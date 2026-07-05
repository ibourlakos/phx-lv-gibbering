import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./tests",
  timeout: 30_000,
  retries: 1,

  use: {
    baseURL: process.env.BASE_URL ?? "http://app:4000",
    screenshot: "only-on-failure",
    video: "off",
    // LiveView uses WebSockets — give it headroom
    navigationTimeout: 15_000,
    actionTimeout: 10_000,
  },

  outputDir: "./screenshots",
  reporter: [["list"], ["html", { open: "never", outputFolder: "./playwright-report" }]],

  projects: [
    {
      name: "chromium",
      use: { browserName: "chromium" },
    },
  ],
});
