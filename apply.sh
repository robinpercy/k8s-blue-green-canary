#! /bin/bash
#

kubectl create configmap nginx-html-blue --from-file ./blue-html

kubectl create configmap nginx-html-green --from-file ./green-html

kubectl apply -f manifests

# Give a few seconds for endpoints to reconfigure if this is a subsequent run
sleep 5 

until kubectl get svc nginx-demo --no-headers | grep -v pending; do echo "Waiting for service to create LB"; sleep 3; done

export PUBLIC_IP=$(kubectl get svc nginx-demo -ojsonpath="{.status.loadBalancer.ingress[0].ip}")

function curl_count {

    echo "Counting results of 100 requests"
    for x in {1..100}; do curl -s ${PUBLIC_IP} --retry 3 | grep title | sed "s/\s*<title>\|<\/title>//g"; done | sort | uniq -c 
}

echo ""
echo "Scaling up blue deployment for a more realistic distribution"
kubectl scale deploy nginx-blue --replicas=10
while kubectl get pod -l version=blue --no-headers | grep -i pending >/dev/null; do echo "Waiting for pods to be ready"; sleep 3; done
sleep 3
echo "pods are ready"


echo ""
echo "Only blue deployment is currently selected."
curl_count

echo ""
echo "Patching service to select blue and green deployments."
kubectl patch svc nginx-demo --type='json' -p='[{"op": "replace", "path": "/spec/selector", "value": {"app":"nginx"}}]'

echo "Current distribution: 10 blue pods, 1 green pod"
curl_count

echo ""
echo "Scaling up green deployment for a 50/50 distribution"
kubectl scale deploy nginx-green --replicas=10
while kubectl get pod -l version=green --no-headers | grep -i pending >/dev/null; do echo "Waiting for pods to be ready"; sleep 3; done
sleep 3
echo "pods are ready"

echo ""
echo "Current distribution: 10 blue pods, 10 green pods"
curl_count

echo "Patching service select only green pods"
kubectl patch svc nginx-demo --type='json' -p='[{"op": "replace", "path": "/spec/selector", "value": {"app":"nginx", "version":"green"}}]'
sleep 5

echo ""
echo "Only green pods are now selected by the service"
curl_count