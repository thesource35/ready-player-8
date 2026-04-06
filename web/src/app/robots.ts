import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/api/", "/auth/", "/preview/"],
    },
    sitemap: "https://constructionos.world/sitemap.xml",
  };
}
