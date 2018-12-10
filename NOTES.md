# Install Metallb

Metallb is a pure software load balancer that does not rely on any cloud infrastruture. 
If you are building a bare metal cluster or building a cluster on a public cloud using 
just VMs, you probably want to use Metallb.

To install Metallb using Helm is very easy, just use the following command:

```helm install --name $YOUR_RELEASE_NAME stable/metallb```

This will install Metallb into the default namespace. After installation Metallb will
not do anything until you create a ConfigMap for it, like the following

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
```

Here I only give Metallb one IP address that has internet access to start with. 