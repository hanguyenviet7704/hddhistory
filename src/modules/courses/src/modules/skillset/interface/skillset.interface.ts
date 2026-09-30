import { ITranslation } from '@utils/interface/common.interface';

import { ICourse } from '../../course/interface/course.interface';
import {
  SkillsetOnboardingIntroduce,
  SkillsetStatus,
} from '../enum/skillset.enum';

export interface ISkillset {
  title: ITranslation;
  description?: ITranslation;
  status: SkillsetStatus;
  image: string;
  onboardingIntroduce?: SkillsetOnboardingIntroduce;
  courses?: ICourse[];
  index?: number;
}
