export interface IUserVideoLessonNote {
  id: string;
  userId: string;
  courseId: string;
  nodeId: string;
  lessonId: string;
  content: string;
  atSecond?: number;
}
