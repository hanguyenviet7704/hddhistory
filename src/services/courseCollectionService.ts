import {
  CourseCollectionPayload,
  ICourseCollection,
} from "../types/interface/course-collection.interface";
import unwrapApi from "../utils/unwrapApi";
import axiosClient from "./axiosClient";

/**
 * Editor-curated Explore strips.
 *
 * Every read goes through `unwrapApi`: meup-api wraps responses in
 * `{ statusCode, message, data }`, and handing a page the envelope means it
 * reads `.title` off `undefined` — which blanks the whole admin with no toast
 * and no console error.
 */
export const courseCollectionService = {
  async list(): Promise<ICourseCollection[]> {
    const res = await axiosClient.get("/course-collections");
    return unwrapApi<ICourseCollection[]>(res.data) ?? [];
  },

  async create(payload: CourseCollectionPayload): Promise<ICourseCollection> {
    const res = await axiosClient.post("/course-collections", payload);
    return unwrapApi<ICourseCollection>(res.data);
  },

  async update(
    id: string,
    payload: CourseCollectionPayload,
  ): Promise<ICourseCollection> {
    const res = await axiosClient.put(`/course-collections/${id}`, payload);
    return unwrapApi<ICourseCollection>(res.data);
  },

  /**
   * Writes a whole slot's order at once. One request rather than one per row,
   * so a drag can never leave the list half-reordered.
   */
  async reorder(ids: string[]): Promise<void> {
    await axiosClient.put("/course-collections/reorder", { ids });
  },

  async remove(id: string): Promise<void> {
    await axiosClient.delete(`/course-collections/${id}`);
  },
};

export default courseCollectionService;
