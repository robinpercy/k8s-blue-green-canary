# Simple Kubernetes Blue/Green with Canary Demo

## Purpose
This project is meant to provide an example of how basic Blue/Green and Canary functionality can be achieved with standard Kubernetes Deployments and Services.

## Prereqs
This demo requires a kubernetes cluster with approximately 2000 millicpus and 4GB of memory available for workloads.
The cluster must also be configured to allow creation of a public accessible endpoint for LoadBalancer type services.


## apply.sh
The `apply.sh` script performs the following:
1. Creates 2 nginx deployments. Each deployment has a unique `version` label value (either "blue" or "green"), as well as an `app=nginx` label.
And each deployment will serve up a response that describes whether it is "blue" or "green"
1. Creates a single service. The service is initially configured to select both labels of the blue deployment.
1. Scales the blue deployment up to 10 replicas.
1. Makes 100 calls to the service and counts the number of Blue vs Green responses. 
We expect 100% return rate from blue.
1. Patches the service to remove the "version" label selector. Which causes both blue and green deployments to be selected.
1. Makes 100 calls to the service. 
We expect approximately 90% return rate from blue and 10% from green, since the green deployment still only has 1 replica.
1. Scales the green deployment to 10. Then Makes another 100 calls. We expect an approximate 50/50 split.
1. Patches the service to add the `version=green` selector so that only the green deployment is selected/
1. Makes 100 calls to the service. We expect 100% green responses


## Sample Output
```
$ ./apply.sh
configmap/nginx-html-blue created
configmap/nginx-html-green created
deployment.extensions/nginx-blue created
deployment.extensions/nginx-green created
service/nginx-demo created
Waiting for service to create LB
...
Waiting for service to create LB
Waiting for service to create LB
nginx-demo   LoadBalancer   <PRIVATE IP>   <PUBLIC_IP>   80:31389/TCP   33s

Scaling up blue deployment for a more realistic distribution
deployment.extensions/nginx-blue scaled
Waiting for pods to be ready
pods are ready

Only blue deployment is currently selected.
Counting results of 100 requests
    100 Blue

Patching service to select blue and green deployments.
service/nginx-demo patched
Current distribution: 10 blue pods, 1 green pod
Counting results of 100 requests
     93 Blue
      7 Green

Scaling up green deployment for a 50/50 distribution
deployment.extensions/nginx-green scaled
Waiting for pods to be ready
pods are ready

Current distribution: 10 blue pods, 10 green pods
Counting results of 100 requests
     44 Blue
     56 Green
Patching service select only green pods
service/nginx-demo patched

Only green pods are now selected by the service
Counting results of 100 requests
    100 Green

```