# Get the kubectl configuration using the Private key you used to create your instances
# call this script by giving as first arg the ip given at the end of create-cluster
# and as second argument your linux user to match /home/YOURUSER/.kube/config

scp -i ~/OpenTicate.pem ubuntu@$1:/home/ubuntu/.kube/config /home/$2/.kube/config

sed -i '4s/^/  /' /home/$2/.kube/config
sed -i '5s/^/    /' /home/$2/.kube/config
sed -i '6,27s/^/      /' /home/$2/.kube/config
sed -i '30s/^/  /' /home/$2/.kube/config
sed -i '31s/^/    /' /home/$2/.kube/config
sed -i '32s/^/      /' /home/$2/.kube/config
sed -i '35s/^/  /' /home/$2/.kube/config
sed -i '36s/^/    /' /home/$2/.kube/config
sed -i '37s/^/      /' /home/$2/.kube/config
sed -i '38s/^/      /' /home/$2/.kube/config
sed -i "s/127.0.0.1\b/$1/g" /home/$2/.kube/config
