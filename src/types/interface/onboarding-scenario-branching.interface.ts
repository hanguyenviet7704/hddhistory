import { ITranslation } from "../../utils/translate";
import { ILablel } from "../enum/common.enum";

export enum OnboardingContentType {
  FACT = "fact",
  ACTIVATION = "activation",
  BRANCH = "branch",
  FIXED = "fixed",
  PERSON_ADMIRE = "person_admire",
}

export interface IOnboardingScenarioBranchOption {
  id: number;
  label: ITranslation;
  icon: string;
  nextSceneId?: string;
  courses?: string[];
}

export interface IOnboardingScenarioBranch {
  subQuestion: ITranslation;
  question: ITranslation;
  options: IOnboardingScenarioBranchOption[];
}

export interface IOnboardingScenarioFixed {
  subQuestion: ITranslation;
  question: ITranslation;
  options: ILablel[];
}

export interface IOnboardingScenarioPersonOption {
  image: string;
  name: string;
  title: ITranslation;
  subTitle: ITranslation;
}

export type IOnboardingScenarioPersonAdmireOption =
  IOnboardingScenarioPersonOption;

export interface IOnboardingScenarioPersonAdmire {
  subQuestion: ITranslation;
  question: ITranslation;
  options: IOnboardingScenarioPersonAdmireOption[];
}

export interface IOnboardingScenarioActivation {
  id: number;
  title: ITranslation;
  description: ITranslation;
  content: {
    icon: string;
    labels: ILablel[];
  };
}

export interface IOnboardingScenarioContentItem {
  id: number;
  type: OnboardingContentType;
  fact?: ILablel;
  activation?: IOnboardingScenarioActivation;
  branch?: IOnboardingScenarioBranch;
  fixed?: IOnboardingScenarioFixed;
  personAdmire?: IOnboardingScenarioPersonAdmire;
}

export interface IOnboardingScenarioScene {
  id: string;
  contents: IOnboardingScenarioContentItem[];
}

export interface IOnboardingScenarioBranching {
  entrySceneId: string;
  scenes: IOnboardingScenarioScene[];
}
