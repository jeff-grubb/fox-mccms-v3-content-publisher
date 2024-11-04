variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
  validation {
    condition     = contains(["us-east-1", "us-west-2"], var.region)
    error_message = "Valid regions are us-east-1, us-west-2."
  }
}

variable "environment_name" {
  type = string
  description = "The name of the environment [stage|prod]"

  validation {
    condition = var.environment_name == "dev" || var.environment_name == "stage" || var.environment_name == "prod"
    error_message = "Environment must be stage or prod"
  }
}

variable "app_name" {
  type        = string
  default     = "fox-mccms-v3-content-publisher"
  description = "name of the app"
}

variable "logging_level" {
  type        = string
  default     = "debug"
  description = "Verbosity for Lambda functions logging"
  validation {
    condition     = contains(["error", "warn", "info", "verbose", "debug", "silly"], var.logging_level)
    error_message = "Valid logging levels are [error, warn, info, verbose, debug, silly]"
  }
}

variable "business_unit" {
  type        = string
  description = "The business unit for this deployment"
}
