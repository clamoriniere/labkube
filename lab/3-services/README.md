# Services

Now we know how to deploy our application. How should be target it?

The `Service` resource is here to help. The `Service` resource contains the information relative to the port and protocol to use to consume the service inside a pod. To retrieve the eligible pods for a given service, we use a selector in the spec definition of the service

``` yaml
kind: Service
apiVersion: v1
metadata:
  name: labkube-svc
  labels:
    purpose: training
spec:
  selector:
    run: labkube
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

The selector is a set of `key:value`, it is used by the endpoint controller to select all the pod which have a subset of labels that matches the selector.

The labels section of a pod is inside the metadata and comes from the template definition inside the deployment (and associated replicaSet). Note that all objects have metadata containing labels. The selector is only used against the labels of the pods, not the labels of the `deployment`.

```console
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:                       # <-- Not these labels.
    run: labkube
  name: labkube
spec:
  replicas: 1
  selector:
    matchLabels:                # <-- Not these labels.
      run: labkube
  template:
    metadata:
      labels:                   # <-- YES these labels!
        run: labkube
        app: helloworld
    spec:
      containers:
      - image: cedriclamoriniere/labkube:v1
        name: labkube
        ports:
        - containerPort: 8080  
```

| Match       | Match          | Match                       | Not Match | Not Match                  |
|-------------|----------------|-----------------------------|-----------|----------------------------|
|{run:labkube}|{app:helloworld}|{run:labkube, app:helloworld}|{run:other}|{target:prd, app:helloworld}|

Let's clean previous deployments and pods, and let's create new objects:

```console
➜ kubectl delete deployments,pods --all
...

➜ kubectl get pods
No resources found.
```

Now let's create a brand new deployment that creates pods with the following labels:

```yaml
      labels:
        run: labkube
        instances: type1
```

Let's do that using file `deployment-1.yaml`:

```console
➜ kubectl create -f deployment-1.yaml
deployment "labkube-1" created
```

This should trigger the creation of 2 pods:

```console
➜ kubectl get pods
NAME                         READY     STATUS    RESTARTS   AGE
labkube-1-556c647f86-24lgv   1/1       Running   0          24s
labkube-1-556c647f86-v28gr   1/1       Running   0          24s
```

Now let's create a service with the following selector:

```yaml
  selector:
    run: labkube
```

Let's do that using file `service-1.yaml`:

```yaml
kind: Service
apiVersion: v1
metadata:
  name: labkube-svc
  labels:
    purpose: training
spec:
  selector:
    run: labkube
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

```console
➜ kubectl create -f service-1.yaml
service "labkube-svc" created
```

Now let's look at the resource that was effectively create:

```console
➜ kubectl get service labkube-svc -o yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: "2022-06-08T20:13:48Z"
  labels:
    purpose: training
  name: labkube-svc
  namespace: labkube
  resourceVersion: "146727"
  uid: 080784bd-8af0-4427-bdf4-1fa9ef6df547
spec:
  clusterIP: 10.96.169.14
  clusterIPs:
  - 10.96.169.14
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    run: labkube
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
```

Note that Kubernetes as associated a `clusterIP` to the service. This is the IP that we should target from inside the cluster to target the pod selected by the service.

Let's put ourselves inside the cluster with a shell, for that let's use a light image that as curl:

```console
➜ kubectl run -i -t --rm shell --image=appropriate/curl --restart=Never --command -- /bin/sh
If you don't see a command prompt, try pressing enter.
/ #
```

Now that we are inside that we are inside the cluster let's target the service clusterIP

```console
/ # curl 10.97.199.85/hello
Hello I am pod labkube-1-7b494bb868-9h75d
Welcome to kubernetes lab.
```

In another shell you can check the logs of the pod:

```console
➜ kubectl logs labkube-1-7b494bb868-9h75d -f
2018/06/29 09:53:13 Server listening on port 8080...
2018/06/29 09:53:17 request on URI /ready
...
2018/06/29 09:53:20 request on URI /hello
...
```

As a client application I know that I need to target service named `labkube-svc` but I cannot predict its `clusterIP` that was dynamically assigned by Kubernetes. Should I call Kubernetes to know that `clusterIP`? That is a possibility but that would imply that your application is given the authorization to call Kubernetes API... that is not super cool: for security reasons, and also because applications will end up DDOS the api server of kubernetes. IN act Kubernetes as configured a DNS inside the cluster for you to access the service via its name. Try the following:

```console
/ # curl labkube-svc/hello
Hello I am pod labkube-1-7b494bb868-9h75d
Welcome to kubernetes lab.
```

Try to target the service multiple time using the curl command (with the clusterIP or the dnsname). You should notice that the traffic is loadbalanced between the 2 pods that are associated to the service:

```console
/ # curl labkube-svc/hello
Hello I am pod labkube-1-55796f6f58-zwnww
Welcome to kubernetes lab.
/ # curl labkube-svc/hello
Hello I am pod labkube-1-55796f6f58-295tt
Welcome to kubernetes lab.
/ # curl labkube-svc/hello
Hello I am pod labkube-1-55796f6f58-295tt
Welcome to kubernetes lab.
/ # curl labkube-svc/hello
Hello I am pod labkube-1-55796f6f58-295tt
Welcome to kubernetes lab.
/ # curl labkube-svc/hello
Hello I am pod labkube-1-55796f6f58-zwnww
Welcome to kubernetes lab.
```

When you create a `Service` with a non empty `spec.Selector`, Kubernetes creates another object call `Endpoint` with the same name. Let's have a look at it:

```console
➜ kubectl get endpoints
NAME          ENDPOINTS                           AGE
labkube-svc   10.244.1.37:8080,10.244.2.25:8080   5m2s

➜ kubectl get endpoints labkube-svc -o yaml
```

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  annotations:
    endpoints.kubernetes.io/last-change-trigger-time: "2022-06-08T20:13:48Z"
  creationTimestamp: "2022-06-08T20:13:48Z"
  labels:
    purpose: training
  name: labkube-svc
  namespace: labkube
  resourceVersion: "146728"
  uid: 74198d1f-4c98-447a-94e2-0f874021c9e6
subsets:
- addresses:
  - ip: 10.244.1.37
    nodeName: labkube-worker
    targetRef:
      kind: Pod
      name: labkube-1-55796f6f58-zwnww
      namespace: labkube
      resourceVersion: "146651"
      uid: 614e1310-ebcd-4698-89cd-1894f47d7964
  - ip: 10.244.2.25
    nodeName: labkube-worker2
    targetRef:
      kind: Pod
      name: labkube-1-55796f6f58-295tt
      namespace: labkube
      resourceVersion: "146649"
      uid: 380becc1-94cf-41ff-9d30-847c20b9e968
  ports:
  - port: 8080
    protocol: TCP
```

This endpoint objects contains the list of IPs that matches the service selector. Remember the `ReadinessProbe` ? What if the service was not ready?

Let's modify the content of one pod to make it not ready. The code associated to the readiness probe of our example application check that the file "/ready" exists. Here is the code:

```go
if _, err := os.Stat("/ready"); os.IsNotExist(err) {
    w.WriteHeader(500)
    log.Printf("--> readiness probe failed")
    return
}
```

This empty file was added at in the image:

```docker
FROM busybox

RUN ["touch", "/ready"]
```

Let's 2 things now:

- Monitor the endpoints, in a dedicated shell:

```console
➜ kubectl get endpoints labkube-svc -w
NAME          ENDPOINTS                           AGE
labkube-svc   10.244.1.37:8080,10.244.2.25:8080   46m
...
```

In another console

```console
➜ kubectl logs -f labkube-1-55796f6f58-295tt
```

- Modify the pod content to change its readiness status:

```console
➜ kubectl exec labkube-1-55796f6f58-295tt  -- mv /ready /notready
```

Check how often the probe is running inside you pod; after that period you should see changes in the endpoints list once you have done the `/notready` modification:

```console
➜ kubectl get pods -ojsonpath='{range .items[*]}{.metadata.name} : {.spec.containers[*].readinessProbe.periodSeconds}s{"\n"}{end}'
labkube-1-55796f6f58-295tt : 30s
labkube-1-55796f6f58-zwnww : 30s
shell : s
```

When one of the pod is not ready check the endpoint resource content:

```yaml
➜ kubectl get endpoints labkube-svc -o yaml
apiVersion: v1
kind: Endpoints
metadata:
  annotations:
    endpoints.kubernetes.io/last-change-trigger-time: "2022-06-08T20:21:41Z"
  creationTimestamp: "2022-06-08T20:13:48Z"
  labels:
    purpose: training
  name: labkube-svc
  namespace: labkube
  resourceVersion: "147645"
  uid: 74198d1f-4c98-447a-94e2-0f874021c9e6
subsets:
- addresses:
  - ip: 10.244.1.37
    nodeName: labkube-worker
    targetRef:
      kind: Pod
      name: labkube-1-55796f6f58-zwnww
      namespace: labkube
      resourceVersion: "146651"
      uid: 614e1310-ebcd-4698-89cd-1894f47d7964
  notReadyAddresses:                                # <- New section was created
  - ip: 10.244.2.25
    nodeName: labkube-worker2
    targetRef:
      kind: Pod
      name: labkube-1-55796f6f58-295tt
      namespace: labkube
      resourceVersion: "147643"
      uid: 380becc1-94cf-41ff-9d30-847c20b9e968
  ports:
  - port: 8080
    protocol: TCP
```

You should notice that a `notReadyAddresses` section was created in the resource. This means that the pod is still selected by the service, but no traffic will be sent to it because of its readiness status.

Note that you can also use the `describe` command to get information about objects. Try:

```console
➜ kubectl describe service labkube-svc
Name:              labkube-svc
Namespace:         labkube
Labels:            purpose=training
Annotations:       <none>
Selector:          run=labkube
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.96.169.14
IPs:               10.96.169.14
Port:              <unset>  80/TCP
TargetPort:        8080/TCP
Endpoints:         10.244.1.37:8080
Session Affinity:  None
Events:            <none>


➜ kubectl describe endpoints labkube-svc
Name:         labkName:         labkube-svc
Namespace:    labkube
Labels:       purpose=training
Annotations:  endpoints.kubernetes.io/last-change-trigger-time: 2022-06-08T20:21:41Z
Subsets:
  Addresses:          10.244.1.37
  NotReadyAddresses:  10.244.2.25
  Ports:
    Name     Port  Protocol
    ----     ----  --------
    <unset>  8080  TCP

Events:  <none>
```

## Exercise 1

In case you have modified them during the lab, re-apply the definition of deployment-1 and the service.

```console
➜ kubectl apply -f deployment-1.yaml
...
➜ kubectl apply -f service-1.yaml
...
```

Let's make some cleanup by deleting all pods. Kubernetes will recreate them with in initial status.

```console
➜ kubectl delete pods --all
OR
➜ kubectl delete pods $(kubectl get pods -o name)
...
```

Let's now add a second deployment, using the file deployment-2.yaml:

```console
➜ kubectl apply -f deployment-2.yaml
deployment "labkube-2" created
```

Now your service should target all the pods created by the 2 deployments. You can check this using the following curl command:

```console
/ # curl labkube-svc/mydeployment
Hello I am pod labkube-1-7b494bb868-lwq4t
Welcome to kubernetes lab.
MY_DEPLOYMENT environment variable is set to: My deployment is labkube-1
/ # curl labkube-svc/mydeployment
Hello I am pod labkube-1-7b494bb868-lwq4t
Welcome to kubernetes lab.
MY_DEPLOYMENT environment variable is set to: My deployment is labkube-1
/ # curl labkube-svc/mydeployment
Hello I am pod labkube-2-7b74446546-2w7jm
Welcome to kubernetes lab.
MY_DEPLOYMENT environment variable is set to: My deployment is labkube-2
/ # curl labkube-svc/mydeployment
Hello I am pod labkube-2-7b74446546-2w7jm
Welcome to kubernetes lab.
MY_DEPLOYMENT environment variable is set to: My deployment is labkube-2
/ # curl labkube-svc/mydeployment
Hello I am pod labkube-1-7b494bb868-prnnj
Welcome to kubernetes lab.
MY_DEPLOYMENT environment variable is set to: My deployment is labkube-1
```

### Questions

- Create a service that only target the pods of the second deployment
- Show the endpoints of the new service and curl the new service to validate your setup
## Exercise 2

- Can we target directly the pod instead of using the service clusterIP (or dnsname)?

- If "yes" how to do it?

- Trainer: "Yes you can by using the IP of the pod. That could be interesting for investigation or development purposes. You should not do that with your regular application. Let's do it for the fun:"

```console
➜ kubectl get pods -o wide
NAME                         READY   STATUS    RESTARTS   AGE     IP            NODE              NOMINATED NODE   READINESS GATES
labkube-1-55796f6f58-2s958   1/1     Running   0          7m12s   10.244.2.27   labkube-worker2   <none>           <none>
labkube-1-55796f6f58-wbbkj   1/1     Running   0          7m12s   10.244.1.38   labkube-worker    <none>           <none>
labkube-2-67cb4d69c4-g8pt9   1/1     Running   0          6m9s    10.244.2.28   labkube-worker2   <none>           <none>
labkube-2-67cb4d69c4-nvqbr   1/1     Running   0          6m9s    10.244.1.39   labkube-worker    <none>           <none>
```

Let's take the IP and use it with the curl:

```console
/ # curl 10.244.2.27/hello
curl: (7) Failed to connect to 10.244.2.27 port 80: Connection refused
```

- User: "It is not working! Why did you say it would work?"
- Trainer: "It is going to work: look at your service definition and fix your command to be able to directly target the pod."