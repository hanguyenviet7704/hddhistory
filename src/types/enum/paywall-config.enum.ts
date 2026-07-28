// Mirrors meup-api PaywallEnvironment (src/modules/paywall-config/enum/paywall-config.enum.ts).
// `environment` is required on both GET and PUT `/paywall-config` -- a write
// can never accidentally fall back to a default. Publishing `prod` updates
// the live Remote Config value every production client reads immediately;
// there is no separate staging step.
export enum PaywallEnvironment {
  DEV = "dev",
  PROD = "prod",
}
