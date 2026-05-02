import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "src"),
      // The `server-only` package throws at import time when loaded outside
      // a Next.js server context. Vitest's node env triggers that throw
      // even for files that ARE correctly server-side. Alias to a no-op
      // stub so server-side modules can be tested. See
      // src/__tests__/_stubs/server-only.ts for the rationale.
      "server-only": path.resolve(__dirname, "src/__tests__/_stubs/server-only.ts"),
    },
  },
  test: {
    environment: "node",
    include: ["src/**/*.test.ts", "src/**/*.test.tsx"],
    // Tests that depend on jsdom opt-in per-file with `// @vitest-environment jsdom`.
    // Pass a real URL so the created Document has a non-opaque origin (required
    // by the storage getters on jsdom's Window; otherwise `window.localStorage`
    // throws SecurityError on access).
    environmentOptions: {
      jsdom: {
        url: "http://localhost/",
      },
    },
  },
});
