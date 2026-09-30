import { ITranslation } from '@utils/interface/common.interface';

import { ICommunityTopicStats } from '../../../interface/community.interface';

export interface ICommunityTopic {
  name: ITranslation;
  description: ITranslation;
  slug: string;
  imageUrl?: string;
  sortOrder: number;
  isActive: boolean;
  stats: ICommunityTopicStats;
}
