export interface IKgPeriod {
  id: string;
  name: string;
  start: string;
  end: string;
}

export interface IKgSource {
  id: string;
  title: string;
  note?: string;
}

/** Thực thể ở dạng rút gọn, dùng trong danh sách và ở hai đầu quan hệ. */
export interface IKgEntitySummary {
  id: string;
  type: string;
  name: string;
  description?: string;
}

/** Một quan hệ đã gắn sẵn thực thể ở đầu kia. */
export interface IKgRelation {
  relation: string;
  entity: IKgEntitySummary;
}

/** Hồ sơ đầy đủ của một thực thể: là ai, đã làm gì, liên quan tới những gì. */
export interface IKgEntityProfile extends IKgEntitySummary {
  note?: string;
  period?: IKgPeriod;
  /** Quan hệ mà thực thể này là chủ thể — "đã làm gì". */
  outgoing: IKgRelation[];
  /** Quan hệ mà thực thể này là đối tượng — "được ai nhắc tới". */
  incoming: IKgRelation[];
  samePeriod: IKgEntitySummary[];
  sources: IKgSource[];
}

/** Một thực thể liên quan kèm khoảng cách trên đồ thị. */
export interface IKgRelatedEntity extends IKgEntitySummary {
  /** Số bước ngắn nhất từ thực thể gốc tới thực thể này. */
  hops: number;
  /** Các loại quan hệ nối hai thực thể trên đường đi ngắn nhất. */
  via: string[];
}
