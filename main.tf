# See https://www.checklyhq.com/docs/terraform-provider/ for more details

terraform {
  required_providers {
    checkly = {
      source  = "checkly/checkly"
      version = "~> 1.0"
    }
  }
}

variable "checkly_api_key" {}
variable "checkly_account_id" {}
variable "checkly_alert_email_address" {}

provider "checkly" {
  api_key    = var.checkly_api_key
  account_id = var.checkly_account_id
}

data "local_file" "test_script" {
  filename = "${path.cwd}/__checks__/browser.spec.ts"
}

resource "checkly_check" "browser-check" {
  name      = "Checkly Next.js Example Browser Check"
  type      = "BROWSER"
  activated = true
  frequency = 10
  locations = [
    "us-east-1",
    "eu-west-1"
  ]

  alert_settings {
    escalation_type = "RUN_BASED"

    run_based_escalation {
      failed_run_threshold = 1
    }
  }

  alert_channel_subscription {
    channel_id = checkly_alert_channel.email_alert_1
    activated  = true
  }

  script = data.local_file.test_script.content
}

resource "checkly_alert_channel" "email_alert_1" {
  email {
    address = var.checkly_alert_email_address
  }
  send_failure  = true
  send_recovery = true
  send_degraded = false
}

