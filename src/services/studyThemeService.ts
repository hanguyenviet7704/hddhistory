import {
  IStudyTheme,
  StudyThemeListQuery,
  StudyThemeListResponse,
  StudyThemePayload,
  StudyThemeUpdatePayload,
} from "../types/interface/study-theme.interface";
import axiosClient from "./axiosClient";

export const studyThemeService = {
  // Admin table — paginated + filterable. Pass orderBy/order to sort like the
  // mobile app's picker (order asc); the list page always does this.
  async getList(params: Partial<StudyThemeListQuery>) {
    const res = await axiosClient.get<StudyThemeListResponse>(
      "/study-themes/all",
      { params }
    );
    return res.data;
  },

  async create(payload: StudyThemePayload) {
    return axiosClient.post<IStudyTheme>("/study-themes", payload);
  },

  // `key` is immutable and lives in the URL, never the body.
  async update(key: string, payload: StudyThemeUpdatePayload) {
    return axiosClient.patch<IStudyTheme>(`/study-themes/${key}`, payload);
  },

  async remove(key: string) {
    return axiosClient.delete(`/study-themes/${key}`);
  },
};
