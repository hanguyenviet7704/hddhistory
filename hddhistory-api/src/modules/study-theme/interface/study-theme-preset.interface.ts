import { StudyThemeMode } from '../enum/study-theme.enum';

export interface IStudyThemePreset {
  key: string;
  mode: StudyThemeMode;
  category: string;
  name: string;
  gradient: string[];
  imageUrl?: string | null;
  videoUrl?: string | null;
  audioUrl?: string | null;
  thumbUrl?: string | null;
  overlay?: string | null;
  isDark: boolean;
  order: number;
  isActive: boolean;
  isPremium: boolean;
}

// Shape returned by the public GET /study-themes endpoint — persistence-only
// fields (_id, isActive, createdAt/updatedAt/createdBy/updatedBy) are dropped
// by the repository's projection before it ever reaches the service.
export interface IStudyThemePresetPublic {
  key: string;
  mode: StudyThemeMode;
  category: string;
  name: string;
  gradient: string[];
  imageUrl?: string | null;
  videoUrl?: string | null;
  audioUrl?: string | null;
  thumbUrl?: string | null;
  overlay?: string | null;
  isDark: boolean;
  order: number;
  isPremium: boolean;
}
