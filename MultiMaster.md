### Install ```kubeadm``` and prepare its images

1. Set up apt mirror that's not blocked by GFW and install ```kubeadm```

```
sudo echo 'deb http://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list
apt-get update
sudo apt-get install kubeadm
```

2. Download and upload the images that will be pulled by ```kubeadm```

Use the following to see the images kubeadm will pull. We have to pull them with
a VPN connection as the original k8s.gcr.io site is blocked. There is an example
shell script for this job in the ```scripts``` directory.

``` 
~$ kubeadm config images list
k8s.gcr.io/kube-apiserver:v1.13.0
k8s.gcr.io/kube-controller-manager:v1.13.0
k8s.gcr.io/kube-scheduler:v1.13.0
k8s.gcr.io/kube-proxy:v1.13.0
k8s.gcr.io/pause:3.1
k8s.gcr.io/etcd:3.2.24
k8s.gcr.io/coredns:1.2.6
```

If you use WeaveNet as your pod network controller, you can download the following
two images as well. They are hosted on docker hub, so are not blocked. You may leave
this to ```kubeadm init```.

You need a locally installed docker to pull these images with an active VPN tunnel.
Once it's pulled, dump each image to a file using

```
docker image save > $imageX_name
```

Create a zipped tarball of all the images to be uploaded. The compressed tarball will 
save your uploading time. SCP the tarball you just created to your cloud host that 
will soon become your "master0" node. 

```
tar cfz k8s-images <image1_name> <image2_name> 
scp k8s-images <user@yourhost:/home/user>
```

Then on the receiving host, recover the images by

```
tar xfz k8s-images
docker image load < $imageX_name
```

### Install and prepare etcd cluster

1. Use cfssl to generate certificates

Find a suitable cfssl release at https://pkg.cfssl.org, install to your local machine. 
We will generate certificates on our local machines then copy to the VMs on Alibaba cloud.

User the following command to generate the certificates under the ```certs``` directoty. 
The certificates and private keys will be save in ```certs/out```

```
# Generate the self-signed CA certificate. 
# It will be used to sign/verify all other certificates
cfssl gencert \
  -initca \
  ca-csr.json | cfssljson -bare out/ca

# Generate the admin client certificate. This certificate will be used by the kubectl 
# from your local machine to access kube-apiserver on your Alibaba cloud VMs
cfssl gencert \
  -ca=out/ca.pem 
  -ca-key=out/ca-key.pem \
  -config=ca-config.json \
  admin-csr.json | cfssljson -bare out/admin

# Generate certificates for each worker node VMs. You need to know the cloud internal IP 
# address of these nodes
cfssl gencert \
  -ca=out/ca.pem \
  -ca-key=out/ca-key.pem \
  -config=ca-config.json \
  w0-csr.json | cfssljson -bare out/w0

# Generate client certificate for Kube Controller Manager. It is used by the controller manager to 
# access other kube-* servers
cfssl gencert \
  -ca=out/ca.pem \
  -ca-key=out/ca-key.pem \
  -config=ca-config.json \
  kube-ctrl-mgr-csr.json | cfssljson -bare out/kube-ctrl-mgr

# Generate client certificate for Kube Proxy. It is used by kube-proxy to access other kube-* servers
cfssl gencert \
  -ca=out/ca.pem \
  -ca-key=out/ca-key.pem \
  -config=ca-config.json \
  kube-proxy-csr.json | cfssljson -bare out/kube-proxy

# Generate client certificate for Kube Scheduler. It is used by the scheduler to access other kube-* 
# servers
cfssl gencert \
  -ca=out/ca.pem \
  -ca-key=out/ca-key.pem \
  -config=ca-config.json \
  kube-scheduler-csr.json | cfssljson -bare out/kube-scheduler

# Generate server certificate for Kube API Server. This certificate will be verified by connecting 
# kube-* clients
cfssl gencert \
  -ca=out/ca.pem \
  -ca-key=out/ca-key.pem \
  -config=ca-config.json \
  kube-apiserver-csr.json | cfssljson -bare out/kube-apiserver

# Generate service account 
cfssl gencert \
  -ca=out/ca.pem \
  -ca-key=out/ca-key.pem \
  -config=ca-config.json \
  service-account-csr.json | cfssljson -bare out/service-account
```




