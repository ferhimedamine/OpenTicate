# Get the kubectl configuration using the Private key you used to create your instances
# call this script by giving as first arg the ip given at the end of create-cluster
# and as second argument your linux user to match /home/YOURUSER/.kube/config

scp -o StrictHostKeyChecking=no -i ~/OpenTicate.pem ubuntu@$(cat ./data/rancher_server_ip | sed 's/https\?:\/\///'):/home/ubuntu/.kube/config /home/$1/.kube/config

sed -i '4s/^/  /' /home/$1/.kube/config
sed -i '5s/^/    /' /home/$1/.kube/config
sed -i '6,27s/^/      /' /home/$1/.kube/config
sed -i '30s/^/  /' /home/$1/.kube/config
sed -i '31s/^/    /' /home/$1/.kube/config
sed -i '32s/^/      /' /home/$1/.kube/config
sed -i '35s/^/  /' /home/$1/.kube/config
sed -i '36s/^/    /' /home/$1/.kube/config
sed -i '37s/^/      /' /home/$1/.kube/config
sed -i '38s/^/      /' /home/$1/.kube/config
sed -i "s/127.0.0.1\b/$(cat ./data/rancher_server_ip | sed 's/https\?:\/\///')/g" /home/$1/.kube/config
