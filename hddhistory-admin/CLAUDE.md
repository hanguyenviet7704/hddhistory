# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a React TypeScript admin panel for an HDDhistory platform, built with Create React App. The application manages educational content including courses, lessons, exercises, roleplays, theories, and user progress.

It is one of four repos in the HDDhistory workspace — see the parent `../CLAUDE.md` for
the shared domain model, the backend it talks to, and the branch/commit conventions.

## Development Commands

- `npx tsc --noEmit` - Type-check only. **The cheapest correctness gate; prefer it.**
  A `PostToolUse` hook in the workspace `.claude/settings.json` already runs this
  after every edit — read that output instead of re-running it.
- `npm start` - Run development server on http://localhost:3000
- `npm test -- App.test.tsx` - Run ONE suite. Do not run the full `npm test` watch
  suite on the dev machine — it exhausts RAM.
- `npm run build` - Build for production
- Do **not** `npm run eject` — CRA config stays as-is.

## Architecture

### Core Structure
- **Entry Point**: `src/index.tsx` renders the main Router component
- **Router**: `src/routes/index.tsx` (React Router 7) handles all routing with protected routes
- **State Management**: Redux Toolkit, but only for cross-cutting UI concerns
- **API Layer**: Axios client with automatic token refresh and language headers

### Redux is narrow — server data is not in the store
There are exactly two slices (`src/store/slices/lang.slice.ts`,
`notification.slice.ts`) and **zero** `createAsyncThunk`. Entities are never
normalized into the store: a page calls its own `src/services/<entity>Service.ts`
and holds the result in local component state. Follow that pattern for new pages
instead of adding an entity slice.

### Key Directories
- `src/components/` - Reusable UI components (layout, common, forms)
- `src/pages/` - Page components for each entity (courses, lessons, exercises, etc.)
- `src/services/` - API service layers for each entity
- `src/types/` - TypeScript interfaces and enums
- `src/utils/` - Utility functions and hooks
- `src/store/` - Redux store configuration and slices

### Layout System
- Main layout uses Sidebar + Header + Main content area
- Sidebar is collapsible and provides navigation
- Fixed notification system in top-right corner
- Protected routes require authentication

### Data Flow
- Services handle API calls using axiosClient
- Components use React hooks for state and Redux for global state
- Automatic token refresh handles 401 responses
- Language preferences stored in Redux and sent with API requests

### Key Entities
- **Courses** & **Lessons** - Main educational content structure
- **Categories** - User skill tracking and management
- **Learning Items** - Exercises, roleplays, theories, documents
- **Keypoints** - Important concepts within lessons
- **User Progress** - Tracking user completion and performance

### Authentication
- JWT-based auth with access/refresh tokens
- Tokens stored in localStorage
- Automatic redirect to login on token failure
- Device tracking for enhanced security

### Environment Variables
- `REACT_APP_BACKEND_URL` - Backend API base URL

## UI Libraries
- Material-UI (@mui/material) for components
- Tailwind CSS for styling
- Framer Motion for animations
- dnd-kit (`@dnd-kit/*`) for drag and drop (ordering lessons, keypoints, etc.)
- TipTap for rich-text (lesson theory content)
- Lucide React & Heroicons for icons