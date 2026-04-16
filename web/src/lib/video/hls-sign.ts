// Phase 22 — HLS manifest batch-signer (D-12 / D-13 workaround).
// Supabase Storage cannot sign "the whole directory" nor resolve relative segment URIs,
// so the API route serves a REWRITTEN manifest where every .ts/.m4s line is an absolute
// presigned URL. Per 22-RESEARCH.md Pattern 3 (VERIFIED 2026-04-14).
//
// Flow:
//   1. list(hlsDir) -> all files in the asset's hls/ subdirectory
//   2. createSignedUrls(paths, ttl) -> batch-signed {path, signedUrl}[]
//   3. fetch(signed manifest URL) -> raw index.m3u8 text
//   4. Rewrite every `.ts` / `.m4s` line to its presigned absolute URL
//
// Returns manifestText on success; { error } otherwise. Caller maps error -> 500/502.

import type { SupabaseClient } from '@supabase/supabase-js'

const BUCKET = 'videos'

export type SignHlsResult =
  | { manifestText: string }
  | { error: string }

export async function signHlsManifest(
  supabase: SupabaseClient,
  hlsDir: string,
  ttlSeconds: number,
): Promise<SignHlsResult> {
  // 1. List every file the worker produced under hls/ (manifest + segments).
  const { data: files, error: listErr } = await supabase.storage.from(BUCKET).list(hlsDir)
  if (listErr) return { error: listErr.message }
  if (!files || files.length === 0) return { error: 'empty hls directory' }

  const paths = files.map((f) => `${hlsDir}/${f.name}`)

  // 2. Batch-sign everything in one round-trip (createSignedUrls supports arrays).
  const { data: signed, error: signErr } = await supabase.storage
    .from(BUCKET)
    .createSignedUrls(paths, ttlSeconds)
  if (signErr) return { error: signErr.message }
  if (!signed) return { error: 'sign failed' }

  // Build filename -> signedUrl lookup. `path` may be the full path we passed in,
  // so take the basename to match the manifest's relative segment references.
  const byName = new Map<string, string>()
  for (const s of signed) {
    if (!s.path || !s.signedUrl) continue
    const name = s.path.split('/').pop()!
    byName.set(name, s.signedUrl)
  }

  const manifestSignedUrl = byName.get('index.m3u8')
  if (!manifestSignedUrl) return { error: 'index.m3u8 missing from signed results' }

  // 3. Fetch the manifest text via its signed URL.
  let text: string
  try {
    const res = await fetch(manifestSignedUrl)
    if (!res.ok) return { error: `fetch manifest failed: ${res.status}` }
    text = await res.text()
  } catch (err) {
    return { error: `fetch manifest threw: ${err instanceof Error ? err.message : 'unknown'}` }
  }

  // 4. Rewrite .ts / .m4s segment lines with presigned absolute URLs.
  // Comments (#...) and blank lines pass through unchanged.
  const rewritten = text
    .split('\n')
    .map((line) => {
      const trimmed = line.trim()
      if (!trimmed || trimmed.startsWith('#')) return line
      if (trimmed.endsWith('.ts') || trimmed.endsWith('.m4s')) {
        const s = byName.get(trimmed)
        return s ?? line
      }
      return line
    })
    .join('\n')

  return { manifestText: rewritten }
}
