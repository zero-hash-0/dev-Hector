# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev       # Start local dev server at http://localhost:3000
npm run build     # Production build
npm run start     # Serve the production build
npm run lint      # ESLint (Next.js + TypeScript rules)
```

There is no test suite in this repository.

## Architecture

This is a **Next.js 16 / React 19 / TypeScript** application — a personal productivity and portfolio site with a task management app ("Opus") at its core.

### App Router layout (`src/app/`)

| Route | Purpose |
|---|---|
| `/opus` | Main Opus task management SPA |
| `/launch` | Landing/marketing page |
| `/beta` | Beta signup page |
| `/jellycat` | Jellycat collection portfolio |
| `/api/beta` | REST endpoint — beta tester registration (Resend Audiences as data store) |
| `/api/waitlist` | REST endpoint — waitlist signup |

### Opus — the core app (`src/app/opus/`)

Opus is a **single-page, client-only app** (`"use client"`) that uses local React state (no external state library, no database from the client's perspective). Key data model:

```ts
interface Task {
  id: string;
  title: string;
  tag: "work" | "side" | "learn";
  priority: "high" | "mid" | "low";
  schedule: "today" | "later";
  done: boolean;
}
```

**Momentum score** = `streak * 4 + (completedToday / totalToday) * 28` (0–100 range).

The app is mobile-first; on desktop it renders inside a phone-frame preview.

### Backend API pattern

API routes live under `src/app/api/`. They use **Resend** (not a traditional DB) as persistent storage — beta testers are stored as Resend Audience contacts. Email delivery also uses Resend. Early testers (first 25) receive a gold-badge bonus tracked via the contact count.

### Shared components (`src/components/`)

Reusable UI pieces (navbar, footer, analytics wrapper). Custom SVG components (LlamaIcon, MomentumRing, StreakDots, TabIcon) are defined inline alongside their parent pages rather than in `src/components/`.

### Non-web sub-projects

- `ios/` — Swift/Xcode companion app; developed separately in Xcode
- `roblox/` — Roblox Lua integration; not part of the Next.js build

## Key conventions

- **Inline styles over CSS classes**: `OpusApp` and other rich UI components use `style={{}}` objects extensively rather than Tailwind utilities. New UI work in Opus should follow this pattern.
- **Tailwind for layout/marketing pages**: Landing page, beta page, and shared components use Tailwind utilities and `md:` breakpoints.
- **Path alias**: `@/*` resolves to `./src/*` (configured in `tsconfig.json`).
- **Environment variables**: See `.env.example` for required keys — PostHog, Sentry DSN, Resend API key, and beta invite codes. Never commit real values.
- **Sentry**: Configured via `next.config.ts` wrapping; errors are captured automatically in production.
- **PostHog**: Initialized in a `"use client"` Analytics component; wrap new pages with it for page-view tracking.
- **ASCII section dividers**: `─────` style comments are used inside large component files to mark logical sections — follow this pattern when editing those files.
