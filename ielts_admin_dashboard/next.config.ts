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

};

export default nextConfig;
