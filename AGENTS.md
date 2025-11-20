# Repository Guidelines

## Project Structure & Module Organization
The React + TypeScript app lives under `src/`, with entrypoints in `index.tsx` and `App.tsx`. UI building blocks go in `src/components`, while page-level flows live in `src/pages` and are wired through `src/routes`. Data fetching and side effects belong in `src/services` (Axios helpers) and state logic in `src/store` (Redux Toolkit slices). Shared contracts stay in `src/types`, reusable helpers in `src/utils`, and styling assets in `src/App.css`, `tailwind.config.js`, and `public/`. Keep feature-specific assets co-located to ease codeowners’ reviews.

## Build, Test, and Development Commands
- `npm start` — launches the CRA webpack dev server with hot reload. Pass `HOST=0.0.0.0` when testing on devices.
- `npm run build` — produces the production bundle consumed by the Dockerfile and nginx.conf.
- `npm test` — runs Jest via `react-scripts test`; use `npm test -- App.test.tsx` to focus on a suite or `npm test -- --coverage` before merges.
Run `npm install` after cloning to pull the pinned versions in `package-lock.json`; avoid mixing yarn/pnpm across agents to keep lockfiles clean.

## Coding Style & Naming Conventions
Follow the default ESLint rules from `react-app` and TypeScript strictness from `tsconfig.json`. Prefer 2-space indentation, PascalCase component files (e.g., `RoleplayPanel.tsx`), camelCase hooks/utilities, and UPPER_SNAKE_CASE constants. Co-locate styles with components and favor Tailwind utility classes when possible; fall back to `App.css` or component-level CSS modules only for complex layouts. Keep hooks pure, memoize expensive selectors, and wrap store mutations inside RTK slices.

## Testing Guidelines
React Testing Library and `@testing-library/jest-dom` assertions are preconfigured through `setupTests.ts`. Add `*.test.tsx` files alongside the component being verified, mirroring the filename (`AvatarCard.test.tsx`). Tests should mock network calls at the `services` boundary and assert user-visible outcomes rather than implementation details. Failing tests gate CI, so cover new behavior (render, interaction, redux wiring) before requesting review.

## Commit & Pull Request Guidelines
Match the existing convention: `<type>-<TICKET> <concise summary>` (e.g., `feature-MEUP-203 fix scroll page size course list`). Keep commits scoped to a single concern and include screenshots or GIFs for UI-facing changes in the PR description. Every PR should link the tracking issue, describe testing performed (`npm test`, manual steps), and call out any config/env changes. Request at least one reviewer familiar with the affected module and ensure your branch is rebased on `develop` before opening the PR.
