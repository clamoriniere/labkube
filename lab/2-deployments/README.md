# Deployment

Now that we know ```pods```, we can ask the following questions:

- What if the pod that I have launched is deleted or crashes?
- What if I want to run multiple instances of the same pod?
- What if I want to rollout a new version of the image ?

The answer is ```deployment```

First delete all the pods inside you namespace:

```console
➜ kubectl delete pods --all
pod "labkube" deleted
pod "labkube-env" deleted
```

Let's use the command ```kubectl create deployment```.

```console
➜ kubectl create deployment labkube --image=cedriclamoriniere/labkube:v1 --port=8080
deployment "labkube" created
```

Instead of create a `labkube` Pod, this command creates a Deployment

```console
➜ kubectl get deployment 
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
labkube   1/1     1            1           27s
```

Let check what is inside this deployment configuration.

```console
➜ kubectl get deployment labkube -oyaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
  creationTimestamp: "2022-06-07T10:04:08Z"
  generation: 1
  labels:
    app: labkube
  name: labkube
  namespace: labkube
  resourceVersion: "10572"
  uid: df7af2a5-42ac-4720-abde-063112b881ef
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: labkube
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: labkube
    spec:
      containers:
      - image: cedriclamoriniere/labkube:v1
        imagePullPolicy: IfNotPresent
        name: labkube
        ports:
        - containerPort: 8080
          protocol: TCP
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
status:
  availableReplicas: 1
  conditions:
  - lastTransitionTime: "2022-06-07T10:04:09Z"
    lastUpdateTime: "2022-06-07T10:04:09Z"
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  - lastTransitionTime: "2022-06-07T10:04:08Z"
    lastUpdateTime: "2022-06-07T10:04:09Z"
    message: ReplicaSet "labkube-598fcbd66d" has successfully progressed.
    reason: NewReplicaSetAvailable
    status: "True"
    type: Progressing
  observedGeneration: 1
  readyReplicas: 1
  replicas: 1
  updatedReplicas: 1
```

What about the pods? Pay attention to the name!

```console
➜ kubectl get pods
NAME                       READY   STATUS    RESTARTS   AGE
labkube-598fcbd66d-7grzg   1/1     Running   0          41s
```

We retrieve the name that we gave to the deployment "labkube" but also 2 sequences that look like identifiers...

Let's have a look at the pod definition. Compared to previous lab on `pods` you should notice that a new section has appeared: ```metadata.ownerReferences```

```yaml
➜ kubectl get pods -oyaml
apiVersion: v1
items:
- apiVersion: v1
  kind: Pod
  metadata:
    creationTimestamp: "2022-06-07T10:04:08Z"
    generateName: labkube-598fcbd66d-
    labels:
      app: labkube
      pod-template-hash: 598fcbd66d
    name: labkube-598fcbd66d-7grzg
    namespace: labkube
    ownerReferences:
    - apiVersion: apps/v1
      blockOwnerDeletion: true
      controller: true
      kind: ReplicaSet
      name: labkube-598fcbd66d
      uid: 00e29522-98b2-49cf-8775-1496113c9f2e
    resourceVersion: "10570"
    uid: fdfc68de-04a7-4a31-9c7b-490a858d3d21
  spec:
    containers:
    ...
```

So the parent of the `pod` is not the `deployment`, it is a `replicaSet`. Let's have a look at that `replicaSet` object.

```console
➜ kubectl get replicaset
NAME                 DESIRED   CURRENT   READY     AGE
labkube-598fcbd66d   1         1         1         17m
```

If you open the yaml definition of the replicaset you will notice that it is really close to the deployment. It contains the number of replicas and the pod definition.

Purpose of the objects by kind:

- The `Pod` runs the container(s)
- The `ReplicaSet` is going to be used by kubernetes to ensure that the relevant number of pods are running.
- The `Deployment` helps to transition from one replicaSet to another (check the spec.strategy section in the definition)

Depending on the modification that you do on the Deployment object the existing replicaSet will be modified or a new one will be create. If a new one is created then the deployment strategy is applied to transition from one definition to another.

Let's delete the current deployment and create one with the resource definition in file ```deployment-1.yaml```

```console
➜ kubectl delete deployment labkube
deployment "labkube" deleted

➜ kubectl apply --record -f deployment-1.yaml
deployment "labkube" created
```

Open a new shell and run the following command to monitor what is happening at pod level:

| to get the kubectl working on the new shell, you can get the kubeconfig file with

```console
kind get kubeconfig --name labkube > /tmp/kubeconfig.yaml
export KUBECONFIG=/tmp/kubeconfig.yaml
```

```console
➜ kubectl get pods -w
NAME                       READY     STATUS    RESTARTS   AGE
labkube-7f97bc77df-zffgp   1/1       Running   0          22s
....
```

Open another new shell and run the following command to monitor what is happening at replicaSet level:

```console
➜ kubectl get replicaset -w
NAME                 DESIRED   CURRENT   READY   AGE
labkube-7f97bc77df   1         1         1       39s
....
```

Now let's change the number of replica to 2, by applying a new definition:

```console
➜ kubectl apply --record -f deployment-2.yaml
deployment "labkube" configured
```

In the screen with the pods events you should see that a new pod is created.

```console
...
NAME                       READY   STATUS              RESTARTS   AGE
labkube-7f97bc77df-zffgp   1/1     Running             0          64s
labkube-7f97bc77df-dccgk   0/1     Pending             0          0s
labkube-7f97bc77df-dccgk   0/1     Pending             0          0s
labkube-7f97bc77df-dccgk   0/1     ContainerCreating   0          0s
labkube-7f97bc77df-dccgk   1/1     Running             0          1s
```

In the screen with the replicaSets events you should see that the replication control has been update, the count are modified.

```console
NAME                 DESIRED   CURRENT   READY   AGE
labkube-7f97bc77df   1         1         1       60s
labkube-7f97bc77df   1         1         1       108s
labkube-7f97bc77df   2         1         1       108s
labkube-7f97bc77df   2         1         1       108s
labkube-7f97bc77df   2         2         1       108s
labkube-7f97bc77df   2         2         2       109s
```

Now let's modify the definition of the pod. This will trigger the creation of a new replicaSet and a pod rolling update:

```console
➜ kubectl apply --record -f deployment-3.yaml
deployment "labkube" configured
```

We can clearly see the rolling update sequence on the replicaSet counters:

```console
NAME                 DESIRED   CURRENT   READY     AGE
...
labkube-76c7c9754d   2         2         2         1m       # Initial state
labkube-58f8fd4bb9   1         0         0         0s       # New Replication controller created
labkube-58f8fd4bb9   1         0         0         0s       
labkube-76c7c9754d   1         2         2         9m       
labkube-58f8fd4bb9   2         0         0         0s       
labkube-76c7c9754d   1         2         2         9m
labkube-58f8fd4bb9   2         1         0         0s       # +1 new pods
labkube-76c7c9754d   1         1         1         9m       # -1 old pods  (but the new one is not yet ready!)
labkube-58f8fd4bb9   2         1         0         0s
labkube-58f8fd4bb9   2         2         0         0s       # +1 new pods
labkube-58f8fd4bb9   2         2         1         0s       
labkube-76c7c9754d   0         1         1         9m      
labkube-76c7c9754d   0         1         1         9m
labkube-76c7c9754d   0         0         0         9m       # -1 old pods
labkube-58f8fd4bb9   2         2         2         0s
```

You can see that during the rolling update the Ready count goes down to 1.

- First we have not defined what qualifies our pod as "Ready": this is the purpose of a `readiness` probe that we can define at container level. Check documentation [here](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/). Here is a probe for our container (check in file deployment-4.yaml):

```yaml
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 3
          periodSeconds: 3
```

- Second we have not tuned our rolling update strategy. We can set some parameters to be sure that we will have always 2 pods running at any point in time. Check the documentation [here](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy). Here is a strategy to have alwasy 2 pods (check in file deployment-4.yaml):

```yaml
        strategy:
            rollingUpdate:
            maxSurge: 1
            maxUnavailable: 0
            type: RollingUpdate
```

Let's perform an update with the new deployment to check the counters:

```console
➜ kubectl apply -f deployment-4.yaml
deployment "labkube" configured
```

Now the sequence of counter always show at least 2 ready pod at any time:

```console
NAME                 DESIRED   CURRENT   READY     AGE
labkube-58f8fd4bb9   2         2         2         23m          # initial state
labkube-7f97bc77df   1         0         0         0s           # creation of new replicaSet
labkube-7f97bc77df   1         0         0         0s
labkube-7f97bc77df   1         1         0         0s
labkube-7f97bc77df   1         1         1         6s           # +1 new pod ready
labkube-58f8fd4bb9   1         2         2         24m
labkube-7f97bc77df   2         1         1         6s
labkube-58f8fd4bb9   1         2         2         24m          
labkube-7f97bc77df   2         1         1         6s
labkube-58f8fd4bb9   1         1         1         24m          # -1 old pod ready
labkube-7f97bc77df   2         2         1         6s
labkube-7f97bc77df   2         2         2         9s           # +1 new pod ready
labkube-58f8fd4bb9   0         1         1         24m
labkube-58f8fd4bb9   0         1         1         24m
labkube-58f8fd4bb9   0         0         0         24m          # -1 old pod 
```

A deployment can `pause/resume`. It is also possible to `rollback` a deployment:

```console
➜ kubectl rollout undo deployment/labkube
deployment "labkube"
```

Pay attention 2 consecutive ```rollout undo``` takes you back to the initial state before the first ```rollout undo```. You can undo to a dedicated version using the flag ```--to-revision```. The revision number can be found in the history.The history is available if the deployment was create and updated with the `--record` flag.

```console
➜ kubectl rollout history deploy/labkube
deployments "labkube"
REVISION  CHANGE-CAUSE
1         kubectl apply --record --filename=deployment-2.yaml
2         kubectl apply --record --filename=deployment-3.yaml
3         kubectl apply --record --filename=deployment-4.yaml
```

Another way of changing the number of replicas for a given deployment:

```console
➜ kubectl scale --replicas=5 deployment/labkube
deployment "labkube" scaled
```

Here we are a simple case with only one deployment and set of pods. If you start doing multiple deployments, how does kubernetes associates the pods with the deployment?

You said `ownerRef` ? Well no, this is just for garbage collection purposes. In fact the association is done thanks to the `deployment.spec.selector` and the `pod.metadata.labels`. 

If the `selector` match a subset of the pod `labels` then kubernetes considers that the deployment controls the pod. This means that a pod can be under the control of several deployments! Select your labels and selector carefully to avoid such situation that lead to undetermined behavior.

## Exercises

### Exercise 1

Open the definition of a `replicaset` and check the ownerRef section.

### Exercise 2

Using the image `docker/whalesay` from [here](https://hub.docker.com/r/docker/whalesay/), produce a deployment that generates pods which logs would be something like that:

```console
 ______________________ 
< exo1-757d9b6645-4c652 >
 ---------------------- 
    \
     \
      \     
                    ##        .            
              ## ## ##       ==            
           ## ## ## ##      ===            
       /""""""""""""""""___/ ===        
  ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~   
       \______ o          __/            
        \    \        __/             
          \____\______/   

```

where `exo1-757d9b6645-4c652` is the name of the pod producing that logs.

### Exercise 3

Check the status of the pods created during the Exercise 2. What can you do to avoid the "CrashLoopBackOff" state (if it is the case) ?
