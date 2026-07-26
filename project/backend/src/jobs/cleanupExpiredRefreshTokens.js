// Optional maintenance script — NOT invoked automatically by the server.
// Deletes refresh_token rows that are already expired or revoked so the
// table doesn't grow forever. Run manually, or wire it up to a scheduler
// (e.g. a Render Cron Job) with:
//
//   npm run job:cleanup-tokens

const db = require('../database/connection');

async function cleanupExpiredRefreshTokens() {
  const result = await db.query(
    `DELETE FROM refresh_tokens WHERE expires_at < now() OR revoked = TRUE`
  );
  console.log(`Removed ${result.rowCount} expired/revoked refresh token(s).`);
  await db.pool.end();
}

cleanupExpiredRefreshTokens().catch((err) => {
  console.error('Cleanup job failed:', err);
  process.exit(1);
});
