# kubernetes
## Establish communication between two vms
login to master 192.168.64.3
run
ssh-keygen -t ed25519 (#optional no need set password, press enter)
ssh-copy-id ubuntu@192.168.64.3
#validate
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
##verify if not set
sudo mkdir -p -m 755 /etc/apt/keyrings
#Download the GPG Signing Key
curl -fsSL https://k8s.io | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

#add repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://k8s.io /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
cat kubernetes.list 
deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://k8s.io /

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
validate:
root@master:/etc/apt/keyrings# ls -altr kubernetes-apt-keyring.gpg 
-rw-r--r-- 1 root root 1200 Aug  6 05:51 kubernetes-apt-keyring.gpg
root@master:/etc/apt/keyrings# chmod 644 kubernetes-apt-keyring.gpg 


