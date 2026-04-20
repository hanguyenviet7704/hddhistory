# Keypoint Audio Delete Persistence Fix

## Overview
- Status: Completed
- Priority: High
- Scope: Investigate and fix the case where deleting audio in keypoint edit does not persist after reload.
- Verification: `npm test -- --runInBand src/components/keypoints/KeypointModal.test.tsx`

## Docs Impact
- `docs/`: none. This is a persistence bug fix in the keypoint edit flow, not a product or API contract change.
- Plan doc: updated to track the implementation status and acceptance criteria for the fix.

## Context Links
- [KeypointDetail.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/pages/keypoints/KeypointDetail.tsx)
- [KeypointModal.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/components/keypoints/KeypointModal.tsx:84)
- [CloudflareFileUpload.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/components/files/CloudflareFileUpload.tsx:120)
- [keypointService.ts](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/services/keypointService.ts:22)
- [keypoint.interface.ts](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/types/interface/keypoint.interface.ts:19)

## Likely Root Cause
- `CloudflareFileUpload` does emit `onUrlChange("")` on clear, so the UI delete action reaches modal state.
- `KeypointModal` then rebuilds `payload.audio` only when `cleanedAudioUrl || cleanedAudioText` is truthy.
- If both fields are cleared, `audio` is omitted from the PUT payload entirely instead of being sent as an explicit clear value.
- If the backend applies partial-update semantics on `PUT /courses-keypoints/:id`, omitted `audio` means “leave existing audio unchanged”, which explains why reload restores the old audio.

## TODOs
- Reproduce once with DevTools/network logging and confirm the update request after audio deletion does not include `audio`.
- Check backend contract for `/courses-keypoints/:id` to determine the accepted clear semantics: `audio: null`, `audio: {}`, or nested `url/text: null`.
- Update `KeypointPayload` typing to support the backend’s clear contract instead of only optional omission.
- Refactor `KeypointModal.handleSubmit` so edit mode can send an explicit audio-clear payload when previous keypoint data had audio and the form is now empty.
- Keep create flow simple: do not send empty audio on new keypoints unless backend requires it.
- Verify related fields for the same bug pattern, especially `estimateCompleTime` and any translation-based optional fields that are currently omitted when emptied.
- Add or update a focused test around payload building for keypoint edit, covering:
  - existing audio -> cleared audio
  - existing audio text only -> cleared
  - new audio upload -> saved

## Files Expected To Change
- `src/components/keypoints/KeypointModal.tsx`
- `src/types/interface/keypoint.interface.ts`
- Possibly `src/services/keypointService.ts` if request shaping needs normalization
- Test file near keypoint modal or payload builder logic

## Success Criteria
- After deleting audio and saving in keypoint edit, the update request carries an explicit clear value accepted by the backend.
- Reloading [KeypointDetail.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/pages/keypoints/KeypointDetail.tsx) shows no restored audio.
- No regression for creating or updating keypoints with audio.
