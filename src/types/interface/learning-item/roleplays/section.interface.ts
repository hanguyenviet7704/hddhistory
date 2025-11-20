import { ITranslation } from "../../../../utils/translate";
import {
  RoleplaySectionType,
  SectionConversationPosition,
} from "../../../enum/learningItem.enum";
import { IAvatar } from "../../avatar.interface";
import {
  ExerciseInput,
  ExerciseInputPayload,
} from "../learning-item.interface";

export interface IConversation {
  avatarId: string;
  avatar?: IAvatar;
  position: SectionConversationPosition;
  backgroundColor: string;
  textColor: string;
  content: ITranslation;
  audio: string;
}

export interface ILeadingText {
  backgroundColor: string;
  textColor: string;
  content: ITranslation;
  audio: string;
}

export interface IHint {
  icon: string;
  backgroundColor: string;
  textColor: string;
  content: ITranslation;
}

export interface ISectionContent {
  id: number;
  type: RoleplaySectionType;
  conversation: IConversation;
  leadingText: ILeadingText;
  hint: IHint;
  exercise: ExerciseInput;
}

export interface ISection {
  id: number;
  title: ITranslation;
  transition: ITranslation;
  textColor: string;
  backgroundColor: string;
  image: string;
  colorTemplateId?: string;
  contents: ISectionContent[];
}

export type ISectionContentPayload = Omit<ISectionContent, "exercise"> & {
  exercise?: ExerciseInputPayload;
};

export type ISectionPayload = Omit<ISection, "contents"> & {
  contents: ISectionContentPayload[];
};
