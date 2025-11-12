from docker.io/k0sproject/k0s:v1.32.8-k0s.0

# RUN docker compose exec -e KUBECONFIG=/var/lib/k0s/kubelet.conf kube k0s kubectl config set-cluster default --server=https://127.0.0.1:6443
RUN apk add curl
RUN apk add helm
RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing grpcurl

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN mv ./kubectl /usr/local/bin && chmod +x /usr/local/bin/kubectl

RUN curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.31.1/crictl-v1.31.1-linux-amd64.tar.gz | tar -C /usr/local/bin -xz crictl

# k0s の containerd.sock の場所がデフォルトでないので設定
COPY <<-EOF /etc/crictl.yaml
runtime-endpoint: unix:///run/k0s/containerd.sock
image-endpoint:   unix:///run/k0s/containerd.sock
timeout: 10
debug: false
EOF



# ARG APP_DOMAIN="knative.platform.localtest.me"
WORKDIR /root

COPY ./setup ./setup
COPY ./services ./services
RUN ./setup/01_kube_download.sh
WORKDIR /
