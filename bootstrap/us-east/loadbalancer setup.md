# AWS Load Balancer Controller setup

This guide installs the official AWS Load Balancer Controller Helm chart through the AWS-managed Argo CD capability for `production-us-east-eks`.

## Prerequisites

Before creating the Argo CD application, confirm that Terraform has created:

- The `aws-load-balancer-controller` IAM role and policy.
- An EKS Pod Identity association for the `kube-system/aws-load-balancer-controller` service account.
- The EKS Pod Identity Agent add-on.
- Public subnet tags with `kubernetes.io/role/elb = 1`.
- Private subnet tags with `kubernetes.io/role/internal-elb = 1`.

Do not add an IAM role annotation to the service account. This cluster uses EKS Pod Identity instead of IRSA.

## 1. Open Argo CD

In the AWS console, open:

`EKS` > `production-us-east-eks` > `Capabilities` > `Argo CD` > `Open Argo CD UI`

## 2. Create the application

Select `Applications` > `New App`, then enter:

| Setting | Value |
| --- | --- |
| Application Name | `aws-load-balancer-controller` |
| Project | `default` |
| Sync Policy | `Manual` |

## 3. Configure the Helm source

| Setting | Value |
| --- | --- |
| Repository URL | `https://aws.github.io/eks-charts` |
| Chart | `aws-load-balancer-controller` |
| Revision | `3.4.3` |

## 4. Select the destination

| Setting | Value |
| --- | --- |
| Cluster | `production-us-east-eks` |
| Namespace | `kube-system` |

## 5. Add Helm values

Paste only the following chart values into the **Helm Values** box:

```yaml
clusterName: production-us-east-eks
region: us-east-1
vpcId: vpc-01ee2d6d3d35fe713

replicaCount: 2

serviceAccount:
  create: true
  name: aws-load-balancer-controller
```

## 6. Deploy

Select `Create`, open the application, and then select `Sync` > `Synchronize`.

The application should report:

- `Synced`
- `Healthy`
- `Succeeded`

## 7. Verify

Configure `kubectl` and verify the deployment:

```powershell
aws eks update-kubeconfig --region us-east-1 --name production-us-east-eks
kubectl get application aws-load-balancer-controller -n argocd
kubectl get deployment aws-load-balancer-controller -n kube-system
```
