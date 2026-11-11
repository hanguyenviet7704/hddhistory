import { ITranslation } from '@utils/interface/common.interface';

export enum ExploreSectionType {
  /** An editor-authored strip from `course_collections`. */
  CURATED = 'curated',
  /** The three courses most people opened this week. */
  WEEKLY_TOP = 'weeklyTop',
  /** Three suggestions drawn from the category of the last course finished. */
  BECAUSE_YOU = 'becauseYou',
  /**
   * A marker, carrying no payload: the client already holds the category
   * catalogue and renders the chips from it. It exists so that the ORDER of
   * every section stays a server decision — moving the chips later is then a
   * server change, not an app release.
   */
  TOPIC_CHIPS = 'topicChips',
}

export interface IExploreSection {
  type: ExploreSectionType;
  /** Collection id; absent on the computed sections. */
  id?: string;
  title?: ITranslation;
  courses?: any[];
  /** `becauseYou` only: the finished course the suggestions hang off. */
  sourceCourse?: any;
}

export interface IExploreResponse {
  sections: IExploreSection[];
}
