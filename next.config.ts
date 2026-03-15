import type { NextConfig } from "next";
import path from "path";
import { withSentryConfig } from "@sentry/nextjs";

const nextConfig: NextConfig = {
  experimental: {
    turbo: {
      root: path.resolve(__dirname),
    },
  },
};

export default withSentryConfig(nextConfig, {
  // Sentry org + project (set in .env or Vercel dashboard)
  org: process.env.SENTRY_ORG || "opus",
  project: process.env.SENTRY_PROJECT || "opus",

  // Upload source maps to Sentry on build (production only)
  silent: true, // suppress CLI output during builds
  widenClientFileUpload: true,
  hideSourceMaps: true,
  disableLogger: true,

  // Automatically tree-shake Sentry logger statements
  automaticVercelMonitors: false,
});
