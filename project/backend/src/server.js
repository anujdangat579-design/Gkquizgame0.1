const http = require('http');
const { Server } = require('socket.io');
const { createAdapter } = require('@socket.io/redis-adapter');
const app = require('./app');
const env = require('./config/env');
const logger = require('./config/logger');
const redis = require('./config/redis');
const initSockets = require('./sockets');
const { pool } = require('./database/connection');

const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: env.corsOrigins,
    credentials: true,
  },
});

// --- Socket.IO Redis adapter -----------------------------------------------
// Broadcasts (io.to(room).emit(...)) and cross-socket events are relayed
// through Redis pub/sub instead of only within this process's memory. That's
// what makes it safe to run more than one instance of this server behind a
// load balancer — a socket connected to instance A can still receive events
// emitted from instance B. The adapter needs two *dedicated* connections
// (a subscriber can't run normal commands), so we duplicate the shared
// client rather than reuse it directly.
const pubClient = redis.duplicate();
const subClient = redis.duplicate();
pubClient.on('error', (err) => logger.error('Redis (Socket.IO pub) error', { message: err.message }));
subClient.on('error', (err) => logger.error('Redis (Socket.IO sub) error', { message: err.message }));

io.adapter(createAdapter(pubClient, subClient));

initSockets(io);

server.listen(env.port, () => {
  logger.info(`GK Quiz backend listening on port ${env.port} [${env.nodeEnv}]`);
});

// --- Graceful shutdown -----------------------------------------------------
// Stops accepting new connections, lets in-flight HTTP requests and socket
// handlers finish, closes the DB pool and all Redis connections, then exits.
// Force-exits after SHUTDOWN_TIMEOUT_MS in case something hangs.
let shuttingDown = false;

async function shutdown(signal) {
  if (shuttingDown) return;
  shuttingDown = true;
  logger.info(`${signal} received, shutting down gracefully`);

  const forceExitTimer = setTimeout(() => {
    logger.error('Graceful shutdown timed out, forcing exit');
    process.exit(1);
  }, env.shutdownTimeoutMs);
  forceExitTimer.unref();

  try {
    io.close(); // stop accepting new socket connections, disconnect existing ones

    await new Promise((resolve, reject) => {
      server.close((err) => (err ? reject(err) : resolve()));
    });

    await pool.end(); // close all Postgres connections cleanly
    await Promise.allSettled([redis.quit(), pubClient.quit(), subClient.quit()]);

    clearTimeout(forceExitTimer);
    logger.info('Shutdown complete');
    process.exit(0);
  } catch (err) {
    logger.error('Error during shutdown:', { stack: err.stack, message: err.message });
    clearTimeout(forceExitTimer);
    process.exit(1);
  }
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// Last-resort safety nets: log and shut down gracefully rather than letting
// the process die in an undefined state or hang silently.
process.on('unhandledRejection', (reason) => {
  logger.error('Unhandled promise rejection:', { reason: reason?.stack || reason });
});

process.on('uncaughtException', (err) => {
  logger.error('Uncaught exception:', { stack: err.stack, message: err.message });
  shutdown('uncaughtException');
});

module.exports = server;
