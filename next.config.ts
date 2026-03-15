import type { NextConfig } from "next";
import { withSentryConfig } from "@sentry/nextjs";

const nextConfig: NextConfig = {};

export default withSentryConfig(nextConfig, {
  org: process.env.SENTRY_ORG || "opus",
  project: process.env.SENTRY_PROJECT || "opus",
  silent: true,
  widenClientFileUpload: true,
  hideSourceMaps: true,
});
