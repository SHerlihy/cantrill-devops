variable "frontend_sg" {
type = string
}

variable "instance_profile" {
type = string
}

variable "lb_subnet" {
type = string
}

variable "lb_subnets" {
type = list(string)
}

variable "tg_name" {
type = string
}

variable "lb_name" {
type = string
}

variable "asg_name" {
type = string
}

variable "vpc" {
type = string
}

variable "launch_id" {
type = string
}
