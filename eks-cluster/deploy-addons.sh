#!/bin/bash

helm upgrade --install -n kube-system loadbalancer incubator/aws-alb-ingress-controller \
  --values alb-ingress-controller.yaml

helm upgrade --install -n kube-system route53 bitnami/external-dns \
  --values external-dns.yaml