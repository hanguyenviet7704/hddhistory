import {
  RoleplaySectionType,
  SectionConversationPosition,
} from "../../../enum/learningItem.enum";
import { ExerciseInput } from "../learning-item.interface";

export interface IConversation {
  name: string;
  avartar: string;
  position: SectionConversationPosition;
  bubbleColor: string;
  content: string;
  audio: string;
}

export interface ILeadingText {
  frameColor: string;
  content: string;
}

export interface IHint {
  icon: string;
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
  transitionColor: string;
  contents: ISectionContent[];
}
