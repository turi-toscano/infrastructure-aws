#!/bin/bash

set -euxo pipefail
exec > >(tee /var/log/node-bootstrap.log) 2>&1

export DEBIAN_FRONTEND=noninteractive

swapoff -a
sed -i '/\sswap\s/ s/^/#/' /etc/fstab

cat > /etc/modules-load.d/k8s.conf <<'EOF'
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

cat > /etc/sysctl.d/k8s.conf <<'EOF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg containerd conntrack unzip

mkdir -p /etc/containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' > /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

mkdir -p /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${k8s_minor_version}/deb/Release.key" \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${k8s_minor_version}/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

curl -fsSL -o /usr/local/bin/ecr-credential-provider \
  "https://artifacts.k8s.io/binaries/cloud-provider-aws/v1.29.0/linux/amd64/ecr-credential-provider-linux-amd64"
chmod 0755 /usr/local/bin/ecr-credential-provider

mkdir -p /etc/kubernetes
cat > /etc/kubernetes/credential-provider-config.yaml <<'CPEOF'
apiVersion: kubelet.config.k8s.io/v1
kind: CredentialProviderConfig
providers:
  - name: ecr-credential-provider
    matchImages:
      - "*.dkr.ecr.*.amazonaws.com"
      - "*.dkr.ecr-fips.*.amazonaws.com"
      - "public.ecr.aws"
    defaultCacheDuration: "12h"
    apiVersion: credentialprovider.kubelet.k8s.io/v1
CPEOF

cat > /etc/default/kubelet <<'KEOF'
KUBELET_EXTRA_ARGS=--image-credential-provider-config=/etc/kubernetes/credential-provider-config.yaml --image-credential-provider-bin-dir=/usr/local/bin
KEOF

systemctl daemon-reload

%{ if enable_join ~}
echo "Attendo il join command su SSM (${ssm_join_command_path})..."
set +x
for attempt in $(seq 1 60); do
  if JOIN_CMD=$(aws ssm get-parameter --name "${ssm_join_command_path}" \
        --with-decryption --region "${aws_region}" \
        --query Parameter.Value --output text 2>/dev/null); then
    echo "Join command trovato (tentativo $attempt). Provo il join."
    if eval "$JOIN_CMD"; then
      echo "Join completato."
      exit 0
    fi
    echo "Join fallito (control plane non raggiungibile o comando stantio), riprovo..."
    kubeadm reset -f || true # ripulisce lo stato parziale prima di ritentare
  fi
  sleep 30
done

echo "TIMEOUT: join command non trovato su SSM dopo 30 minuti." >&2
exit 1
%{ endif ~}