import { ITranslation } from "../../utils/translate";
import { ILablel, LablelPayload } from "../enum/common.enum";
import { BaseQuery } from "./common.interface";

export interface IOnboardingIntro {
  id: number;
  title: ITranslation;
  image: string;
  content: ITranslation;
}

export interface OnboardingIntroPayload {
  id: number;
  title: ITranslation;
  image: string;
  content: ITranslation;
}

export interface IOnboarding {
  _id: string;
  intro: IOnboardingIntro[];
  age: ILablel[];
  gender: ILablel[];
  skillsetWantToMaster: ILablel[];
  seemLikeYou: ILablel[];
  strugglesWhenSpeaking: ILablel[];
  comfortableLearningTime: ILablel[];
  dailyLearningGoal: ILablel[];
  timeToBecomeSkilled: ILablel[];
}

export interface OnboardingPayload {
  intro: OnboardingIntroPayload[];
  age: LablelPayload[];
  gender: LablelPayload[];
  skillsetWantToMaster: LablelPayload[];
  seemLikeYou: LablelPayload[];
  strugglesWhenSpeaking: LablelPayload[];
  comfortableLearningTime: LablelPayload[];
  dailyLearningGoal: LablelPayload[];
  timeToBecomeSkilled: LablelPayload[];
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
