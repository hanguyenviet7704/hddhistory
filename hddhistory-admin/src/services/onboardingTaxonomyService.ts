import type { OnboardingTaxonomyTree } from "../types/interface/onboarding-taxonomy.interface";
import { unwrapApi } from "../utils/unwrapApi";
import axiosClient from "./axiosClient";

const BASE = "/onboarding-taxonomy";

export const onboardingTaxonomyService = {
  async getAdmin() {
    const res = await axiosClient.get(`${BASE}/admin`);
    return unwrapApi<OnboardingTaxonomyTree>(res.data);
  },
  /** Thay toàn bộ cây; API validate và trả 400 {message, issues[]} khi hỏng. */
  async replace(tree: OnboardingTaxonomyTree) {
    const res = await axiosClient.put(BASE, tree);
    return unwrapApi<OnboardingTaxonomyTree>(res.data);
  },
  async importExcel(file: File) {
    const formData = new FormData();
    formData.append("file", file);
    return axiosClient.post<Blob>(`${BASE}/import`, formData, {
      responseType: "blob",
      headers: { "Content-Type": "multipart/form-data" },
    });
  },
  async exportExcel() {
    return axiosClient.get<Blob>(`${BASE}/export`, { responseType: "blob" });
  },
  async downloadTemplate() {
    return axiosClient.get<Blob>(`${BASE}/template`, { responseType: "blob" });
  },
};
