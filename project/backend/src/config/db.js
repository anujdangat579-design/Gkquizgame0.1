const { Pool } = require('pg');
const env = require('./env');
const logger = require('./logger');

// Neon requires SSL. The `sslmode=require` in the connection string handles
// most cases, but we set `ssl` explicitly too so it also works on hosts
// (like some CI or older pg versions) that don't parse sslmode from the URL.
const pool = new Pool({
  connectionString: env.databaseUrl,
  ssl: { rejectUnauthorized: false },
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

pool.on('error', (err) => {
  // Prevents an idle client error from crashing the whole process.
  logger.error('Unexpected Postgres pool error:', { stack: err.stack, message: err.message });
});

async function query(text, params) {
  const start = Date.now();
  const result = await pool.query(text, params);
  logger.debug('executed query', { text, duration: Date.now() - start, rows: result.rowCount });
  return result;
}

async function getClient() {
  const client = await pool.connect();
  return client;
}

module.exports = { pool, query, getClient };
