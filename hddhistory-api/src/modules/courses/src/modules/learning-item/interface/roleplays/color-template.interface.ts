export interface IColorStyle {
  backgroundColor: string;
  textColor: string;
}

export interface IConversationColor {
  left: IColorStyle;
  right: IColorStyle;
}

export interface IRoleplayColorTemplate {
  title: string;
  conversation: IConversationColor;
  leadingText: IColorStyle;
  transition: IColorStyle;
  resultsOfAnsweringTheQuestion: IColorStyle;
}
