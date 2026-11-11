import { ITranslation } from "../../../../utils/translate";
import {
  RoleplayContentType,
  RoleplayConversationPosition,
} from "../../../enum/learningItem.enum";
import { IAvatar } from "../../avatar.interface";
import {
  ExerciseInput,
  ExerciseInputPayload,
} from "../learning-item.interface";

export interface IConversation {
  avatarId: string;
  avatar?: IAvatar;
  position: RoleplayConversationPosition;
  backgroundColor: string;
  textColor: string;
  content: ITranslation;
  audio: ITranslation;
}

export interface ILeadingText {
  backgroundColor: string;
  textColor: string;
  content: ITranslation;
  audio: ITranslation;
}

export interface ITransition {
  textColor: string;
  content: ITranslation;
}

export interface IRoleplayContent {
  id: number;
  type: RoleplayContentType;
  conversation: IConversation;
  leadingText: ILeadingText;
  transition: ITransition;
  exercise: ExerciseInput;
}

export interface IMission {
  id: number;
  content: ITranslation;
}

export interface IRoleplay {
  image: string;
  contents: IRoleplayContent[];
  missions: IMission[];
  colorTemplateId: string;
}

export type IRoleplayContentPayload = Omit<IRoleplayContent, "exercise"> & {
  exercise?: ExerciseInputPayload;
};

export type IRoleplayPayload = Omit<IRoleplay, "contents"> & {
  contents: IRoleplayContentPayload[];
};
