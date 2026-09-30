export enum WarmUpInactivityUnit {
  SECONDS = 'seconds',
  MINUTES = 'minutes',
  HOURS = 'hours',
  DAYS = 'days',
}

const MS_PER_UNIT: Record<WarmUpInactivityUnit, number> = {
  [WarmUpInactivityUnit.SECONDS]: 1000,
  [WarmUpInactivityUnit.MINUTES]: 60 * 1000,
  [WarmUpInactivityUnit.HOURS]: 60 * 60 * 1000,
  [WarmUpInactivityUnit.DAYS]: 24 * 60 * 60 * 1000,
};

/**
 * Convert an inactivity threshold expressed as a value + unit pair into
 * milliseconds. Falls back to days for any unrecognised unit so a legacy or
 * malformed document never breaks the comparison.
 */
export function toMilliseconds(
  value: number,
  unit: WarmUpInactivityUnit,
): number {
  return value * (MS_PER_UNIT[unit] ?? MS_PER_UNIT[WarmUpInactivityUnit.DAYS]);
}
