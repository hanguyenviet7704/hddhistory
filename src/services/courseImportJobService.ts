import axiosClient from "./axiosClient";

export interface CourseImportJob {
  _id: string;
  status: "queued" | "processing" | "completed" | "failed" | "cancelled";
  totalRows: number;
  processedRows: number;
  percent: number;
  errors?: Array<{
    sheet: string;
    row: number;
    column?: string;
    message: string;
  }>;
  lastError?: string;
  createdAt?: string;
  startedAt?: string;
  completedAt?: string;
}

export type LearningItemImportTarget = "theories" | "exercises";

export const courseImportJobService = {
  async importLearningItems(file: File) {
    const formData = new FormData();
    formData.append("file", file);

    const res = await axiosClient.post(
      "/course-import-jobs/learning-items",
      formData,
      {
        headers: {
          "Content-Type": "multipart/form-data",
        },
      }
    );
    return res.data;
  },

  async getById(jobId: string) {
    const res = await axiosClient.get(`/course-import-jobs/${jobId}`);
    return res.data;
  },
};
