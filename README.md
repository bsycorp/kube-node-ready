# Kubernetes Node Ready

An image to be run in a kubernetes cluster to remove taints from matching nodes when a matching set a pods on a node are healthy. Is intended to only allow pods to be scheduled when a node is deemed "ready", prevents race conditions like with kube2iam between daemonsets and regulary pods.

[![Build Status](https://travis-ci.org/bsycorp/kube-node-ready.svg?branch=master)](https://travis-ci.org/bsycorp/kube-node-ready)

## Kubernetes manifest

Example in `kubernetes.yml`