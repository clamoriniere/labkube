# Kubernetes 101 lab

## Prerequisite

1. A laptop
1. Internet access
1. Access to a Kubernetes cluster. Of course a personal or a test a test cluster :) .
   It can be:
    * [kind](https://kind.sigs.k8s.io/)
    * [minikube](https://minikube.sigs.k8s.io/docs/start/)
    * A manage solution like [Google GKE](https://console.cloud.google.com/kubernetes/add)....
1. Clone this repository: `git clone git@github.com:clamoriniere/labkube.git`

### How to create a local cluster with kind

IMO the simple solution to create a local kubernete cluster is to use [kind](https://kind.sigs.k8s.io/).
`kind` installation is describe [here](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)

For the need of this lab, it can be interesting to create a multi nodes cluster. After followed the `kind`
installation process. To create a local multi nodes cluster, runs the following command

```console
➜ kind create cluster --config config/cluster-kind.yaml --name labkube
Creating cluster "labkube" ...
...
You can now use your cluster with:

➜ kubectl cluster-info --context kind-labkube
```

It will spin up a 3 nodes cluster: 1 control plane + 2 worker nodes.

## Lab

before starting the lab verify that your cluster is up-and-running and that you have access to it.

```console
➜ kubectl get nodes
NAME                    STATUS   ROLES                  AGE     VERSION
labkube-control-plane   Ready    control-plane,master   5m28s   v1.23.4
labkube-worker          Ready    <none>                 5m6s    v1.23.4
labkube-worker2         Ready    <none>                 4m54s   v1.23.4
```

Go to the [lab](/lab) folder and follow the instructions

## how to contribute

### Rebuild the container image use in this lab

```console
export CONTAINER_REGISTRY=<your container registry>

docker build -t $CONTAINER_REGISTRY/labkube:v1 .
```
