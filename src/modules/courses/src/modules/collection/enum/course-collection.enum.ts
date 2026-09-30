export enum CourseCollectionStatus {
  DRAFT = 'draft',
  PUBLISHED = 'published',
}

/**
 * Where the collection sits on the Explore tab.
 *
 * The tab has exactly two curated regions, fixed by the design: one strip above
 * the weekly-popular card, and everything else below the topic chips. A slot is
 * not a pixel position — it is which of those two regions the row belongs to,
 * and `index` orders the rows inside it.
 */
export enum CourseCollectionSlot {
  TOP = 'top',
  BOTTOM = 'bottom',
}
