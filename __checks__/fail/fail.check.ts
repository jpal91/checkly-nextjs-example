import {
  BrowserCheck,
  Frequency,
  RetryStrategyBuilder,
  SmsAlertChannel,
} from "checkly/constructs";

const sendDefaults = {
  sendFailure: true,
  sendRecovery: true,
  sendDegraded: false,
};

// To preview how you will be notified of a test failure, this check will
// always fail.
//
// To see the functionality, the check must be deployed on Checkly and you can manually
// trigger it via the command line ->
//	make trigger-fail
//
// MAKE SURE TO INCLUDE ALL NECESSARY ENV VARIABLES IN THE .env.local FILE!! (ie CHECKLY_ALERT_EMAIL)
new BrowserCheck("fail-spec-ts", {
  name: "Will always fail",
  activated: true,
  muted: false,
  shouldFail: false,
  runParallel: false,
  runtimeId: "2022.10",
  locations: ["us-east-1", "eu-west-1"],
  tags: ["fail"],
  frequency: Frequency.EVERY_10M,
  environmentVariables: [],
  code: {
    entrypoint: "./fail.spec.ts",
  },
  retryStrategy: RetryStrategyBuilder.noRetries(),
  alertChannels: [
    new SmsAlertChannel("sms-alert-1", {
      phoneNumber: process.env.CHECKLY_ALERT_PHONE_NUMBER!,
      ...sendDefaults,
    }),
    // Add more channels to try additional alerts!
  ],
});
