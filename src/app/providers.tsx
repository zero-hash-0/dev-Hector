'use client';
import posthog from 'posthog-js';
import { PostHogProvider as PHProvider, usePostHog } from 'posthog-js/react';
import { useEffect } from 'react';
import { usePathname, useSearchParams } from 'next/navigation';
import { Suspense } from 'react';

// ─── Page view tracker ────────────────────────────────────────────────────────
function PageViewTracker() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const ph = usePostHog();

  useEffect(() => {
    if (pathname && ph) {
      const url = pathname + (searchParams?.toString() ? `?${searchParams}` : '');
      ph.capture('$pageview', { $current_url: url });
    }
  }, [pathname, searchParams, ph]);

  return null;
}

// ─── PostHog initialiser ──────────────────────────────────────────────────────
function PostHogInit() {
  useEffect(() => {
    const key = process.env.NEXT_PUBLIC_POSTHOG_KEY;
    const host = process.env.NEXT_PUBLIC_POSTHOG_HOST || 'https://app.posthog.com';

    if (key && key !== 'phc_placeholder_replace_with_real_key' && typeof window !== 'undefined') {
      posthog.init(key, {
        api_host: host,
        capture_pageview: false, // manual via PageViewTracker
        capture_pageleave: true,
        persistence: 'localStorage',
        autocapture: false, // manual events only — keep data clean
      });
    }
  }, []);

  return null;
}

// ─── Analytics hook (use in any component) ───────────────────────────────────
export function useAnalytics() {
  const ph = usePostHog();

  return {
    track: (event: string, properties?: Record<string, unknown>) => {
      if (ph) ph.capture(event, properties);
    },
    identify: (id: string, traits?: Record<string, unknown>) => {
      if (ph) ph.identify(id, traits);
    },
  };
}

// ─── Root provider ────────────────────────────────────────────────────────────
export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <PHProvider client={posthog}>
      <PostHogInit />
      <Suspense fallback={null}>
        <PageViewTracker />
      </Suspense>
      {children}
    </PHProvider>
  );
}
