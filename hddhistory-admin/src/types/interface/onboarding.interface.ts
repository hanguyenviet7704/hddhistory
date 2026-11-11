import { ITranslation } from "../../utils/translate";
import { ILablel, IMotivation, LablelPayload } from "../enum/common.enum";
import { BaseQuery } from "./common.interface";

export interface IOnboardingIntro {
  id: number;
  title: ITranslation;
  image: string;
  content: ITranslation;
  source: string;
  sourceTitle: string;
}

export interface OnboardingIntroPayload {
  id: number;
  title: ITranslation;
  image: string;
  content: ITranslation;
  source: string;
  sourceTitle: string;
}

// Onboarding v2 — API-driven learning paths / symptoms.
// See hddhistory-api/plans/260717-onboarding-v2-api-driven/design.md
export interface OnboardingSymptom {
  key: string;
  title: ITranslation;
  trackingLabel: string;
  order: number;
}

export interface OnboardingPath {
  key: string;
  title: ITranslation;
  shortTitle: string;
  iconKey: string;
  iconUrl?: string;
  trackingLabel: string;
  order: number;
  symptoms: OnboardingSymptom[];
}

// Onboarding v2 — fixed-key screen copy (en/vi). Keys are a known, closed set
// (see OnboardingManagemant.tsx COPY_GROUPS) — editors fill in values, they
// never invent new keys.
export interface OnboardingCopy {
  key: string;
  value: {
    en?: string;
    vi?: string;
  };
}

export interface IOnboarding {
  _id: string;
  intro: IOnboardingIntro[];
  age: ILablel[];
  gender: ILablel[];
  categoryWantToMaster: ILablel[];
  learningGoal: ILablel[];
  learningStruggles: ILablel[];
  comfortableLearningTime: ILablel[];
  dailyLearningGoal: ILablel[];
  welcome: IMotivation;
  motivationOne: IMotivation;
  motivationTwo: IMotivation;
  motivationThree: IMotivation;
  loading: IMotivation;
  paths?: OnboardingPath[];
  copy?: OnboardingCopy[];
}

export interface OnboardingPayload {
  intro: OnboardingIntroPayload[];
  age: LablelPayload[];
  gender: LablelPayload[];
  categoryWantToMaster: LablelPayload[];
  learningGoal: LablelPayload[];
  learningStruggles: LablelPayload[];
  comfortableLearningTime: LablelPayload[];
  dailyLearningGoal: LablelPayload[];
  welcome: IMotivation;
  motivationOne: IMotivation;
  motivationTwo: IMotivation;
  motivationThree: IMotivation;
  loading: IMotivation;
  paths: OnboardingPath[];
  copy: OnboardingCopy[];
}

export class OnboardingListQuery extends BaseQuery {
  constructor(init?: Partial<OnboardingListQuery>) {
    super(init);
    Object.assign(this, init);
  }

  override toQueryParams(): string {
    const params = new URLSearchParams(super.toQueryParams());

    return params.toString();
  }
}
