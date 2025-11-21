variable "location" {
  description = "The Azure location where resources will be deployed."
  type        = string
  default     = "uksouth"
}

variable "product" {
  description = "The product or application name"
  type        = string
  default     = "hub"
}

variable "builtFrom" {
  type    = string
  default = "hmcts/github-infra"
}
