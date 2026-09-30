export interface ICommunitySanction {
  userId: string;
  // Null means indefinite.
  mutedUntil?: Date;
  reason: string;
  createdByUserId: string;
  revokedAt?: Date;
  revokedByUserId?: string;
}
