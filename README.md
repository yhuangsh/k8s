# Kubernetes Experiments on Alibaba Cloud

This project uses a series of scripts to setup a 3-master-3-worker Kubernetes cluster on Alibaba's Aliyun Cloud using 7 standard Aliyun ECS instances. 

## ECS resources used

This experiment uses the following Aliyun resources:
- a0 node, bridge and working node for settting up the cluster master and worker nodes and also act as soft load balancer and reverse proxy to Kubernetes API servers running on the master
- m0, m1, m2 nodes, master nodes running the cluster's control plane 
- w0, w1, w2 nodes, wokers nodes running the application pods

- a0, w0, w1, w2 are provisioned with public IPs (EIP or fixed), so they have internet access
- m0, m1 m2 are provisioned with cloud internal IPs only

- a0 is provisioned with 1 CPU, 0.5 GiB, (ecs.t5-lc2m1.nano)
- m0, m1, m2, w0, w1, w2 are provisioned with 1 CPU, 1 GiB RAM (ecs.t5-lc1m1.small)

- Make sure all the ECS instances are in one security group
- Mare sure the following ports are open within your clusters. Aliyun by default only opens port 22, 80 and 433
  - TCP port 6443, this is for the Kubernetes API server
  - TCP port 6873 and UDP ports 6873/6874, these are for Weave Net pod network drivers

- All nodes are provisioned with default/minimal settings for other resources (I/O, bandwidth, disk, etc.)
- All nodes are running Ubuntu 16.04 LTS (Xenial)
- All nodes must be provisioned within the same region, but can spread across difference availability zones. This experiment puts master nodes on 3 different availablility zones

This is the probably the cheapest possible configuration for this experiment. If you use these resources plus 4 public IPs, it'll cost you about 100 RMB for 1 week, about 3000 RMB for a year. As a comparison, if you use Aliyun's managed Kubernetes cluster with the same 3-master-3-worker setup with lowest possible configuration ecs.n1.medium (2 CPU, 4 GiB), it'll cost you about 2000 RMB per node a year, that's 12,000 RMB a year just for the VMs. Of course, how much workload can a 3000-RMB cluster take remains to be seen and will be covered by future experiments. My guts feeling is this is a good base and with Kubernetes you will be able to horizontally scale your cluster little by little

I've tested that master nodes won't run in a 0.5 GiB configuration. Whether worker nodes can is something you can try. 

Besides, your local machine will be used in the set up process and when the setup is done your local machine will be set up to do kubectl to administrate the cluster remotely. Because this experiment uses bash scripts a Mac or Linux machine is recommended.

## Preparation on local machine

The setup process uses a series of bash scripts. Scripts starting with 
- `_` are the ones run on your local machine
- `a0` are the ones run on your a0 node
- `m-` are the ones run on each of your master nodes
- `m0-`, `m1-`, `m-2` are the ones run on designated master nodes
- `w-` are the ones run on each of you worker nodes 

In order to run the scripts, `git clone https://github.com/yhuangsh/k8s && cd k8s`. The scripts are supposed to run from `k8s`'s git root. The paths in the following sections are all relative to this git root unless otherwise specified.

### Install tools that run on your local machine

Tools you need to install and run on your local machine are:
- `git`, obviously
- `docker`, download and instal Docker for Mac Community Edition. `brew install docker` should also work, but Docker for Mac CE was the one I used. YMMV.
- `cfssl`, download from cfssl's github or use `brew install cfssl`
- `kubectl`, install with `brew install kubernetes-cli` or download from Google's official 

### Download ETCD binary

Run the script `_dl-etcd.sh` to download the `etcd` and `etcdctl` binaries. The donwloaded files will be put in `bin/download`. 

### Pull and save Kubenetes docker images

Run the script `_pull-kubeadm-images.sh`. This script pulls the official Kubernetes images that `kubelet` will need to run master and worker nodes alike, plus the two Weave Net images that will drive the pod network withint the clusters. 

Note that the images are hosted on Google servers. Make sure there is an active **VPN connection** if run from within China mainland. 

Run the script `_save-kubeadm-images.sh`. This script dumps the pulled images and save them into a local binary file, so we can copy them to the Aliyun nodes.

### Generate certificates

Run the script `_gen-certs.sh`. This script generates the CA and the core certificate for your master nodes and will be used by `etcd` and `kubeadm` to set up security for your ETCD and Kubernetes cluster.

Make sure you **change the IP address variables** in this script to reflect your set up.

### Copy files to a0

Change `_cp-bin-to-a0.sh` and `_cp-certs0to-a0.sh` scripts so they use your a0 and master nodes' host names. 

SSH to a0 and do `git clone https://github.com/yhuangsh/k8s`. 

Run the scripts, still on your local machine, `_cp-bin-to-a0.sh` and `_cp-certs-to-a0.sh`. This script copies binaries and certificates files to your a0 node.

## Preparation on a0 node

You should have cloned this repository on your a0 node and have the `bin/` and `certs` directories under your git root populated.

### Download Kubernetes core binaries  

Kubernetes core binaries and dependencies are not part of standard Ubuntu distribution. They are hosted on Google's storage which cannot be access without VPN. To workaround, we use a mirror from UTSC. 

Add below line to `/etc/apt/sources.list.d/kubernetes.list` on your a0 node:
```
deb http://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-xenial main
```
 
Note that this source is unauthenticated. UTSC is a well-known and credible university in China. And their mirror is updated very frequently and always have the latest Kubernetes packages. If you know another mirror in China that's authenticated, please let me know.

Once the UTSC source is set, download the following packages:

```
cd bin
sudo apt-get download --allow-unauthenticated \
  cri-tools_1.12.0-00_amd64.deb \
  ebtables_2.0.10.4-3.4ubuntu2.16.04.2_amd64.deb \
  kubeadm_1.13.1-00_amd64.deb \
  kubectl_1.13.1-00_amd64.deb \
  kubelet_1.13.1-00_amd64.deb \
  kubernetes-cni_0.6.0-00_amd64.deb \
  socat_1.7.3.1-1_amd64.deb 
```

*TODO: make the above into a script*.

At this point, your `bin/` directory should have all the `.deb` file and the docker images copied from your local machine, something like this:

```
user@host:~/k8s$ ls bin
coredns_1.2.6
cri-tools_1.12.0-00_amd64.deb
ebtables_2.0.10.4-3.4ubuntu2.16.04.2_amd64.deb
etcd
etcd_3.2.24
etcdctl
kubeadm_1.13.1-00_amd64.deb
kube-apiserver_v1.13.1
kube-controller-manager_v1.13.1
kubectl_1.13.1-00_amd64.deb
kubelet_1.13.1-00_amd64.deb
kube-proxy_v1.13.1
kubernetes-cni_0.6.0-00_amd64.deb
kube-scheduler_v1.13.1
pause_3.1
socat_1.7.3.1-1_amd64.deb
weaveworks_weave-kube_2.5.0
weaveworks_weave-npc_2.5.0
```

The `etcd_3.2.23` image is actually not needed as we will set up a etcd cluster manually. I'm using a higher version of ETCD for this experiment. This image is used by kubelet and kubeadm if you start a single master cluster. I put it here for reason of completeness.

### Copy files from a0 to master and worker nodes

Run scripts `a0-cp-bin-to-m.sh`, `a0-cp-to-m.sh`, `a0-cp-bin-to-w.sh`, `a0-cp-to-w.sh`. These scripts will copy the files needed for setting up master and workers nodes. Make sure you change the hostnames, IP address, diretories, etc, in the following scripts before running them. 

## Set up master nodes, m0, m1, m2

All of your master nodes should now have `_bin`, `_certs`, `_scripts`, `_yaml` directories under the home directory. You will need to SSH from a0 node to m0, m1, m2 in the following steps as the master nodes are not accessible directly from outside of your cluster.

### Install docker and load Kubernetes docker images

1. Install docker by running something like `sudo apt-get install docker.io`.
2. SSH from a0 to m0, m1, m2. On each master node run `m-load-kubeadm-images.sh`. This loads the docker images needed for `kubeadm` to bootstrap your cluster.
3. SSH from a0 to w0, w1, w2. On each worker node run `w-load-kubeadm-images.sh`. This loads the docker images needed for `kubeadm` to bootstrap your cluster.

### Install Kubernetes core binaries

1. SSH from a0 to m0, m1, m2, w0, w1, w2
2. On each node, install Kubernetes core binaries using `dpkg` comamnd with `*.deb` file under `~/_bin` directory
   ```
   cd _bin
   sudo dpkg -i \
     kubernetes-cni_0.6.0-00_amd64.deb \
     kubectl_1.13.1-00_amd64.deb \
     cri-tools_1.12.0-00_amd64.deb \
     socat_1.7.3.1-1_amd64.deb \
     ebtables_2.0.10.4-3.4ubuntu2.16.04.2_amd64.deb \
     kubelet_1.13.1-00_amd64.deb \
     kubeadm_1.13.1-00_amd64.deb
   ```

### Set up etcd cluster on master nodes

1. SSH from a0 to m0
2. Run the script `m0-gen-etcd.service.sh`. This creates a `etcd.service` systemctl unit file in your `_scripts/out` directory. Make sure you change the details in the script to suit your environment.
3. Run the script `m-pre-etcd.sh`. This starts the etcd cluster on m0.
4. Repeat the above for m1 and m2. Note that you should use `m1-gen-etcd.service.sh` and `m2-gen-etcd.service.sh` on m1 and m2 nodes.

Now SSH to any of the master nodes, run the script `m-chk-etcd.sh`, you should see something like:

```
4f1559e54113e015, started, m2, https://someip:2380, https://someip:2379
68891416ccd28cf2, started, m1, https://someip:2380, https://someip:2379
e2c4af89fb70ae0b, started, m0, https://someip:2380, https://someip:2379
```

This shows your etcd cluster is up running. 

### Boot strap the first master node m0

1. SSH from a0 to m0
2. Run the script `m-gen-kubeadm-config.sh`. This generates a `kubeadm-config.yaml` under your `~/_yaml` directory. 
3. Run this command to bootstrap first master node. The `--ignore-preflight-errors=NumCPU` flag will make `kubeadm` to ignore that fact that our low spec instance has only 1 CPU. Without the flag, `kubeadm` preflight check will fail.
   ```
   sudo kubeadm init --config=_yaml/kubeadm-config.yaml --ignore-preflight-errors=NumCPU
   ```
4. Run the scripts `m0-cp-kube-certs-to-m1-m2.sh`. This copes the certificates generated by `kubeadm` on m0 to m1 and m2. This step is very important and makes sure the master nodes can talk to each other using the same certificates and CA.

### Install HAProxy on a0 to load balance master nodes

1. SSH to a0
2. `sudo apt-get install haproxy`
3. Config HAProxy's config file `sudo vi /etc/haproxy/haproxy.cfg`
   ```
   global
   ...
   default
   ...
    
   frontend kubernetes
   bind <a0 ip address>:6443
   option tcplog
   mode tcp
   default_backend kubernetes-master-nodes


   backend kubernetes-master-nodes
   mode tcp
   balance roundrobin
   option tcp-check
   server m0 <m0 ip address>:6443 check fall 3 rise 2
   server m1 <m1 ip address>:6443 check fall 3 rise 2
   server m2 <m2 ip address>:6443 check fall 3 rise 2
   ```
4. Restart HAProxy with `sudo systemctl restart haproxy`

### Bring up the rest of the masters nodes, m1 and m2

1. SSH from a0 to m1 and m2. You should see on each node's home directory there is a directory `~/pki`. This directory holds the certificates copied from m0.
2. On each master nodes, run the script `m-prep-kubeadm-init.sh`. Do *NOT* run this script on m0. This copies the certificates generated from m0 to the proper places on m1 and m2.
3. Run the same command to bootstrap master nodes on m1 and m2
   ```
   sudo kubeadm init --config=_yaml/kubeadm-config.yaml --ignore-preflight-errors=NumCPU
   ```
4. Make a copy of the `kubeadm join` line from the last `kubeadm` command output.

## Bring up worker nodes

1. SSH from a0 to w0, w1, w2
2. Run `sudo kubeadm join ...(from the last kubeadm output from master node)...`. This will join the worker node to the cluster. 

In case the `kubeadm join` line is lost, you can always make a new one by running the following command on one of the master nodes 
```
$ sudo kubeadm token generate
<generated token string>
$ sudo kubeadm token create <generated token string> --print-join-command
```

## Set up kubectl on a0 and your local machine

1. SSH from a0 to m0
2. `sudo cp -i /etc/kubernetes/admin.conf ~`. This copies the admin kubeconfig file to your home directory on m0
3. `kubectl --kubeconfig=~/admin.conf get nodes`. This should produce something like the following. It's normal that the nodes are in `NotReady` states because we have not installed the pod network driver.
   ```
   NAME   STATUS      ROLES    AGE   VERSION
   m0     NotReady    master   22h   v1.13.1
   m1     NotReady    master   22h   v1.13.1
   m2     NotReady    master   22h   v1.13.1
   w0     NotReady    <none>   22h   v1.13.1
   w1     NotReady    <none>   22h   v1.13.1
   w2     NotReady    <none>   21h   v1.13.1
   ``` 
4. Exit to a0 node and run 
   ```
   $ scp m0:~/admin.conf .
   $ kubectl --kubeconfig=~/admin.conf get nodes
   ```
   You should see the same node list output as above. This shows kubectl is working remotely on a0. 
5. Back to you local machine and do `scp user@a0:~/admin.conf .`. This copies the `admin.conf` from a0 (was originally from m0) to your local machine.
6. On your local machine, `vi admin.conf`, then find the `server: https://<m0 ip address>:6443` line and replace `<m0 ip address>` with a0's host@domain. 
7. On your local machine, `kubectl --kbueconfig=~/admin.conf get nodes` should also work. If you want to make in kubeconfig as your default, copy it to `~/.kube/` and rename it to `config`. 

## Bring up the Weave Net pod network

1. From k8s's git root of you local machine, `kubectl apply -f yaml/weave-net.yaml`. This will create the pod network. Wait for a few minutes, then `kubectl get nodes`, you should see something like:
   ```
   NAME   STATUS   ROLES    AGE   VERSION
   m0     Ready    master   22h   v1.13.1
   m1     Ready    master   22h   v1.13.1
   m2     Ready    master   22h   v1.13.1
   w0     Ready    <none>   22h   v1.13.1
   w1     Ready    <none>   22h   v1.13.1
   w2     Ready    <none>   21h   v1.13.1
   ```

Congratulations, you've had yourself a running Kubernetes cluster with 3 master nodes and 3 worker nodes. 

# Install Helm

Helm is a package manager for Kubenetes applications. It is installed on your local machine and it will also install its agent `tiller` on your cluster

## Install on Mac

1. Install with `brew install kubernetes-helm`
2. Run `helm init`. Up to this point, tiller will be deployed, but will fail at container creation because it cannot get the image
3. Prepare tiller image `gcr.io/kubernetes-helm/tiller:v2.12.1`. Use the same technique we used for our cluster: 
   1. connect to VPN 
   2. use docker pull, then docker save
   3. scp to all the woker nodes,
   4. docker load
4. Run `scripts/__helm-init-sa.sh`. This creates the service account and binds it to the cluster-admin cluster role for `tiller`. Otherwise `tiller` cannot install  charts on the cluster

You also need VPN to download the charts from the official `stable` repo. Use `helm fetch` to get what you need into local directory. Then use `helm install ./<your_chart_file_name>`

# Install and get Metallb up running

## Install Metallb

In our experiment, we didn't provision any Aliyun load balancer because (1) cost saving (2) Kubernetes does not yet support Alyyun cloud apparatus as does AWS or GCP. Our cluster is essentially running on bare metal. Without native cloud load balancer support, we can only expose services via node port. This way we are not allowed to use privilleged ports such as http (80) or https (443). Metallb solves this problem by offering a pure software load balancer that does not rely on any cloud infrastruture. 

To install Metallb using `helm` is very easy: `helm install stable/metallb`. But we have to do this in a more complicated way because of the GFW. 
```
# Get on VPN
helm fetch stable/metallb
helm install ./metallb
```

## Create a ConfigMap for Metallb

This will install Metallb into the default namespace. But Metallb will not do anything until we create a ConfigMap for it, like in the `metalllb.yaml`:
```
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: default
  name: metallb-config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.17.94.121/32
      - 172.17.197.158/32
      - 172.17.94.122/32
```

Here we expose all three woker nodes' Aliyun internal IPs. Recall that workers nodes all have public EIPs. Services exposed on these internal IPs will be accessible from outside Aliyun.  

# Install nginx-ingress

## Install nginx-ingress with `helm`

Use `helm` to install nginx-ingress is very easy. But `helm` will also install a default back end whose image is hosted on Google server. You should know how to deal with this by now if you've been following this article.
```
# Connect to VPN
# docker pull image k8s.gcr.io/defaultbackend:1.4
# docker save k8s.gcr.io/defaultbackend:1.4 > defaultbackend_1.4
# scp defaultbackend_1.4 user@a0:~/k8s/bin
# scp defaultbacnekd_1.4 user@workerhost:~/_bin
# sudo docker load < defaultbackend_1.4>
helm fetch stable/nginx-ingress
# Disconnect VPN
helm install ./nginx-ingress-1.0.1.tgz --set rbac.create=true
```

## Verify nginx-ingress installation

Use `kubectl get pods` you should see something like:
```
NAME                                                              READY   STATUS    RESTARTS   AGE
belligerent-rabbit-nginx-ingress-controller-56b5d67859-4tz5l      1/1     Running   0          9m37s
belligerent-rabbit-nginx-ingress-default-backend-6c47644b585bmz   1/1     Running   0          9m37s
terrifying-dog-metallb-controller-74b9bd949-w2726                 1/1     Running   0          10h
terrifying-dog-metallb-speaker-kfttw                              1/1     Running   0          10h
terrifying-dog-metallb-speaker-v5hxq                              1/1     Running   0          10h
terrifying-dog-metallb-speaker-vlm4r                              1/1     Running   0          10h
```

If you see the defaultbackend pod shows status `ImagePullBackOff`, it means that worker node cannot pull the default backend image. After you have loaded the image, the pod will automatically resume and enter into running state.

Now go to your Aliyun web console and verify if you have your 80 port open in the security group hosting your worker nodes. You need to figure out what is the public ip address to connect to the default backend. But first let's look at how the traffic will flow:
```
Internet --> worker public up --> worker internal ip --> metallb --> nginx-ingress --> defaultbackend
```

Recall that we have
- 3 public IPs, one on each of the worker nodes
- Assigned 3 internal IPs from the same set of worker nodes to Metallb

Therefore Metallb must have allocated one of the 3 internal IPs (meaning which worker node) to `nginx-ingress`. To find out, use `kubectl get svc -o wide`. The IP address listed under the EXTERNAL-IP column is the internal IP used. Find the corresponding public IP and you find the IP address you'll use to access the default backend. This IP address is also the one you want to bind your domain name to. 

Finally, fire up your browser and go to `http://<worker public up>`, you should see a simple line that says:
```
default backend - 404
``` 

## Run a simple node js website

We will now install a simple web app using an example from the book Kubernetes for Developers. I have forked the original code in order to make some changes for my experiment.

1. Get the code from github
   ```
   git clone https://githubcom/yhuangsh/kfd-nodejs
   cd kfd-nodejs
   git checkout first_container_branch
   ```
2. Build the docker image for this simple application `docker build -t your_repository/kfd-node:version`. This creates a docker image that runs a particular version of the web app under the "first_container_branch". Don't miss the dot in the command
3. You must push your image to an image registry for your cluser to pull and use. Aliyun offers free Kubernetes docker image registry. There are several registry addresses roughly matching Aliyun's regions. For example, `registry.cn-beijing.aliyuncs.com`.  In our example, I used `docker push yhuangsh/kfd-nodejs:v1` to push the image to my own image repository hosted on docker public registry. You may use this image directly.
4. Run the web app on your Kubernetes cluster by `kubectl run nodejs --image=yhuangsh/kfd-nodejs:v1 --port=3000`. This starts a new pod with the `kfd-nodejs:v1` image we just created and a deployment named `nodejs`. The `port` is passed to the pod via environment variable so that the nodejs web server will listen on port 3000 rather than the normal 80 port. The port number doesn't matter since this port is inside the a docker container. 
5. The pod is inaccessible from outside its docker container until exposed by `kubectl expose deploy/nodejs`. This exposes the web app to the cluster network, still inaccessible from outside world. Use `kubectl get svc` and something like the following will show up, among other things. 
   ```
   NAME                         TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)
   nodejs                       ClusterIP      10.111.230.152   <none>          3000/TCP
   ```
   Another way to interact with this web app is through `kubectl port-forward <you nodejs pod name> --port=<your localhost port>:3000`. This is useful for development, but not for a production system.
6. In order for the nodejs web app to be available publicly, the last step is to tell `nginx-ingress` controller how to route HTTP requests. Use the command `kbuectl create -f yaml/ingress.yaml`. This maps incoming traffic to the host `www.davidhuang.top` to the nodejs web app. You sure wants to use your own domain name. I also changed the original `kfd-nodejs` code so that the web app is available under `http://www.davidhuang.top/nodejs` and `http://www.davidhuang.top/nodejs/users`. This demostrates that `nginx-ingress` controller can dispatch traffic based on path as well as host's DNS names.

Congratulations, you have your first web site on Kubernetes cluster running.

***Domain name and http (80) port in China***. It's easy to open 80/433 ports on Aliyun. But the port is not really open until you register as an ICP (Internet Content Provider) with the authority. This takes a few days and requires uploading your personal information and the domain names that you own. Otherwise, any traffic to 80 will be hijacked by Aliyun leading to a page prompting you to register. You may think you get around by using a non-standard http port. That works until the moment you wants to set up TLS for your website with free certificates from Let's Encrypt. We get to that in the next experiment.

# Install cert-manager 

## Install cert-manager via `helm`

Use `helm install ./cert-manager-v0.5.2.tgz --name cert-manager` to install. Note that we install `cert-manager` to the default namespace rather than the `kube-system` namespace as the official guide instructed.

## Set up the Issuer resource

First, customize the `letsencrypt-staging-issuer.yaml` and use `kubectl create -f yaml/letsencrypt-staging-issuer.yaml` to create the issuer using Let's Encrypt's ACME staging server. 

Important things to note:
1. Always use the staging server first as there is limit on how much and how frequent you can retry a certificate request if the previous one fails. You don't want have too many failures in a short period of time with the production ACME.
2. Use `http01` as the domain verification method. Let's Encrypt does not support Aliyun, so `dns01` method won't work.
3. In case you haven't finished the previous section and jumped here. You should know that you must finish your ICP registration before starting `http01` verification because `http01` uses 80 port to talk to a `cert-manager` web server to complete the verification process. 

After the `kubectl create` command, use `kubectl describe issuer` to check the progress of issuer registration with Let's Encrypt's ACME server. If an ACME account is successfully registered, you should see something like:
```
[More ouput]
Status:
  Acme:
    Uri:  https://acme-staging-v02.api.letsencrypt.org/acme/acct/7666981
  Conditions:
    Last Transition Time:  2018-12-24T03:30:56Z
    Message:               The ACME account was registered with the ACME server
    Reason:                ACMEAccountRegistered
    Status:                True
    Type:                  Ready
Events:                    <none>
```
This means you are ready to take the next step. 

## Domain verification and certificate issuing

Use `kubectl create -f yaml/letsencrypt-staging-certificate.yaml` to create a certificate. This triggers `cert-manager` to 
1. start the `http01` verification for each CN and DNS name you are requesting a certificate for 
2. request ACME to issue certificates for thse CN and DNS names

Note that `cert-manager` will complete `http01` verifications of all CN and DNS names you requested before requesting any certificate. If one of your CN or DNS name cannot be verified, no certificate will be issued and `cert-manager` will retry after a time-out. This is why you should use the staging server first. 

Use `kubectl describe certificate/<certificate-name>` to track progress. The `<certificate-name>` is the `name:` you put in the `meta` block of the `letsencrypt-staging-certificate.yaml`. If successful, you should see something like:
```
[More output]
Events:
  Type    Reason          Age   From          Message
  ----    ------          ----  ----          -------
  Normal  CreateOrder     65s   cert-manager  Created new ACME order, attempting validation...
  Normal  DomainVerified  41s   cert-manager  Domain "www.davidhuang.top" verified with "http-01" validation
  Normal  DomainVerified  10s   cert-manager  Domain "dev.davidhuang.top" verified with "http-01" validation
```
Here you can see `www.davidhuang.top` and `dev.davidhuang.top` have been validated.

Now use `kubectl describe cert/<certificate-name>` to confirm if a certificate has been issued. A sample output of an issued certificate looks like this:
```
[More output]
Status:
  Acme:
    Order:
      URL:  https://acme-v02.api.letsencrypt.org/acme/order/48273452/236826555
  Conditions:
    Last Transition Time:  2018-12-24T06:58:23Z
    Message:               Certificate issued successfully
    Reason:                CertIssued
    Status:                True
    Type:                  Ready
```

## Find what you need to set up a TLS connection

Use `kubectl get secret` to find out the secret you need for setting up your TLS connection. Here's an example.
```
NAME                                            TYPE                                  DATA   AGE
belligerent-rabbit-nginx-ingress-token-n5wn6    kubernetes.io/service-account-token   3      36h
cert-manager-token-k872m                        kubernetes.io/service-account-token   3      11h
davidhuang-top-prod-tls                         kubernetes.io/tls                     2      7h33m
default-token-8hfn4                             kubernetes.io/service-account-token   3      2d23h
letsencrypt-prod                                Opaque                                1      7h37m
letsencrypt-staging                             Opaque                                1      11h
terrifying-dog-metallb-controller-token-662qx   kubernetes.io/service-account-token   3      46h
terrifying-dog-metallb-speaker-token-k2zn8      kubernetes.io/service-account-token   3      46h
```

The third line with `davidhuang-top-prod-tls` is the one we are looking for. In fact, this is the `secretName` you specified in your certificate yaml file. 

Note that `cert-manager` also created `letsencrypt-prod` and `letsencrypt-staging` of type `Opaque` for the issuers. We don't care about that, but make sure you are not confused. 

# Secure our web app with TLS

Use `kubectl delete ingress/davidhuang-top-ingress` since we will set up the TLS-enabled ingress with the same name. Use `kubectl create -f yaml/ingress-tls.yaml`.

Now go to your browser and refresh. You should see the same web site, but your browser should show a lock sign somewhere near your URL. `nginx-ingress` by default will redirect HTTP request to HTTPS if a domain names appears under the `tls` section. 

# Credits

This project was inspired and has used ideas and methods from the following articles and website:

- [UTSC Mirror](https://ieevee.com/tech/2017/09/17/k8s-yum-mirror.html)
- [Multi-master with Kubeadm](https://blog.inkubate.io/install-and-configure-a-multi-master-kubernetes-cluster-with-kubeadm/)
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [Weave Net FAQ](https://www.weave.works/docs/net/latest/faq/)
