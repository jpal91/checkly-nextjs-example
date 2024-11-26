import { defineConfig } from "checkly";
import { Frequency } from "checkly/constructs";

// See https://www.checklyhq.com/docs/cli/constructs-reference/#project for further reference
export default defineConfig({
  projectName: "Checkly Next.js Monitoring Example",
  logicalId: "checkly-nextjs-exmaple-monitoring-1",
  repoUrl: "https://github.com/jpal91/checkly-nextjs-example",
  checks: {
    activated: true,
    muted: false,
    runtimeId: "2022.10",
    frequency: Frequency.EVERY_5M,
    // See https://www.checklyhq.com/docs/monitoring/global-locations
    locations: ["us-east-1", "eu-west-1"],
    tags: ["website", "api"],
    checkMatch: "**/__checks__/**/*.check.ts",
    ignoreDirectoriesMatch: [],
    // See https://www.checklyhq.com/docs/browser-checks/playwright-test/#global-configuration for available options
    playwrightConfig: {
      use: {
        baseURL: "https://checkly-nextjs-example.vercel.com",
      },
    },
    browserChecks: {
      frequency: Frequency.EVERY_10M,
      // Change to match you project structure
      // Ideally you will want to move all checks/tests to one directory for simpler CI deployment
      testMatch: "**/__checks__/**/*.spec.ts",
    },
  },
  cli: {
    runLocation: "us-east-1",
  },
});
