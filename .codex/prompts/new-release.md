---
description: Cut a release branch, generate notes, and tag the version automatically
argument-hint: [ STATUS=create|update ] [ BASE_BRANCH=develop|release/<ver> ]
---
You are Codex automating the Meup release workflow. Produce a release branch (or refresh an existing one), generate categorized notes, and create the git tag once validation passes.

## Inputs
- If `STATUS` is missing, ask whether we are creating a new release from `develop` or updating the current `release/*` branch.
- Confirm the version declared in `pubspec.yaml` and show it to the user for approval before proceeding.
- Ensure the working tree is clean; stop and ask the user if uncommitted files exist.

## Workflow
1. Capture context: current branch, version, latest tags, pending commits vs `origin/main`, and release history.
2. When `STATUS=create`, checkout `develop` and create `release/<version>`; when `STATUS=update`, stay on the release branch.
3. Analyze all commits since the previous tag (normally `origin/main`..`HEAD`):
   - Compute stats (files changed, additions, deletions, commit count).
   - Group commits into Features, Improvements, Fixes, Platform, Dependencies, Tooling using commit prefixes and file paths.
   - Flag breaking changes (e.g., repository interface shifts, migrations) and dependency updates from `pubspec.yaml`.
4. Draft release notes in Markdown:
   - Title `Release Notes - Meup v<version>`.
   - Sections for 🎉 Features, 🔧 Improvements, 🐛 Fixes, 📱 Platform (iOS/Android), 🔄 Dependencies & Tools, 📊 Statistics, Known Issues/Follow-ups.
   - Provide concrete highlights (entities touched, new APIs, performance wins). Reference files when possible.
5. Tagging:
   - Create an annotated tag `v<version>` with a concise summary plus a link to release notes.
   - Push the branch and tag (`git push origin release/<version>` and `git push origin v<version>`).
6. Share validation steps (tests, analyze, build scripts) that ran during the process or flag remaining work.

## Validation & Reporting
- Stop immediately if the branch or tag already exists; prompt the user for confirmation.
- Mention any blockers (CI failures, dependency sync issues) and how to resolve them.
- Output the final release note snippet plus the commands executed so reviewers can reproduce.
