import { OrderType } from "../enum/common.enum";
import { StudyThemeMode } from "../enum/study-theme.enum";

// A single study-background preset shown in the mobile app's theme picker.
// `key` is the immutable slug the mobile client references, so it is only
// ever set on create — see StudyThemeUpdatePayload.
export interface IStudyTheme {
  key: string;
  mode: StudyThemeMode;
  category: string;
  name: string;
  gradient: string[];
  imageUrl?: string;
  videoUrl?: string;
  audioUrl?: string;
  thumbUrl?: string;
  overlay?: string;
  isDark: boolean;
  order: number;
  isActive: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export type StudyThemePayload = Omit<IStudyTheme, "createdAt" | "updatedAt">;

// PATCH /study-themes/:key takes the key from the URL — the body must not
// include it.
export type StudyThemeUpdatePayload = Partial<Omit<StudyThemePayload, "key">>;

export interface StudyThemeListQuery {
  page: number;
  take: number;
  orderBy?: string;
  order?: OrderType;
  search?: string;
  mode?: StudyThemeMode;
  category?: string;
  isActive?: boolean;
}

export interface StudyThemeListResponse {
  items: IStudyTheme[];
  itemsPerPage: number;
  totalPages: number;
  currentPage: number;
}
