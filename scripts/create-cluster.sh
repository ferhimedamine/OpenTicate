terraform init ../terraform/aws/
terraform apply -var-file ../terraform/aws/terraform.tfvars -state-out ../terraform/terraform.tfstate ../terraform/aws/
