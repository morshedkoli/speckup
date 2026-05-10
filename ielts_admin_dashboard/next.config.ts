import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // firebase-admin uses native gRPC addons that must NOT be bundled.
  // This tells both webpack and Turbopack to keep these as runtime requires.
  serverExternalPackages: [
    'firebase-admin',
    'firebase-admin/app',
    'firebase-admin/auth',
    'firebase-admin/firestore',
    '@google-cloud/firestore',
    '@opentelemetry/api',
    'google-auth-library',
    'google-gax',
  ],

  // Allow Next.js <Image> to load chart images hosted on ImgBB CDN
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "i.ibb.co",
        pathname: "/**",
      },
      {
        protocol: "https",
        hostname: "ibb.co",
        pathname: "/**",
      },
    ],
  },
};

export default nextConfig;
