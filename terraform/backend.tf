
terraform{
      backend "s3" {
        bucket  = "prm-deductions-terraform-state"
        region  = "eu-west-2"
        key = "docker-gocd-agent/terraform.tfstate"
        encrypt = true
    }
}
