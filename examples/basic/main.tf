provider "google" {
  project = "local-concord-408802"
  region  = "asia-northeast1"
  zone    = "asia-northeast1-a"
}

#####==============================================================================
##### instance_template module call.
#####==============================================================================
module "instance_template" {
  source               = "git::https://github.com/cypik/terraform-gcp-template-instance.git?ref=v1.0.0"
  name                 = "template"
  environment          = "test"
  region               = "asia-northeast1"
  source_image         = "ubuntu-2204-jammy-v20230908"
  source_image_family  = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"
  disk_size_gb         = "20"
  subnetwork           = module.subnet.subnet_id
  instance_template    = true
  service_account      = null
  ## public IP if enable_public_ip is true
  enable_public_ip = true
  metadata = {
    ssh-keys = <<EOF
      dev:ssh-rsa AAAAB3NzaC1yc2EAA/3mwt2y+PDQMU= suresh@suresh
    EOF
  }
}


#####==============================================================================
##### instance_group module call.
#####==============================================================================
module "instance_group" {
  source              = "git::https://github.com/cypik/terraform-gcp-instance-group.git?ref=v1.0.0"
  region              = "asia-northeast1"
  hostname            = "test"
  autoscaling_enabled = true
  instance_template   = module.instance_template.self_link_unique
  min_replicas        = 2
  max_replicas        = 2
  autoscaling_cpu = [{
    target            = 0.5
    predictive_method = ""
  }]

  target_pools = [
    module.load_balancer.target_pool
  ]
  named_ports = [{
    name = "http"
    port = 80
  }]
}

####==============================================================================
#### load_balancer_custom_hc module call.
####==============================================================================
module "load_balancer" {
  source                  = "../../"
  name                    = "test"
  environment             = "load-balancer"
  region                  = "asia-northeast1"
  port_range              = 80
  network                 = module.vpc.vpc_id
  health_check            = local.health_check
  target_service_accounts = []
}