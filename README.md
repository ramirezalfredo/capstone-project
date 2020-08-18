# capstone-project
Capstone Project for Udacity's Cloud DevOps nano-degree

For this project, I've decided to perform blue/green deployments by deploying a new node group instead of a new cluster, minimizing deployment times.

## EKS CLuster Deployment

I'm deploying the cluster outside of the Jenkins pipeline for saving some time on Control Plane deployment and also to have some components like Ingress Controller and External DNS available for application deployment in the pipeline.

To deploy the cluster:

* Switch to the `eks-cluster` folder, run: `./create-stack.sh`.
* Once the stack has been deployed (check the console), run: `./get-credentials.sh`.
* Get the node group Role (not the instance profile), and add it to the `aws-auth-cm.yaml` manifest in order to authorize the self-managed node group to join the cluster.

### Cluster Validation

```sh
$ kubectl get svc
$ kubectl get all -A
```

## Deploy ALB Ingress Controller and external-dns

Both add-ons can be deployed by using the following script:

```sh
$ ./deploy-addons.sh
```

### More information

For the ALB ingress controller setup, follow these instructions:

* https://kubernetes-sigs.github.io/aws-alb-ingress-controller/guide/controller/setup/

For `external-dns`, Policy document and Role has been deployed according to:

* https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md

For both cases, IAM role assigment was done with the instructions in the following documents:

* https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
* https://docs.aws.amazon.com/eks/latest/userguide/create-service-account-iam-policy-and-role.html
* https://docs.aws.amazon.com/eks/latest/userguide/specify-service-account-role.html

Alternate documents:

* https://medium.com/swlh/amazon-eks-setup-external-dns-with-oidc-provider-and-kube2iam-f2487c77b2a1
* https://medium.com/@marcincuber/amazon-eks-with-oidc-provider-iam-roles-for-kubernetes-services-accounts-59015d15cb0c

## Create the Kubernetes namespaces

* kubectl create ns production
* kubectl create ns development

## Testing the development environment

* kubectl -n development port-forward svc/hello-flask 8080:80


To add more parameters to the parameters.json file:

```json
    {
        "ParameterKey": "",
        "ParameterValue": ""
    }
```