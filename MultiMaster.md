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

Use the following command to generate the certificates under the ```certs``` directoty. 
The certificates and private keys will be save in ```certs/out```. Note that you must run the 
the commands in the parent directory of ```certs``` and ```scripts```

```
scripts/gen-certs.sh
scripts/gen-kubeconfig.sh
```

### Prepare etcd cluster

1. Install certificates

```
sudo mkdir -p /etc/etcd /var/lib/etcd





