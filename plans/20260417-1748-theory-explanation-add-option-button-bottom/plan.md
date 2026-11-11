# Theory Explanation Add Option Button Bottom

## Overview
- Status: Completed
- Priority: Low
- Scope: Move the `Add Option` action to the bottom of the options list for `DocumentType.EXPLANATION` in `src/pages/theories/TheoryForm.tsx`.

## Context Links
- [TheoryForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/theories/TheoryForm.tsx:983)

## Current State
- The Explanation editor renders the `Add Option` button in the section header above the options list.
- With many options, users must scroll back to the top of the section to add one more option.

## Implementation Steps
1. Update the Explanation render block so the header only contains the `Options` label.
2. Render the `Add Option` button after the mapped `options` list and after the empty-state message, so it stays at the bottom of the section.
3. Keep the existing `addExplanationOption(index)` handler unchanged to avoid unnecessary state logic changes.
4. Preserve current spacing and button styling unless bottom placement exposes a layout issue that needs a minimal class adjustment.

## Validation
- Open a theory document with type `Explanation` and confirm the button appears below all options.
- Add several options and verify the button stays at the bottom after each insert.
- Remove all options and verify the empty-state message still shows, with the button remaining accessible underneath it.

## Risk Notes
- Low risk. This is a render-order change only.
- Main regression to avoid: placing the button inside the mapped list or inside the empty-state branch, which would make it disappear in some states.
