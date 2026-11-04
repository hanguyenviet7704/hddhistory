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
  /** Tên gọi khác (miếu hiệu, tên húy, tên thường gọi…). */
  aliases?: string[];
  /** Mốc thời gian dạng chữ, vd "sinh khoảng năm 1228, mất năm 1300". */
  date?: string;
}

/** Một quan hệ đã gắn sẵn thực thể ở đầu kia. */
export interface IKgRelation {
  relation: string;
  entity: IKgEntitySummary;
  /** Ghi chú của người soạn về chính quan hệ này (thuyết khác, phạm vi…). */
  note?: string;
  /** Nguồn ghi nhận quan hệ. */
  sources?: IKgSource[];
}

/** Một lập trường của một nguồn trong nhận định còn tranh cãi. */
export interface IKgClaimPosition {
  source: IKgSource;
  text: string;
}

/** Điều các nguồn chưa thống nhất về thực thể này. */
export interface IKgClaim {
  id: string;
  description: string;
  positions: IKgClaimPosition[];
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
  claims: IKgClaim[];
}

/** Một thời kỳ kèm số thực thể — mục lục để duyệt cả đồ thị. */
export interface IKgPeriodOverview extends IKgPeriod {
  entityCount: number;
}

/** Toàn cảnh đồ thị: các thời kỳ theo thứ tự và quy mô dữ liệu. */
export interface IKgOverview {
  periods: IKgPeriodOverview[];
  totals: {
    entities: number;
    relations: number;
    claims: number;
    byType: Record<string, number>;
  };
}

/** Một thực thể liên quan kèm khoảng cách trên đồ thị. */
export interface IKgRelatedEntity extends IKgEntitySummary {
  /** Số bước ngắn nhất từ thực thể gốc tới thực thể này. */
  hops: number;
  /** Các loại quan hệ nối hai thực thể trên đường đi ngắn nhất. */
  via: string[];
}
