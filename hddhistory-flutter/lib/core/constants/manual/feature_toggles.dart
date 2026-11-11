part of '../constants.dart';

/// Build-time feature toggles — one const per surface we can switch off
/// without ripping its code out.
///
/// Achievements (badges): hidden app-wide per product call (2026-08-07). This
/// single const gates every visible achievements surface:
/// - the Profile "Thành tích" section (header + badge summary card) — the sole
///   entry into [AchievementsFullPage], so the full list, detail sheet, and
///   the roadmap's "back to achievements" return path all become unreachable
///   with it;
/// - the course-badge celebration ([BadgeProgressRoute]) at the moment a
///   course's badge completes — with badges hidden, celebrating one would show
///   a thing the app pretends not to have. Completion routes to the roadmap
///   like every other keypoint.
///
/// The Learning Progress section, streak stats and minutes on Profile are NOT
/// achievements and stay.
const bool kAchievementsEnabled = false;
