const { z } = require('zod');

// The service layer clamps this to 200 regardless (see quizService.getLeaderboard),
// so this just rejects non-numeric/garbage input rather than duplicating the cap.
const leaderboardQuerySchema = z.object({
  limit: z.coerce.number().int('limit must be an integer').positive('limit must be a positive integer').optional(),
  period: z.enum(['daily', 'weekly', 'monthly', 'all_time']).optional(),
});

module.exports = { leaderboardQuerySchema };
