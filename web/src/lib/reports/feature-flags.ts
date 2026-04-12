// Feature flags for gradual reporting rollout (D-95)
// Deterministic percentage-based rollout using userId hash.
// Reads REPORT_ROLLOUT_PERCENT env var (default: 100 = fully rolled out).

// ---------------------------------------------------------------------------
// Hash function for deterministic bucket assignment
// ---------------------------------------------------------------------------

/**
 * Simple hash of userId to a number 0-99 for rollout bucketing.
 * Deterministic: same userId always gets same bucket.
 */
function hashToBucket(userId: string): number {
  let hash = 0;
  for (let i = 0; i < userId.length; i++) {
    const char = userId.charCodeAt(i);
    hash = ((hash << 5) - hash + char) | 0; // Convert to 32-bit int
  }
  return Math.abs(hash) % 100;
}

// ---------------------------------------------------------------------------
// Rollout configuration
// ---------------------------------------------------------------------------

export type RolloutStage = {
  percentage: 10 | 50 | 100;
  beta_opt_in: boolean;
};

/**
 * Get the current rollout percentage from env var.
 * Defaults to 100 (fully rolled out) if not set.
 */
function getRolloutPercentage(): number {
  const envVal = process.env.REPORT_ROLLOUT_PERCENT;
  if (!envVal) return 100;
  const parsed = parseInt(envVal, 10);
  if (isNaN(parsed) || parsed < 0) return 0;
  if (parsed > 100) return 100;
  return parsed;
}

// ---------------------------------------------------------------------------
// Feature flag checks
// ---------------------------------------------------------------------------

/**
 * Check if reporting features are enabled for a given user (D-95).
 * Uses deterministic hashing so a user's access is consistent.
 *
 * @param userId - The user's unique identifier
 * @param betaOptIn - Whether the user has opted into beta (from user preferences)
 * @returns true if the user should see reporting features
 */
export function isReportingEnabled(
  userId: string,
  betaOptIn: boolean = false
): boolean {
  // Beta opt-in users always get access (D-95)
  if (betaOptIn) return true;

  const percentage = getRolloutPercentage();

  // 100% = everyone gets access (default)
  if (percentage >= 100) return true;
  // 0% = nobody gets access
  if (percentage <= 0) return false;

  const bucket = hashToBucket(userId);
  return bucket < percentage;
}

/**
 * Get all feature flag states for the reporting module.
 * Used by UI to conditionally render features.
 */
export function getFeatureFlags(
  userId?: string,
  betaOptIn: boolean = false
): {
  reportingEnabled: boolean;
  rolloutPercentage: number;
  userBucket: number | null;
  betaOptIn: boolean;
  pdfExportEnabled: boolean;
  scheduledReportsEnabled: boolean;
  portfolioRollupEnabled: boolean;
  aiInsightsEnabled: boolean;
} {
  const percentage = getRolloutPercentage();
  const bucket = userId ? hashToBucket(userId) : null;
  const enabled = userId ? isReportingEnabled(userId, betaOptIn) : percentage >= 100;

  return {
    reportingEnabled: enabled,
    rolloutPercentage: percentage,
    userBucket: bucket,
    betaOptIn,
    // Sub-features are gated by main reporting flag
    pdfExportEnabled: enabled,
    scheduledReportsEnabled: enabled,
    portfolioRollupEnabled: enabled,
    aiInsightsEnabled: enabled,
  };
}

/**
 * Get the current rollout stage description.
 */
export function getRolloutStage(): RolloutStage {
  const percentage = getRolloutPercentage();
  if (percentage <= 10) return { percentage: 10, beta_opt_in: true };
  if (percentage <= 50) return { percentage: 50, beta_opt_in: true };
  return { percentage: 100, beta_opt_in: false };
}
