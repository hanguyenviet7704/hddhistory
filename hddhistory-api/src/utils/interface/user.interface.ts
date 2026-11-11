import { ITranslation } from './common.interface';

export interface ILablel {
  id: number;
  icon: string;
  title: ITranslation;
  label: ITranslation;
  trackingLabel: string;
}
