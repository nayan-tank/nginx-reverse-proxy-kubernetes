# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Install necessary packages
sudo apt install -y curl apt-transport-https ca-certificates curl gpg net-tools

# Disable Swap
sudo swapoff -a
sudo sed -i '/swap/ s/^/#/' /etc/fstab

# Enable kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set sysctl params required by Kubernetes
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Install containerd
sudo apt install -y containerd

# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Edit: set SystemdCgroup = true
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# Add Kubernetes apt repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update

# Install Kubernetes components
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl  
sudo systemctl enable kubelet
sudo systemctl start kubelet    

# Verify installation
kubelet --version
kubeadm version
kubectl version --client
containerd --version

# End of script





sudo kubeadm init --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


kubeadm join < IP Address >:6443 --token 4ll843.examplewyid06bc04 \
	--discovery-token-ca-cert-hash sha256:wuiwjw383728117dfe6c12337e028a8cc77ad3dc431f5277c758dc599a


/etc/hosts
==========
127.0.0.1   localhost
::1         localhost ip6-localhost ip6-loopback


Master Node UFW Rules
=====================
ufw allow 80/tcp
ufw allow 443/tcp
# API Server
sudo ufw allow from 192.168.200.0/24 to any port 2379:2380 proto tcp
# Kubelet
sudo ufw allow from 192.168.200.0/24 to any port 10250 proto tcp
# NodePorts
sudo ufw allow from 192.168.200.0/24 to any port 30000:32767 proto tcp
# Calico BGP
sudo ufw allow from 192.168.200.0/24 to any port 179 proto tcp
# Calico VXLAN
sudo ufw allow from 192.168.200.0/24 to any port 4789 proto udp
# Flannel VXLAN
sudo ufw allow from 192.168.200.0/24 to any port 8472 proto udp


Worker Node UFW Rules
======================
sudo ufw allow from 192.168.200.0/24 to any port 80 proto tcp
sudo ufw allow from 192.168.200.0/24 to any port 443 proto tcp
# Kubelet
sudo ufw allow from 192.168.200.0/24 to any port 10250 proto tcp
# NodePorts
sudo ufw allow from 192.168.200.0/24 to any port 30000:32767 proto tcp
# Calico BGP
sudo ufw allow from 192.168.200.0/24 to any port 179 proto tcp
# Calico VXLAN
sudo ufw allow from 192.168.200.0/24 to any port 4789 proto udp
