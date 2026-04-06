import type { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = "https://constructionos.world";

  const publicRoutes = [
    "",
    "projects",
    "contracts",
    "market",
    "maps",
    "feed",
    "jobs",
    "ops",
    "ai",
    "pricing",
    "rentals",
    "punch",
    "tasks",
    "wealth",
    "trust",
    "verify",
    "hub",
    "security",
    "field",
    "finance",
    "compliance",
    "clients",
    "analytics",
    "schedule",
    "training",
    "scanner",
    "electrical",
    "tax",
    "roofing",
    "smart-build",
    "contractors",
    "tech",
    "cos-network",
    "empire",
    "terms",
    "privacy",
    "support",
  ];

  return publicRoutes.map((route) => ({
    url: route === "" ? baseUrl : `${baseUrl}/${route}`,
    lastModified: new Date(),
    changeFrequency: "weekly" as const,
    priority: route === "" ? 1 : 0.8,
  }));
}
