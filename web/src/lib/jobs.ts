import type { FeedPost } from "@/lib/supabase/types";

const META_PREFIX = "meta:";

export type JobListing = {
  id: string;
  title: string;
  company: string;
  location: string;
  pay: string;
  trade: string;
  employmentType: string;
  startLabel: string;
  duration: string;
  description: string;
  requirements: string[];
  urgent: boolean;
  contactEmail: string;
  authorName: string;
  authorTitle: string;
  createdAt: string;
  tags: string[];
};

export type JobDraft = {
  title: string;
  company: string;
  location: string;
  pay: string;
  trade: string;
  employmentType: string;
  startLabel?: string;
  duration?: string;
  description: string;
  requirements?: string[];
  urgent?: boolean;
  contactEmail?: string;
};

type FeedPostRow = FeedPost & {
  user_id?: string | null;
  updated_at?: string | null;
};

function cleanValue(value: string) {
  return value.trim().replace(/\s+/g, " ");
}

function encodeMetaValue(value: string) {
  return encodeURIComponent(cleanValue(value));
}

function decodeMetaValue(value: string) {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

function slugTag(value: string) {
  const compact = value.replace(/[^a-z0-9]+/gi, "").trim();
  return compact ? `#${compact}` : "";
}

function getMeta(tags: string[] = []) {
  const meta = new Map<string, string>();

  for (const tag of tags) {
    if (!tag.startsWith(META_PREFIX)) continue;

    const body = tag.slice(META_PREFIX.length);
    const separatorIndex = body.indexOf("=");
    if (separatorIndex === -1) continue;

    const key = body.slice(0, separatorIndex);
    const value = body.slice(separatorIndex + 1);
    meta.set(key, decodeMetaValue(value));
  }

  return meta;
}

export function buildJobTags(job: JobDraft) {
  const requirements = (job.requirements ?? [])
    .map((item) => cleanValue(item))
    .filter(Boolean);

  const publicTags = [
    "#Hiring",
    slugTag(job.trade),
    slugTag(job.location.split(",")[0] || job.location),
  ].filter(Boolean);

  const metaTags = [
    ["title", job.title],
    ["location", job.location],
    ["pay", job.pay],
    ["trade", job.trade],
    ["employmentType", job.employmentType],
    ["startLabel", job.startLabel || "Immediate"],
    ["duration", job.duration || "Open"],
    ["urgent", job.urgent ? "true" : "false"],
    ["requirements", requirements.join("||")],
    ["contactEmail", job.contactEmail || ""],
  ]
    .filter(([, value]) => cleanValue(value).length > 0)
    .map(([key, value]) => `${META_PREFIX}${key}=${encodeMetaValue(value)}`);

  return Array.from(new Set([...publicTags, ...metaTags]));
}

export function parseJobListing(row: FeedPostRow): JobListing {
  const meta = getMeta(row.tags || []);

  return {
    id: row.id,
    title: meta.get("title") || "Construction Role",
    company: row.author_company || "ConstructionOS Company",
    location: meta.get("location") || "Location not listed",
    pay: meta.get("pay") || "Compensation on request",
    trade: meta.get("trade") || "General",
    employmentType: meta.get("employmentType") || "Full-time",
    startLabel: meta.get("startLabel") || "Immediate",
    duration: meta.get("duration") || "Open",
    description: row.content || "Construction opportunity posted through ConstructionOS.",
    requirements: (meta.get("requirements") || "")
      .split("||")
      .map((item) => cleanValue(item))
      .filter(Boolean),
    urgent: meta.get("urgent") === "true",
    contactEmail: meta.get("contactEmail") || "",
    authorName: row.author_name || row.author_company || "ConstructionOS Member",
    authorTitle: row.author_title || "Hiring Team",
    createdAt: row.created_at,
    tags: (row.tags || []).filter((tag) => !tag.startsWith(META_PREFIX)),
  };
}

export const sampleJobs: JobListing[] = [
  {
    id: "sample-concrete-superintendent",
    title: "Concrete Superintendent",
    company: "Trident Construction",
    location: "Las Vegas, NV",
    pay: "$95-$115K/yr",
    trade: "Concrete",
    employmentType: "Full-time",
    startLabel: "Immediate",
    duration: "18 months",
    description: "Lead field operations on a vertical concrete package with slab, PT, and finish crews. Coordinate manpower, pour sequencing, and safety across a high-rise schedule.",
    requirements: ["ACI certified", "10+ years high-rise experience", "OSHA 30"],
    urgent: true,
    contactEmail: "",
    authorName: "ConstructionOS Demo",
    authorTitle: "Hiring Team",
    createdAt: "2026-04-01T12:00:00.000Z",
    tags: ["#Hiring", "#Concrete", "#LasVegas"],
  },
  {
    id: "sample-journeyman-electrician",
    title: "Journeyman Electrician",
    company: "TruBuild Electrical",
    location: "Austin, TX",
    pay: "$42-$48/hr",
    trade: "Electrical",
    employmentType: "Contract",
    startLabel: "Apr 15",
    duration: "12 months",
    description: "Install and finish power, lighting, and controls on a live data center expansion. Per diem available for the right crew and foreman references.",
    requirements: ["Commercial data center experience", "Lift certification", "IBEW preferred"],
    urgent: false,
    contactEmail: "",
    authorName: "ConstructionOS Demo",
    authorTitle: "Hiring Team",
    createdAt: "2026-03-30T15:30:00.000Z",
    tags: ["#Hiring", "#Electrical", "#Austin"],
  },
  {
    id: "sample-tower-crane-operator",
    title: "Tower Crane Operator",
    company: "Skyline Lift Solutions",
    location: "New York, NY",
    pay: "$85-$105/hr",
    trade: "Crane",
    employmentType: "Full-time",
    startLabel: "Immediate",
    duration: "24 months",
    description: "Operate tower crane on a multi-phase urban high-rise site with tight delivery windows and daily coordination with steel and concrete teams.",
    requirements: ["NCCCO certified", "NYC DOB approved", "5+ years high-rise experience"],
    urgent: true,
    contactEmail: "",
    authorName: "ConstructionOS Demo",
    authorTitle: "Hiring Team",
    createdAt: "2026-03-29T10:15:00.000Z",
    tags: ["#Hiring", "#Crane", "#NewYork"],
  },
];

export function getFallbackJobs() {
  return sampleJobs;
}
