import {
  RoleplaySectionType,
  SectionConversationPosition,
} from "../../../enum/learningItem.enum";
import {
  ExerciseInput,
  ExerciseInputPayload,
} from "../learning-item.interface";

export interface IConversation {
  name: string;
  avartar: string;
  position: SectionConversationPosition;
  backgroundColor: string;
  textColor: string;
  content: string;
  audio: string;
}

export interface ILeadingText {
  backgroundColor: string;
  textColor: string;
  content: string;
  audio: string;
}

export interface IHint {
  icon: string;
  textColor: string;
  content: string;
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
  title: string;
  transition: string;
  textColor: string;
  backgroundColor: string;
  image: string;
  contents: ISectionContent[];
}

export type ISectionContentPayload = Omit<ISectionContent, "exercise"> & {
  exercise?: ExerciseInputPayload;
};

export type ISectionPayload = Omit<ISection, "contents"> & {
  contents: ISectionContentPayload[];
};
