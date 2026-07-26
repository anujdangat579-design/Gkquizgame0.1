const { getPeriodRange } = require('../src/utils/periodRange');

describe('getPeriodRange', () => {
  it('all_time has no lower bound', () => {
    const now = new Date('2026-07-24T15:30:00.000Z');
    const { start, end } = getPeriodRange('all_time', now);
    expect(start).toBeNull();
    expect(end).toBe(now);
  });

  it('daily starts at today\'s UTC midnight', () => {
    const now = new Date('2026-07-24T15:30:00.000Z'); // Friday
    const { start } = getPeriodRange('daily', now);
    expect(start.toISOString()).toBe('2026-07-24T00:00:00.000Z');
  });

  it('weekly starts at this ISO week\'s Monday (mid-week case)', () => {
    const now = new Date('2026-07-24T15:30:00.000Z'); // Friday, July 24 2026
    const { start } = getPeriodRange('weekly', now);
    expect(start.toISOString()).toBe('2026-07-20T00:00:00.000Z'); // Monday
  });

  it('weekly rolls Sunday back to the preceding Monday, not forward', () => {
    const now = new Date('2026-07-26T05:00:00.000Z'); // Sunday, July 26 2026
    const { start } = getPeriodRange('weekly', now);
    expect(start.toISOString()).toBe('2026-07-20T00:00:00.000Z');
  });

  it('monthly starts at the 1st of the current UTC month', () => {
    const now = new Date('2026-07-24T15:30:00.000Z');
    const { start } = getPeriodRange('monthly', now);
    expect(start.toISOString()).toBe('2026-07-01T00:00:00.000Z');
  });

  it('throws on an unknown period', () => {
    expect(() => getPeriodRange('yearly')).toThrow('Unknown leaderboard period: yearly');
  });
});
