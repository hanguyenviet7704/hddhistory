import {
  DriveImportJob,
} from "../types/interface/files/drive-import.interface";
import axiosClient from "./axiosClient";

const unwrap = <T>(response: any): T => response?.data?.data ?? response?.data;

export const driveImportService = {
  async create(folderUrl: string): Promise<DriveImportJob> {
    const response = await axiosClient.post("/cloudflares/drive-imports", {
      folderUrl,
    });
    return unwrap<DriveImportJob>(response);
  },

  async list(): Promise<DriveImportJob[]> {
    const response = await axiosClient.get("/cloudflares/drive-imports");
    return unwrap<DriveImportJob[]>(response);
  },

  async getById(jobId: string): Promise<DriveImportJob> {
    const response = await axiosClient.get(
      `/cloudflares/drive-imports/${jobId}`
    );
    return unwrap<DriveImportJob>(response);
  },

  async cancel(jobId: string): Promise<DriveImportJob> {
    const response = await axiosClient.post(
      `/cloudflares/drive-imports/${jobId}/cancel`
    );
    return unwrap<DriveImportJob>(response);
  },
};
