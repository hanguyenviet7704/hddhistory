import {
  AdminUserHabitDetailQuery,
  AdminUserHabitsQuery,
  AdminUserHabitsResponse,
  IAdminUserHabitDetail,
} from "../types/interface/userHabit.interface";
import axiosClient from "./axiosClient";

/**
 * Read-only admin view of real habit usage.
 *
 * The API wraps every response as `{ statusCode, message, data }`
 * (ResponseInterceptor), so the payload is one level down. The `?? res.data`
 * fallback matches the rest of the admin services and keeps this working if the
 * envelope is ever dropped.
 *
 * Both endpoints are `@Roles(ADMIN)`-gated server side: a non-admin token gets
 * a 403, not an empty list. Callers should surface that rather than rendering
 * "no data".
 */
export const userHabitService = {
  async getUserSummaries(
    params?: AdminUserHabitsQuery,
  ): Promise<AdminUserHabitsResponse> {
    const res = await axiosClient.get("/user-habits/admin", { params });
    return res.data?.data ?? res.data;
  },

  async getUserDetail(
    userId: string,
    params?: AdminUserHabitDetailQuery,
  ): Promise<IAdminUserHabitDetail> {
    const res = await axiosClient.get(`/user-habits/admin/users/${userId}`, {
      params,
    });
    return res.data?.data ?? res.data;
  },
};
