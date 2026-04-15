// Owner: 22-04-PLAN.md Wave 2 — VOD signed-manifest batch signer (VIDEO-01-H)
// Tests: signHlsManifest batch-signs manifest + segments, rewrites .ts/.m4s lines with presigned URLs.
import { describe, it, expect, vi, beforeEach } from "vitest";

// Real manifest body (3 segments). We'll rewrite every .ts line to its signed URL.
const RAW_MANIFEST = [
  "#EXTM3U",
  "#EXT-X-VERSION:3",
  "#EXT-X-TARGETDURATION:6",
  "#EXT-X-PLAYLIST-TYPE:VOD",
  "#EXTINF:6.0,",
  "segment_000.ts",
  "#EXTINF:6.0,",
  "segment_001.ts",
  "#EXTINF:5.2,",
  "segment_002.ts",
  "#EXT-X-ENDLIST",
  "",
].join("\n");

function makeSupabaseMock(opts: { files: string[]; manifestBody?: string } = { files: [] }) {
  const listMock = vi.fn();
  const createSignedUrlsMock = vi.fn();
  listMock.mockResolvedValue({
    data: opts.files.map((name) => ({ name })),
    error: null,
  });
  createSignedUrlsMock.mockResolvedValue({
    data: opts.files.map((name) => ({
      path: name,
      signedUrl: `https://storage.example.com/signed/${name}?token=abc`,
    })),
    error: null,
  });
  return {
    storage: {
      from: vi.fn().mockReturnValue({
        list: listMock,
        createSignedUrls: createSignedUrlsMock,
      }),
    },
    _listMock: listMock,
    _createSignedUrlsMock: createSignedUrlsMock,
  };
}

describe("signHlsManifest — VOD batch-signing + manifest rewrite (Pattern 3)", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    // Mock global fetch used to pull manifest text via its signed URL.
    global.fetch = vi.fn(async (url: string) => {
      if (String(url).includes("index.m3u8")) {
        return new Response(RAW_MANIFEST, { status: 200 }) as unknown as Response;
      }
      return new Response("", { status: 404 }) as unknown as Response;
    }) as unknown as typeof fetch;
  });

  it("lists files, batch-signs, and rewrites every .ts line with its presigned URL", async () => {
    const { signHlsManifest } = await import("@/lib/video/hls-sign");
    const supabase = makeSupabaseMock({
      files: ["index.m3u8", "segment_000.ts", "segment_001.ts", "segment_002.ts"],
    });
    const out = await signHlsManifest(supabase as unknown as Parameters<typeof signHlsManifest>[0], "org/proj/asset/hls", 3600);
    if ("error" in out) throw new Error(`expected manifestText, got error: ${out.error}`);
    // Every .ts line should now be an absolute signed URL.
    expect(out.manifestText).toContain("https://storage.example.com/signed/segment_000.ts?token=abc");
    expect(out.manifestText).toContain("https://storage.example.com/signed/segment_001.ts?token=abc");
    expect(out.manifestText).toContain("https://storage.example.com/signed/segment_002.ts?token=abc");
    // Non-segment lines preserved.
    expect(out.manifestText).toContain("#EXTM3U");
    expect(out.manifestText).toContain("#EXT-X-ENDLIST");
    expect(out.manifestText).toContain("#EXTINF:6.0,");
    // createSignedUrls called ONCE with all paths (batch).
    expect(supabase._createSignedUrlsMock).toHaveBeenCalledTimes(1);
    const [paths] = supabase._createSignedUrlsMock.mock.calls[0];
    expect(paths).toHaveLength(4);
    expect(paths).toContain("org/proj/asset/hls/index.m3u8");
    expect(paths).toContain("org/proj/asset/hls/segment_000.ts");
  });

  it("rewrites .m4s segments (fMP4 variant) defensively", async () => {
    const FMP4_MANIFEST = [
      "#EXTM3U",
      "#EXT-X-MAP:URI=\"init.m4s\"",
      "#EXTINF:6.0,",
      "segment_000.m4s",
      "#EXT-X-ENDLIST",
      "",
    ].join("\n");
    global.fetch = vi.fn(async () => new Response(FMP4_MANIFEST, { status: 200 })) as unknown as typeof fetch;
    const { signHlsManifest } = await import("@/lib/video/hls-sign");
    const supabase = makeSupabaseMock({
      files: ["index.m3u8", "init.m4s", "segment_000.m4s"],
    });
    const out = await signHlsManifest(supabase as unknown as Parameters<typeof signHlsManifest>[0], "org/proj/asset/hls", 3600);
    if ("error" in out) throw new Error(out.error);
    expect(out.manifestText).toContain("https://storage.example.com/signed/segment_000.m4s?token=abc");
  });

  it("returns error when hls directory is empty", async () => {
    const { signHlsManifest } = await import("@/lib/video/hls-sign");
    const supabase = makeSupabaseMock({ files: [] });
    const out = await signHlsManifest(supabase as unknown as Parameters<typeof signHlsManifest>[0], "empty/dir", 3600);
    expect("error" in out).toBe(true);
  });
});
