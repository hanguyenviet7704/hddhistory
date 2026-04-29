import { tagService } from "../services/tagService";
import { LessonType } from "../types/enum/lesson.enum";
import { ITag } from "../types/interface/tag.interface";

type DefaultLessonIconTitles = {
  icon: string;
  lightIcon: string;
};

export const DEFAULT_LESSON_ICON_TITLES: Record<
  | LessonType.LESSON
  | LessonType.ROLEPLAY
  | LessonType.OUTPUT
  | LessonType.VIDEO,
  DefaultLessonIconTitles
> = {
  [LessonType.LESSON]: {
    icon: "keypoint_locked",
    lightIcon: "keypoint",
  },
  [LessonType.ROLEPLAY]: {
    icon: "roleplay_locked",
    lightIcon: "roleplay",
  },
  [LessonType.OUTPUT]: {
    icon: "practice_locked",
    lightIcon: "practice",
  },
  [LessonType.VIDEO]: {
    icon: "video_locked",
    lightIcon: "video",
  },
};

const normalizeTitle = (value?: string) => value?.trim().toLowerCase() || "";

const normalizeTagList = (res: any): ITag[] => {
  const list = res?.data?.items ?? res?.data ?? res?.items ?? [];
  return Array.isArray(list) ? list : [];
};

let tagListRequest: Promise<ITag[]> | null = null;

const getTagsForDefaultIconMatch = async () => {
  if (!tagListRequest) {
    tagListRequest = tagService
      .getList({ page: 1, take: 1000, isAll: true } as any)
      .then(normalizeTagList)
      .catch((error) => {
        tagListRequest = null;
        throw error;
      });
  }

  return tagListRequest;
};

const findTagByEnglishTitle = async (title: string): Promise<ITag | null> => {
  const normalizedTitle = normalizeTitle(title);
  if (!normalizedTitle) return null;

  const tags = await getTagsForDefaultIconMatch();

  const matchedTag =
    tags.find((tag) => normalizeTitle(tag.title?.en) === normalizedTitle) ||
    null;

  if (!matchedTag) {
    console.warn(`Default lesson icon tag not found: ${title}`);
  }

  return matchedTag;
};

export const resolveDefaultLessonIcons = async (
  lessonType:
    | LessonType.LESSON
    | LessonType.ROLEPLAY
    | LessonType.OUTPUT
    | LessonType.VIDEO
) => {
  const titles = DEFAULT_LESSON_ICON_TITLES[lessonType];
  const [icon, lightIcon] = await Promise.all([
    findTagByEnglishTitle(titles.icon),
    findTagByEnglishTitle(titles.lightIcon),
  ]);

  return { icon, lightIcon };
};
