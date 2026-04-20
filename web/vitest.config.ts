import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "src"),
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
