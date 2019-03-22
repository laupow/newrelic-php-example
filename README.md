# New Relic PHP APM in GKE Cluster

This repository contains resources to create a Google Kubernetes Engine cluster with Terraform
and deploy a example PHP application to the cluster that uses the New Relic PHP APM.

This walk through may take 45-60 minutes

Credit to enricostahn in the [New Relic forums](https://discuss.newrelic.com/t/feature-idea-add-config-newrelic-daemon-host-to-allow-non-localhost-connections/51033/6)
for working through agent/daemon challenges in Kubernetes.

Note that walking through this steps will incur charges in Google Cloud. There's a $300 free credit to get started with any GCP product, which would cover all costs of this walk through. Make sure to delete your resources promptly when you're done. Terraform makes this creation and deletion straightforward.

## Requirements

* Docker
* Terraform
* gcloud-sdk
* kubernetes-cli
* A New Relic account and license key

## Create a new Google Cloud Project
Create a new Google Cloud Project

Enable the [GKE API](https://cloud.google.com/apis/docs/enable-disable-apis) for your new project

Configure a GCP [service account](https://www.terraform.io/docs/providers/google/getting_started.html#adding-credentials)
for Terraform to use.

Set some environment variables to use from here out:

```bash
# required
export GOOGLE_PROJECT=my_gcp_project_id
export GOOGLE_CREDENTIALS=~/path/to/service-account-credentials.json
export NEWRELIC_PHP_LICENSE=my_newrelic_license_key
export CONTAINER_TAG=test1

# optional
export NR_AGENT_VERSION=8.6.0.238
```

Then configure the `gcloud` cli tool for your new project id
`gcloud config set project $GOOGLE_PROJECT`

### Deploy the GKE Resources
_Takes 10-15 minutes_

```bash
terraform init terraform-gke-cluster/
terraform apply terraform-gke-cluster/
```

Wait for the Terraform command to finish

### Build the example app container
Meanwhile, set [set up your machine](https://cloud.google.com/container-registry/docs/pushing-and-pulling)
so you can push container builds to a private container registry at gcr.io. 

Build and push the app container

```bash
docker build -t gcr.io/$GOOGLE_PROJECT/example-app:$CONTAINER_TAG example-app/
docker push gcr.io/$GOOGLE_PROJECT/example-app:$CONTAINER_TAG
``` 

### Connect to the cluster 
When the Terraform is done setting up the GKE cluster, run
```bash
gcloud container clusters get-credentials newrelic-php-example --zone us-central1-a
```
to setup kubeconfig

Run `kubectl get nodes` to see the nodes in your new cluster and ensure you're connecting to the correct cluster

```bash
$ kubectl get nodes
NAME                                                  STATUS   ROLES    AGE   VERSION
gke-newrelic-php-exampl-standard-pool-e7ee4abe-530h   Ready    <none>   10m   v1.10.11-gke.1
gke-newrelic-php-exampl-standard-pool-e7ee4abe-kb93   Ready    <none>   10m   v1.10.11-gke.1
gke-newrelic-php-exampl-standard-pool-e7ee4abe-kb98   Ready    <none>   10m   v1.10.11-gke.1
```


### Deploy the example app to the cluster
Substitute environment vars and send the result to the Kubernetes API server

```bash
$ cat kubernetes/*.yaml | envsubst  '$GOOGLE_PROJECT $NEWRELIC_PHP_LICENSE $CONTAINER_TAG' | kubectl apply -f -
deployment.apps/example-php-app created
configmap/nginx-config created
configmap/newrelic-php-ini created
service/example-php-app created
ingress.extensions/ingress-glbc created
configmap/newrelic-env-config created
deployment.apps/newrelic-php-daemon created
service/newrelic-daemon created
```

Watch the created Ingress resource for 10-12 minutes until 
all ingress.kubernetes.io/backends report HEALTHY instead of Unknown 

```bash
$ watch kubectl describe ing ingress-glbc
Name:             ingress-glbc
Namespace:        default
Address:          35.244.146.99
Default backend:  default-http-backend:80 (10.16.3.7:8080)
Rules:
  Host  Path  Backends
  ----  ----  --------
  *
        /   example-php-app:80 (<none>)
Annotations:
  ingress.kubernetes.io/backends:                    {"k8s-be-31217--ddcc5f8e9dec2055":"HEALTHY","
k8s-be-32279--ddcc5f8e9dec2055":"HEALTHY"}
  ingress.kubernetes.io/forwarding-rule:             k8s-fw-default-ingress-glbc--ddcc5f8e9dec2055
  ingress.kubernetes.io/target-proxy:                k8s-tp-default-ingress-glbc--ddcc5f8e9dec2055
  ingress.kubernetes.io/url-map:                     k8s-um-default-ingress-glbc--ddcc5f8e9dec2055
  kubectl.kubernetes.io/last-applied-configuration:  {"apiVersion":"extensions/v1beta1","kind":"In
gress","metadata":{"annotations":{},"name":"ingress-glbc","namespace":"default"},"spec":{"rules":[
{"http":{"paths":[{"backend":{"serviceName":"example-php-app","servicePort":80},"path":"/"}]}}]}}

Events:
  Type     Reason  Age                 From                     Message
  ----     ------  ----                ----                     -------
  Normal   ADD     13m                 loadbalancer-controller  default/ingress-glbc
  Normal   CREATE  10m                 loadbalancer-controller  ip: 35.244.146.99
```

When the backends are HEALTHY, your Google Cloud Load Balancer is ready for test traffic:

```bash
$ while true; do curl http://35.244.146.99/; sleep .1;  done;
Hello, World!
Delay 162 ms
Done
Hello, World!
Delay 514 ms
Done
Hello, World!
Delay 587 ms
Done
Hello, World!
Delay 45 ms
Done
Hello, World!
Delay 15 ms
Done
Hello, World!
Delay 588 ms
Done
```

### Validate in New Relic
Log into your New Relic account and verify a successful connection was made

Or check the container logs. The applications are set to debug logs for the purposes of this walk through.

```bash
# The Pods will have different signatures in your cluster
$ kubectl logs -f example-php-app-6f7c54d97f-nx5pq -c nginx
$ kubectl logs -f example-php-app-6f7c54d97f-nx5pq -c app
$ kubectl logs -f example-php-app-6f7c54d97f-nx5pq -c socat
$ kubectl logs -f newrelic-php-daemon-744fbc86d8-5w6tg -c daemon
$ kubectl logs -f newrelic-php-daemon-744fbc86d8-5w6tg -c socat
```


### Clean up

Delete the Kubernetes resources
```bash
$ kubectl delete -f kubernetes/
deployment.apps "example-php-app" deleted
configmap "nginx-config" deleted
configmap "newrelic-php-ini" deleted
service "example-php-app" deleted
ingress.extensions "ingress-glbc" deleted
configmap "newrelic-env-config" deleted
deployment.apps "newrelic-php-daemon" deleted
service "newrelic-daemon" deleted
```

Delete the GKE resources with Terraform

```bash
terraform destroy
```

Delete your GCP project
