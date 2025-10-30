from docker.io/k0sproject/k0s:v1.32.8-k0s.0

# RUN docker compose exec -e KUBECONFIG=/var/lib/k0s/kubelet.conf kube k0s kubectl config set-cluster default --server=https://127.0.0.1:6443
RUN apk add curl
RUN apk add helm
RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing grpcurl

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN mv ./kubectl /usr/local/bin && chmod +x /usr/local/bin/kubectl

# ARG APP_DOMAIN="knative.platform.localtest.me"
WORKDIR /root

COPY ./setup ./setup
RUN ./setup/01_kube_setup_kanative.sh
WORKDIR /
