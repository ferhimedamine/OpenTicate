# Get the kubectl configuration using the Private key you used to create your instances
# call this script by giving as first arg the ip given at the end of create-cluster
# and as second argument your linux user to match /home/YOURUSER/.kube/config

scp -i ~/OpenTicate.pem ubuntu@$1:/home/ubuntu/.kube/config /home/$2/.kube/config

sed '4s/^/  /' /home/$2/.kube/config
sed '5s/^/    /' /home/$2/.kube/config
sed '6,27s/^/      /' /home/$2/.kube/config
sed '30s/^/  /' /home/$2/.kube/config
sed '31s/^/    /' /home/$2/.kube/config
sed '32s/^/      /' /home/$2/.kube/config
sed '35s/^/  /' /home/$2/.kube/config
sed '36s/^/    /' /home/$2/.kube/config
sed '37s/^/      /' /home/$2/.kube/config
sed '38s/^/      /' /home/$2/.kube/config