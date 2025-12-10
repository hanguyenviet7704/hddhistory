import { ITranslation } from "../../utils/translate";
import { ILablel, IMotivation, LablelPayload } from "../enum/common.enum";
import { BaseQuery } from "./common.interface";

export interface IOnboardingIntro {
  id: number;
  title: ITranslation;
  image: string;
  content: ITranslation;
  source: string;
}

export interface OnboardingIntroPayload {
  id: number;
  title: ITranslation;
  image: string;
  content: ITranslation;
  source: string;
}

export interface IOnboarding {
  _id: string;
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
}

export interface OnboardingPayload {
  intro: OnboardingIntroPayload[];
  age: LablelPayload[];
  gender: LablelPayload[];
  skillsetWantToMaster: LablelPayload[];
  learningGoal: LablelPayload[];
  learningStruggles: LablelPayload[];
  comfortableLearningTime: LablelPayload[];
  dailyLearningGoal: LablelPayload[];
  welcome: IMotivation;
  motivationOne: IMotivation;
  motivationTwo: IMotivation;
  motivationThree: IMotivation;
  loading: IMotivation;
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
