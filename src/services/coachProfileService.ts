import axiosClient from "./axiosClient";

/**
 * What a reader told the Coach about themselves during its onboarding.
 *
 * Read-only. These live in `coach_profiles`, not on the user record: age and
 * gender have columns there and are written across, everything else does not,
 * and copying it would give one fact two homes.
 *
 * The address ("gọi mình là chị") is deliberately not returned — how somebody
 * wants to be spoken to is a setting for the conversation, not information
 * about them.
 */
export interface ICoachOnboardingProfile {
  onboardedAt: string | null;
  goalText: string | null;
  barrierText: string | null;
  currentPractice: string | null;
  learningStyle: string | null;
  occupation: string | null;
  occupationRaw: string | null;
}

export const coachProfileService = {
  async getByUser(userId: string): Promise<ICoachOnboardingProfile> {
    const res = await axiosClient.get(`/coach-profiles/${userId}`);
    return res.data?.data ?? res.data;
  },
};
