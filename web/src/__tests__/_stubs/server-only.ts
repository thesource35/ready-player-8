// Vitest stub for the `server-only` boundary marker.
//
// In a real Next.js bundle, importing `server-only` from a Client Component
// throws — that's what enforces the server/client boundary at build time.
// Vitest runs in a plain Node env so the real package always throws, even
// when the file under test is correctly server-side.
//
// This empty module is aliased in vitest.config.ts so server-side modules
// can be imported by tests without tripping the boundary marker. The real
// package still runs in `next build`, so production behavior is preserved.
export {};
