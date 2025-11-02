#!/bin/sh

set -e

kubectl get nodes  -o wide
kubectl -n kourier-system get endpoints kourier -o wide
kubectl -n kourier-system get pod -o wide
kubectl -n kourier-system get service -o wide
kubectl -n kourier-system describe svc kourier
kubectl -n kube-system get ds kube-proxy -o wide
kubectl -n knative-serving get cm config-network -o jsonpath='{.data.ingress-class}'; echo
kubectl get endpoints -n kourier-system -o wide
