# Pod

Deploy your first pod. Almost like ```docker run```, use ```kubectl run```

```console
➜ kubectl run --help
```

let's run our first pod

```console
➜ kubectl run labkube --image=cedriclamoriniere/labkube:v1 --port=8080 --restart=Never
pod "labkube" created
```

let's have a look at pods

```console
➜ kubectl get pods
NAME      READY     STATUS    RESTARTS   AGE
labkube   1/1       Running   0          3m
```

let's get some more details like the IP with extended view

```console
➜ kubectl get pods -owide
NAME      READY     STATUS    RESTARTS   AGE       IP           NODE
labkube   1/1       Running   0          4m        172.17.0.6   minikube
```

let's get some more information about the status

```console
➜ kubectl describe pod labkube
Name:         labkube
Namespace:    labkube
Priority:     0
Node:         labkube-worker/172.18.0.3
Start Time:   Tue, 07 Jun 2022 11:00:00 +0200
Labels:       run=labkube
Annotations:  <none>
Status:       Running
IP:           10.244.1.2
IPs:
  IP:  10.244.1.2
Containers:
  labkube:
    Container ID:   containerd://236cd820fd11863d98afc80aba4d1bbb4e140d50c98bacd36acbea60193e5ae3
    Image:          cedriclamoriniere/labkube:v1
    Image ID:       docker.io/cedriclamoriniere/labkube@sha256:b9564ff40384ff8f19705ea9e124d613af7f2bffe7c0ff63e26bc5e6df6f72bb
    Port:           8080/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Tue, 07 Jun 2022 11:00:08 +0200
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-kp94v (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kube-api-access-kp94v:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  2m12s  default-scheduler  Successfully assigned labkube/labkube to labkube-worker
  Normal  Pulling    2m11s  kubelet            Pulling image "cedriclamoriniere/labkube:v1"
  Normal  Pulled     2m4s   kubelet            Successfully pulled image "cedriclamoriniere/labkube:v1" in 6.966940771s
  Normal  Created    2m4s   kubelet            Created container labkube
  Normal  Started    2m4s   kubelet            Started container labkube
```

what about logs?

```console
kubectl logs labkube
```

can we enter the container?

```console
➜ kubectl exec labkube -it -- /bin/sh
/ # ls
bin      dev      etc      home     labkube  proc     root     sys      tmp      usr      var
/ # ps
PID   USER     TIME  COMMAND
    1 root      0:00 /labkube
    8 root      0:00 /bin/sh
   15 root      0:00 ps
/ # exit
```

let's have a look at the pod definition

```console
➜ kubectl get pod labkube -o yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2022-06-07T09:00:00Z"
  labels:
    run: labkube
  name: labkube
  namespace: labkube
  resourceVersion: "3191"
  uid: acd888e6-1431-4320-add9-1bf655aa91f8
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
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-kp94v
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: labkube-worker
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Never
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: kube-api-access-kp94v
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
status:
  # ...
  hostIP: 172.18.0.3
  phase: Running
  podIP: 10.244.1.2
  podIPs:
  - ip: 10.244.1.2
  qosClass: BestEffort
  startTime: "2022-06-07T09:00:00Z"
```

Now let's play directly with pod object definition. Have a look at file pod-1.yaml.
All the values that have disappeared compare to what we have seen with ```kubectl get pod labkube -oyaml``` are either the default values or status or runtime values.

```console
➜ cat pod-1.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: labkube
  name: labkube
spec:
  containers:
  - image: cedriclamoriniere/labkube:v1
    name: labkube
    ports:
    - containerPort: 8080


➜ kubectl create -f pod-1.yaml
pod "labkube" created
```

Let's create another pod with a modified definition to introduce an environment variable.
Have a look at file pod-2.yaml and inject it.

```console
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: labkube
  name: labkube-env
spec:
  containers:
  - image: cedriclamoriniere/labkube:v1
    env:                                      # <-- Section for environment variable
    - name: MY_LABKUBE_VAR                    #
      value: "Hello from the environment"     #
    name: labkube
    ports:
    - containerPort: 8080


➜ kubectl create -f pod-2.yaml
pod "labkube-env" created
```

Now we should have 2 pods

```console
➜ kubectl get pods
NAME          READY     STATUS    RESTARTS   AGE
labkube       1/1       Running   0          15m
labkube-env   1/1       Running   0          39s
```

Let's have a look at their environment

```console
➜ kubectl exec labkube -- env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=labkube
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
KUBERNETES_SERVICE_HOST=10.96.0.1
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP_PORT=443
HOME=/root

➜ kubectl exec labkube-env -- env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=labkube-env
MY_LABKUBE_VAR=Hello from the environment
KUBERNETES_PORT_443_TCP_PORT=443
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
KUBERNETES_SERVICE_HOST=10.96.0.1
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP_PROTO=tcp
HOME=/root
```

Also something noticeable here: the `HOSTNAME` environment variable is set to the name of the pod.

You can directly edit some sections of the resource. For example you can add an annotation. The following command will open the editor configured for your environment:

```console
➜ kubectl edit pod labkube
```

## Exercice 1

Create a pod running an interactive shell based on "alpine" image.

## Exercice 2

Launch a pod that echo is name and exit.

## Exercice 3

Create a pod running labkube and `edit` its definition to modify/add [annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) and [labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
