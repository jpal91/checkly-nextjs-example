import { defineConfig } from "checkly";
import { Frequency, EmailAlertChannel } from "checkly/constructs";

const sendDefaults = {
  sendFailure: true,
  sendRecovery: true,
  sendDegraded: false,
};

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
    ignoreDirectoriesMatch: [
      // Comment out to see fail check
      "**/__checks__/fail/*",
    ],
    // See https://www.checklyhq.com/docs/browser-checks/playwright-test/#global-configuration for available options
    playwrightConfig: {
      use: {
        baseURL:
          process.env.ENVIRONMENT_URL! ||
          "https://checkly-nextjs-example.vercel.app",
      },
    },
    browserChecks: {
      frequency: Frequency.EVERY_30M,
      // Change to match you project structure
      // Ideally you will want to move all checks/tests to one directory for simpler CI deployment
      testMatch: "**/__checks__/**/*.spec.ts",
      // See https://www.checklyhq.com/docs/alerting-and-retries/alert-channels/ for all alert channel types
    },
    alertChannels: [
      new EmailAlertChannel("email-alert-1", {
        address: process.env.CHECKLY_ALERT_EMAIL!,
        ...sendDefaults,
      }),
    ],
  },
  cli: {
    runLocation: "us-east-1",
  },
});
