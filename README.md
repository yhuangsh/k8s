# Kubernetes Experiments on Alibaba Cloud

This project uses a serious of scripts to setup a 3-master, 3-worker Kubernetes cluster on Alibaba's Aliyun Cloud using 7 standard Aliyun ECS machines. 

## ECS resources used are:

- a0 node, bridge and working node for settting up the cluster master and worker nodes and also act as soft load balancer and reverse proxy to Kubernetes API servers running on the master
- m0, m1, m2 nodes, master nodes running the cluster's control plane 
- w0, w1, w2 nodes, wokers nodes running the application pods

- a0, w0, w1, w2 are provisioned with public IPs (EIP or fixed), so they have internet access
- m0, m1 m2 are provisioned with cloud internal IPs only

- a0 is provisioned with 1 CPU, 0.5 GiB, (ecs.t5-lc2m1.nano)
- m0, m1, m2, w0, w1, w2 are provisioned with 1 CPU, 1 GiB RAM (ecs.t5-lc1m1.small)

- Make sure all the VMs are in one security group
- Mare sure the following ports are open within your clusters. Aliyun default only opens port 22, 80 and 433
  - TCP port 6443, this is for the Kubernetes API server
  - TCP port 6873 and UDP ports 6873/6874, these are for Weave Net pod network drivers

- All nodes are provisioned with default/minimal settings for other resources (I/O, bandwidth, disk, etc.)
- All nodes are running Ubuntu 16.04 LTS (Xenial)
- All nodes must be in one region, but can spread across difference availability zones. This experiment puts master nodes on 3 different availablility zones

This is the probably the cheapest possible configuration for this experiment. If you use these resources plus 4 public IPs, it'll cost you about 100 RMB for 1 week, about 3000 RMB for a year. As a comparison, if you use Aliyun's managed Kubernetes cluster with the same 3-master-3-worker setup with lowest possible configuration ecs.n1.medium (2 CPU, 4 GiB), it'll cost you about 2000 RMB per node a year, that's 12,000 RMB a year just for the VMs. Of course, how much workload can a 3000-RMB cluster take remains to be seen and will be covered by future experiments. My guts feeling is this is a good base and with Kubernetes you will be able to horizontally scale your cluster little by little

I've tested that master nodes won't run in a 0.5 GiB configuration. Whether worker nodes can is something you can try. 

Besides, your local machine will be used in the set up process and when the setup is done your local machine will be set up to do kubectl to administrate the cluster remotely. Because this experiment uses bash scripts a Mac or Linux machine is recommended.

## Preparation on local machine

The setup process uses a serious of bash scripts. Scripts starting with 
- `_` are the ones run on your local machine
- `a0` are the ones run on your a0 node
- `m-` are the ones run on each of your master nodes
- `m0-`, `m1-`, `m-2` are the ones run on designated master nodes
- `w-` are the ones run on each of you worker nodes 

In order to run the scripts, just do `git clone https://github.com/yhuangsh/k8s && cd k8s`. The scripts are supposed to run from `k8s`'s git root. The paths in the following sections are all relative to this git root unless otherwise specified.

### Install tools that run on your local machine

Tools you need to install and run on your local machine are:
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

All of your master nodes should now have `_bin`, `_certs`, `_scripts`, `_yaml` directories under the home directory

### Set up m0

SSH from a0 to m0. 

Run the script `m0-gen-etcd.service.sh`. This creates a `etcd.service` systemctl unit file in your `_scripts/out` directory. 

# Now set up worker node, ssh to a new node you intend to use as worker

# Same as on the master node
# Install Kubernetes core binaries and dependencies
sudo apt-get install docker.io
sudo dpkg -i kubernetes-cni_0.6.0-00_amd64.deb
sudo dpkg -i kubectl_1.12.3-00_amd64.deb
sudo dpkg -i cri-tools_1.12.0-00_amd64.deb
sudo dpkg -i socat_1.7.3.1-1_amd64.deb 
sudo apt-get install ebtables                     # MUST be installed after cri-tools and socat
sudo dpkg -i kubelet_1.12.3-00_amd64.deb
sudo dpkg -i kubeadm_1.12.3-00_amd64.deb

# A subset of images are needed 
# Load docker images needed for kubeadm init
# You could run load_worker_images.sh
sudo docker load < k8s.gcr.io_kube-proxy_3.1
sudo docker load < k8s.gcr.io_pause_3.1
sudo docker load < weaveworks_weave-kube_2.5.0
sudo docker load < weaveworks_weave-npc_2.5.0

sudo kubeadm join ... # The same output from master node's kubeadm init command

# set up config to run kubectl on node1. This is just used once to get the pod_networking running
mkdir -p $HOME/.kube
scp <master node>:/home/someuser/.kube/config ~/.kube
kubectl apply -f weaveworks.yaml

# Check from the master node if the worker node has jointed
kubectl get nodes

# Now access your Kubernetes cluster on the cloud from your laptop
# From your local machine
scp <master node>:/home/someuser/.kube/config kubeconfig.master
kubectl <any command and parameter> --kubeconfig=kubeconfig.master

Install and Setup Helm

Install on Mac following official instructions worked

curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
$ chmod 700 get_helm.sh
$ ./get_helm.sh
helm init

Up to this point, tiller will be deploed, but will fail at container creation because it cannot get the image

gcr.io/kubernetes-helm/tiller:v2.11.0

So use the same technique:
 - find a VPN access 
 - use docker pull, then docker save
 - scp to your host, then docker load

You also need VPN to download the charts from the official stable/ repo. Use Helm fetch to get what you need
into local directory. Then use helm install ./your_chart_file_name

Now set up the service account and clusterrole for tiller, or it cannot install the charts on the cluster

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

Install nginx-ingress

Use Helm to install
** Note ** after installation use kubectl edit to change the ingress controller type to NodePort and config the exposed
http and https ports to 30080 and 30443 respectively

Install Certbot 

Go to Let's Encrypt and follow instruction on installing Cerbot and use cerbot certonly
port 80 needs to be open for http01 verification to go through

sudo certbot certonly --standalone -d davidhuang.top -d jenkins.davidhuang.top
Once done, kc create secret tls <name> --key privkey.pem --cert fullchain.pem

Install Kong

Enable local storage volume in Kubernetes, if you are just using the VMs on Alibaba Cloud (same as bare-metal)

apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
 capacity:
   storage: 15Gi
 accessModes:
 - ReadWriteOnce
 persistentVolumeReclaimPolicy: Retain
 storageClassName: local-storage
 local:
   path: /mnt/k8s/local-vol1
 nodeAffinity:
   required:
     nodeSelectorTerms:
     - matchExpressions:
       - key: kubernetes.io/hostname
         operator: In
         values:
         - node1.davidhuang.top
         - node2.davidhuang.top

The default helm values for Kong will has a PersistentVolumeClaim in its Postgress image that cannot claim local 
storage. The kong-postgress container will stuck in pending state. Fix it by 

kubectl get pvc/<the default persistent volume claim for kong> -o yaml > kong-pvc.yaml

Edit the yaml file to look like this. The key change is adding a storageClassName in the volume spec for the local
storage we just added

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  annotations:
    helm.sh/resource-policy: ""
  creationTimestamp: 2018-12-08T06:29:04Z
  finalizers:
  - kubernetes.io/pvc-protection
  labels:
    app: postgresql
    chart: postgresql-0.18.0
    heritage: Tiller
    release: vocal-poodle
  name: vocal-poodle-postgresql
  namespace: default
  resourceVersion: "1102579"
  selfLink: /api/v1/namespaces/default/persistentvolumeclaims/vocal-poodle-postgresql
  uid: 8ed6513c-fab2-11e8-9992-00163e0c4a4a
spec:
  storageClassName: local-storage
  accessModes:
  - ReadWriteOnce
  dataSource: null
  resources:
    requests:
      storage: 8Gi



use helm install

## Install nginx-ingress controll

The default helm nginx-ingress chart will install the ingress controller using LoadBalancer. It does not work for 
our 3-node cluster as we don't have driver for Alibaba cloud's load balancer. 

We need to install as a node port service type.

```
helm install stable/nginx-ingress \
  --name dvd \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443
```

Use `kubectl get svc` to verify nginx-ingress is up and running. You should see output similar to the following

```
NAME                                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
dvd-nginx-ingress-controller        NodePort    10.97.109.150    <none>        80:30080/TCP,443:30443/TCP   17s
dvd-nginx-ingress-default-backend   ClusterIP   10.99.0.51       <none>        80/TCP                       17s
```

You should use your release name to replace `dvd` and your own ports to replace `30080` and `30443`, although I
found these are pretty good, given you cannot expose port `80` and `443` when ingress is configured to use node 
port.



