# Kubernetes Experiments on Alibaba Cloud

1. Setup 3-node cluster on Alibaba's cloud

   1. What's needed
   2. How to get images that are blocked by GFW
   3. Step by step guide
   
2. Install and use Helm
3. Install Kong Ingress Controller/API Gateway
4. Install a small nodejs application
5. Secure nodejs application with TLS and certificates

## Setup 3-node cluster on Alibaba's cloud

This is a step by step guide of setting up a 3-node Kubernetes cluster on Alibaba Cloud.

Bill of Materials

- 3x ecs.t5.lc1m1.small nodes, 1x vCPU, 1 GiB RAM. This is cheapest VM you can buy on Alibaba Cloud
- Ubuntu 16.04 LTS, standard Ubuntu image when you create the node instances
- Kubernetes v1.12.2, most of the images from k8s.gcr.io
- Weave Net network drivers for Kubernetes cluster
- Docker 17.03.2-ce, comes with Alibaba Cloud's Ubuntu xenial distribution

The GFW Challenge

There are many guides on internet teaching you how to set up a single-master Kubernetes cluster. 
They are all good. But the challenge here is that Kubernetes's core binaries and its needed images
are hosted on Google's servers which are blocked by The Great Fire Wall. This guide is mostly about
working around the GFW while generally following the same method as many good guides have laid out. 

What's Blocked and Needed

Google's apt key hosted on: https://packages.cloud.google.com/apt/doc/apt-key.gpg

  We will not need it if you use the steps in this guide.

Kubernetes core binaries in deb packages hosted on: http://apt.kubernetes.io/

  cri-tools_1.12.0-00_amd64.deb               socat_1.7.3.1-1_amd64.deb
  kubelet_1.12.3-00_amd64.deb                 kubernetes-cni_0.6.0-00_amd64.deb
  kubeadm_1.12.3-00_amd64.deb                 kubectl_1.12.3-00_amd64.deb

Docker images that will be pulled when kubeadm or kubeelet starts. 
  
  k8s.gcr.io/coredns:1.2.2                    k8s.gcr.io/kube-scheduler:v1.12.3
  k8s.gcr.io/etcd:3.2.24                      k8s.gcr.io/pause:3.1
  k8s.gcr.io/kube-apiserver:v1.12.3           weaveworks/weave-kube:2.5.0
  k8s.gcr.io/kube-controller-manager:v1.12.3  weaveworks/weave-npc:2.5.0
  k8s.gcr.io/kube-proxy:3.1

WeaveWorks's YAML config file for setting up the pod_networks. This file is not blocked. Many 
existing guides uses a complex bash command to pull directly from WeaveWork's website passing
the Kubernetes version string on the localhost. With our specific guide, you could just use 
the one from this project. It was pulled and save the same way.

  weaveworks.yaml

Steps

Create an ECS instance and do basic setup. Among other things create a user that can sudo. 

Git clone this project, you will have all the .deb files and images in your local machine. Use 
scp to copy all .deb and image files to your node. 

You could also install git on your ECS instance and do git clone there. This should be faster
than scp, but your ECS instance is somewhat less pure. Choose either way to your liking.

Ssh into the node and do: sudo dpkg -i <each deb file>. When you use dpkg, the dependency
packages are not automatically installed. Just use the standard sudo apt-get install command
to installed the dependencies, then retry dpkg -i. 

# Make sure we have a up-to-date clean Ubuntu
sudo apt-get update
sudo apt-get upgrade
sudo apt-get autoremove
sudo reboot

# Install Kubernetes core binaries and dependencies
# You could run install_bin.sh 
sudo apt-get install docker.io
sudo dpkg -i kubernetes-cni_0.6.0-00_amd64.deb
sudo dpkg -i kubectl_1.12.3-00_amd64.deb
sudo dpkg -i cri-tools_1.12.0-00_amd64.deb
sudo dpkg -i socat_1.7.3.1-1_amd64.deb 
sudo apt-get install ebtables                     # MUST be installed after cri-tools and socat
sudo dpkg -i kubelet_1.12.3-00_amd64.deb
sudo dpkg -i kubeadm_1.12.3-00_amd64.deb

# Load docker images needed for kubeadm init
# You could run load_master_images.sh
sudo docker load < k8s.gcr.io_coredns_1.2.2
sudo docker load < k8s.gcr.io_etcd_3.2.24
sudo docker load < k8s.gcr.io_kube-apiserver_v1.12.3
sudo docker load < k8s.gcr.io_kube-controller-manager_v1.12.3
sudo docker load < k8s.gcr.io_kube-proxy_3.1
sudo docker load < k8s.gcr.io_kube-scheduler_v1.12.3
sudo docker load < k8s.gcr.io_pause_3.1
sudo docker load < weaveworks_weave-kube_2.5.0
sudo docker load < weaveworks_weave-npc_2.5.0

# Now start the node as Kubernetes master
sudo kubeadm init
# IMPORTANT: save the kubeadm join ... line into a file
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f weaveworks.yaml

# Check if the master is up running
kubectl get nodes


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


