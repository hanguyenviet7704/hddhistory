import { SegmentPayload } from "../types/interface/segment.interface";
import axiosClient from "./axiosClient";

export const segmentService = {
  /** GET /segments — the full list, unpaginated (admin-only, expected to stay small). */
  async list() {
    const res = await axiosClient.get("/segments");
    return res.data;
  },

  async create(payload: SegmentPayload) {
    const res = await axiosClient.post("/segments", payload);
    return res.data;
  },

  async update(id: string, payload: SegmentPayload) {
    const res = await axiosClient.put(`/segments/${id}`, payload);
    return res.data;
  },

  async remove(id: string) {
    const res = await axiosClient.delete(`/segments/${id}`);
    return res.data;
  },

  /**
   * Live member count + nightly-snapshot history. Count is computed on the
   * fly and can be slow for a broad segment — call this on demand (a button
   * click), never on page load for every row.
   */
  async stats(id: string) {
    const res = await axiosClient.get(`/segments/${id}/stats`);
    return res.data;
  },

  /** |A|, |B| and |A∩B| for the overlap/Venn view. */
  async overlap(a: string, b: string) {
    const res = await axiosClient.get("/segments/overlap", { params: { a, b } });
    return res.data;
  },
};
