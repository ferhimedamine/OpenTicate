terraform init ../terraform/aws/
terraform apply -var-file ../terraform/aws/terraform.tfvars -state-out ../terraform/terraform.tfstate ../terraform/aws/
terraform output --state ../terraform/terraform.tfstate crypto_efs > ./data/efs_dns

sed -i "s/10.10.10.10/$(cat ./data/efs_dns)/g" ../provisioning/fabric/templates/fabric_1_0_template_pod_cli.yaml
sed -i "s/10.10.10.10/$(cat ./data/efs_dns)/g" ../provisioning/fabric/templages/fabric_1_0_template_pod_namespace.yaml

