import { ITranslation } from '@utils/interface/common.interface';

import { IAvatar } from '../../../avatar/interface/avatar.interface';
import {
  RoleplayContentType,
  RoleplayConversationPosition,
} from '../../enum/learning-item.enum';
import { ExerciseInput } from '../learning-item.interface';

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
