/**
 * This is a Checkly CLI BrowserCheck construct. To learn more, visit:
 * - https://www.checklyhq.com/docs/cli/
 * - https://www.checklyhq.com/docs/cli/constructs-reference/#browsercheck
 */

import {
  BrowserCheck,
  Frequency,
  RetryStrategyBuilder,
} from "checkly/constructs";

// This is an example of manually setting the browser check.
// This is not a requirement, as the base `checkly.config.ts` will
// automatically assign these options for `browser.spec.ts` if this file
// is not present. However, you can manually override default options
// from your config by including this file.
new BrowserCheck("browser-spec-ts", {
  name: "Checkly Next.js Example BrowserCheck",
  activated: true,
  muted: false,
  shouldFail: false,
  runParallel: false,
  runtimeId: "2022.10",
  locations: ["us-east-1", "eu-west-1"],
  tags: ["website", "api"],
  frequency: Frequency.EVERY_10M,
  environmentVariables: [],
  code: {
    entrypoint: "./browser.spec.ts",
  },
  retryStrategy: RetryStrategyBuilder.fixedStrategy({
    baseBackoffSeconds: 0,
    maxRetries: 1,
    maxDurationSeconds: 600,
    sameRegion: false,
  }),
});
