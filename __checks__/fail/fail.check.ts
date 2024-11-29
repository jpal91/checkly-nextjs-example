import {
  BrowserCheck,
  Frequency,
  RetryStrategyBuilder,
  EmailAlertChannel,
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
//	npx checkly trigger -t fail
//	OR
//	make trigger-fail
//
// MAKE SURE TO INCLUDE ALL NECESSARY ENV VARIABLES IN THE .env.local FILE!! (ie CHECKLY_ALERT_EMAIL)
new BrowserCheck("fail-spec-ts", {
  name: "Will always fail",
  // Change this to true to test funcitonality
  activated: false,
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
    new EmailAlertChannel("email-alert-1", {
      address: process.env.CHECKLY_ALERT_EMAIL!,
      ...sendDefaults,
    }),
    // Uncomment to try out SMS as well
    new SmsAlertChannel("sms-alert-1", {
      phoneNumber: process.env.CHECKLY_ALERT_PHONE_NUMBER!,
      ...sendDefaults,
    }),
  ],
});
