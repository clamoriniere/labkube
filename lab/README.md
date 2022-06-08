# Lab Kubernetes presentation

Lets start by a quick presentation about Kubernetes architecture and several specificities:

* API-Server
* Client (kubectl)
* Kubernetes namespaces

## Configure your environment

### Check your Kubernetes cluster access.

```console
➜ kubectl get nodes
NAME                    STATUS   ROLES                  AGE     VERSION
labkube-control-plane   Ready    control-plane,master   5m28s   v1.23.4
labkube-worker          Ready    <none>                 5m6s    v1.23.4
labkube-worker2         Ready    <none>                 4m54s   v1.23.4
```

### Create a dedicated namespace

It is better to run the lab in a dedicated namespace to ease cleanup.

* list existing namespaces

  ```console
  ➜ kubectl get namespaces
  NAME                 STATUS   AGE
  default              Active   17m
  kube-node-lease      Active   17m
  kube-public          Active   17m
  kube-system          Active   17m
  local-path-storage   Active   17m
  ```

* Create new namespace

  ```console
  ➜ kubectl create namespace labkube
  namespace/labkube created

  ➜ kubectl get namespaces
  NAME                 STATUS   AGE
  default              Active   20m
  kube-node-lease      Active   20m
  kube-public          Active   20m
  kube-system          Active   20m
  labkube              Active   112s
  local-path-storage   Active   20m
  ```

* Set your current namespace to `labkube`

  ```console
  ➜ kubectl config set-context --current --namespace=labkube
  Context "kind-labkube" modified.
  ```
