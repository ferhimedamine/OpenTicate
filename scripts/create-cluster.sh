terraform init ../terraform/aws/
terraform apply -var-file ../terraform/aws/terraform.tfvars -state-out ../terraform/terraform.tfstate ../terraform/aws/
terraform output --state ../terraform/terraform.tfstate crypto_efs > ./data/efs_dns
terraform output --state ../terraform/terraform.tfstate rancher-url > ./data/rancher_server_ip
terraform output --state ../terraform/terraform.tfstate rancheragent_all > ./data/rancheragent_all

sed -i "s/10.10.10.10/$(cat ./data/efs_dns)/g" ../provisioning/fabric/templates/fabric_1_0_template_pod_cli.yaml
sed -i "s/10.10.10.10/$(cat ./data/efs_dns)/g" ../provisioning/fabric/templages/fabric_1_0_template_pod_namespace.yaml

echo "## Waiting for Kubernetes cluster to be up, 20 sec"
sleep 20

echo "## Creating genesis block, certificats using cryptogen and configtxgen"
sh create-genesisblock.sh

echo "## Copying all necessary files to the EFS inside AWS Infrastructure via one kubernetes node"
scp -r -i ~/OpenTicate.pem ../provisioning/fabric/crypto-config  ubuntu@$(cat ./data/rancheragent_all):/opt/share
scp -r -i ~/OpenTicate.pem ../provisioning/fabric/channel-artifacts  ubuntu@$(cat ./data/rancheragent_all):/opt/share
