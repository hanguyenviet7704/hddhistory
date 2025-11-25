# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a React TypeScript admin panel for an AI Tutor platform, built with Create React App. The application manages educational content including courses, lessons, exercises, roleplays, theories, and user progress.

## Development Commands

- `npm start` - Run development server on http://localhost:3000
- `npm test` - Run tests in interactive watch mode
- `npm run build` - Build for production
- `npm run eject` - Eject from Create React App (one-way operation)

## Architecture

### Core Structure
- **Entry Point**: `src/index.tsx` renders the main Router component
- **Router**: `src/routes/index.tsx` handles all routing with protected routes
- **State Management**: Redux Toolkit with slices for language and notifications
- **API Layer**: Axios client with automatic token refresh and language headers

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
- **Skillsets** - User skill tracking and management
- **Learning Items** - Exercises, roleplays, theories, documents
- **Keypoints** - Important concepts within lessons
- **User Progress** - Tracking user completion and performance

### Authentication
- JWT-based auth with access/refresh tokens
- Tokens stored in localStorage
- Automatic redirect to login on token failure
- Device tracking for enhanced security

### Environment Variables
- `REACT_APP_BACKEND_AI_TUTOR` - Backend API base URL

## UI Libraries
- Material-UI (@mui/material) for components
- Tailwind CSS for styling
- Framer Motion for animations
- React Dn Kit for drag and drop functionality
- Lucide React & Heroicons for icons