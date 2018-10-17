# OpenTicate
Powering the future of content validation using HyperLedger Fabric

## What does this project do?
Offer a command line, which permits you to launch a Hyperledger Fabric Cluster running on top of Kubernetes. The command line will then permits you to interact with this cluster, and offers an easy way to define a content validation system based on it.


## Why is this project useful?
HyperLedger vs Legacy systems:
- Immutability, data will not be lost or altered
- Transparency and history within systems for authorized participants
- Improved security and confidentiality
- High performance and scalability (even more easy with Kubernetes)

This implementation offers easy to ways to validate any types of contents, the applications are very broad:
- B2B contracts signed by both parties will be stored and validated on the dedicated channel, offering an immutable, always queryable and private storage of these contracts
- Content validation by certified company/governments, consumers of this content can at any time verify the validation of the content. Infinite span of possibilities: Bio products, Videos tagging, gun control, professionnal experiences of candidates ....
- ...


## How do I get started?
Install terraform, kubectl and go on your machine

Create a AWS account (will cost less than a few dollar months if you are not working on it 24/24 7/7)

Create a ssh key pair in the the region in which you will deploy the cluster and call it openticate (download the private key)

Link your account in the terraform/terraform.tfvars files (create it using https://raw.githubusercontent.com/rancher/quickstart/master/aws/terraform.tfvars.example ) and add at the end of the file:

\# AWS
new_node_count = "X"
new_node_disk = "20"
new_node_type = "t2.medium"


go to scripts/

sh create-cluster (will output an ip necessary for the nex step)

sh getKubeConfig.sh (will create the necessary configuration to connect to Kubernetes cluster from your local machine)

You can now browse to the ip to access the UI of the Cluster and can interact with the Kubernetes cluster directly with your local installation of kubectl.

You can add node by modifying the counts* variable in terraform/terraform.tfvars and then

cd scripts/

sh add-node.sh


You will have a Kubernetes cluster running in AWS, with Hyperledger Fabric running on top of it

## Where can I get more help, if I need it?
