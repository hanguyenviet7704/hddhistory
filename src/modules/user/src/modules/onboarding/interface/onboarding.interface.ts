import { ITranslation } from '@utils/interface/common.interface';
import { ILablel } from '@utils/interface/user.interface';

export interface IOnboardingIntro {
  id: number;
  title: ITranslation;
  image: string;
  content: ITranslation;
  source: string;
  sourceTitle: string;
}

export interface IMotivation {
  content: ITranslation;
  image: string;
}

export interface IOnboardingSymptom {
  key: string;
  title: ITranslation;
  trackingLabel: string;
  order: number;
}

export interface IOnboardingPath {
  key: string;
  title: ITranslation;
  shortTitle: string;
  iconKey: string;
  iconUrl?: string;
  trackingLabel: string;
  order: number;
  symptoms: IOnboardingSymptom[];
}

export interface IOnboardingCopy {
  key: string;
  value: ITranslation;
}

export interface IOnboarding {
  intro: IOnboardingIntro[];
  age: ILablel[];
  gender: ILablel[];
  skillsetWantToMaster: ILablel[];
  learningGoal: ILablel[];
  learningStruggles: ILablel[];
  comfortableLearningTime: ILablel[];
  dailyLearningGoal: ILablel[];
  welcome: IMotivation;
  motivationOne: IMotivation;
  motivationTwo: IMotivation;
  motivationThree: IMotivation;
  loading: IMotivation;
  paths: IOnboardingPath[];
  copy: IOnboardingCopy[];
}
