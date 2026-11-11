import { ITranslation } from '@utils/interface/common.interface';

import { ICourse } from '../../course/interface/course.interface';
import {
  CategoryOnboardingIntroduce,
  CategoryStatus,
} from '../enum/category.enum';

export interface ICategory {
  title: ITranslation;
  description?: ITranslation;
  status: CategoryStatus;
  image: string;
  onboardingIntroduce?: CategoryOnboardingIntroduce;
  courses?: ICourse[];
  index?: number;
}
