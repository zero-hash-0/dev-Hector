import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,

  // Performance monitoring
  tracesSampleRate: 0.1, // 10% of transactions — low cost, enough signal

  // Session replay (captures screen recordings of errors)
  replaysOnErrorSampleRate: 1.0,  // 100% on errors
  replaysSessionSampleRate: 0.05, // 5% of sessions

  // Only enable in production
  enabled: process.env.NODE_ENV === 'production',

  integrations: [
    Sentry.replayIntegration({
      maskAllText: false,      // Task content visible in replays (helpful for debugging)
      blockAllMedia: false,
    }),
  ],

  // Don't send noise
  ignoreErrors: [
    'ResizeObserver loop limit exceeded',
    'Non-Error promise rejection captured',
  ],
});
