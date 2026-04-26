import type { NextConfig } from "next";

const nextConfig: NextConfig = {
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

  // firebase-admin uses Node.js built-ins — mark as external for Server Components
  serverExternalPackages: ["firebase-admin"],
};

export default nextConfig;
