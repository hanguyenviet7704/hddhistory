/** Picker mà admin render cho một tham số. Khớp `DeeplinkParamPicker` ở API. */
export type DeeplinkParamPicker =
  | "course"
  | "skillset"
  | "keypoint"
  | "select"
  | "text";

export interface IDeeplinkParam {
  name: string;
  required: boolean;
  picker: DeeplinkParamPicker;
  /** Chỉ có với picker "select". */
  options?: string[];
}

export interface IDeeplinkDestination {
  key: string;
  label: string;
  group: string;
  /** Build app nhỏ nhất hiểu được khoá này — hiện dưới dạng chú thích. */
  minAppBuild: number;
  note?: string;
  params: IDeeplinkParam[];
}
