const auditService = require('../services/auditService');
const asyncHandler = require('../middleware/asyncHandler');

const listAuditLogs = asyncHandler(async (req, res) => {
  const result = await auditService.list(req.query);
  res.json(result);
});

module.exports = { listAuditLogs };
