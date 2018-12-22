# Kubernetes Experiments on Alibaba Cloud

This project uses a series of scripts to setup a 3-master-3-worker Kubernetes cluster on Alibaba's Aliyun Cloud using 7 standard Aliyun ECS instances. 

## ECS resources used are:

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
   1 connect to VPN 
   2 use docker pull, then docker save
   3 scp to all the woker nodes,
   4 docker load
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

Use Helm to install

# Install Certbot 

Go to Let's Encrypt and follow instruction on installing Cerbot and use cerbot certonly
port 80 needs to be open for http01 verification to go through

sudo certbot certonly --standalone -d davidhuang.top -d jenkins.davidhuang.top
Once done, kc create secret tls <name> --key privkey.pem --cert fullchain.pem

use helm install


