# Kubernetes Cluster Setup with K3s

Scripts to set up a lightweight Kubernetes cluster using K3s with custom node labels.

## Overview

This setup uses **K3s** - a lightweight Kubernetes distribution perfect for edge, IoT, and homelab environments. It's production-ready, CNCF certified, and uses 50% less memory than standard Kubernetes.

## Quick Start

### 1. Setup Master Node (10.0.0.85)

On the master node (baremetal server):

```bash
# Set node name and labels
export NODE_NAME="baremetal"
export NODE_LABELS="purpose=baremetal,purpose=immich,type=server"

# Run master setup
sudo ./setup-k3s-master.sh
```

This will:
- Install K3s control plane
- Label the node with specified labels
- Generate a token for worker nodes
- Save the token to `k3s-token.txt`

### 2. Setup Worker Nodes

On each worker node (e.g., 10.0.0.131 - Raspberry Pi):

```bash
# Set configuration
export MASTER_IP="10.0.0.85"
export NODE_NAME="pi-node"
export NODE_LABELS="purpose=plex,purpose=pi,type=raspberrypi"
export NODE_TOKEN="<token-from-master>"

# Run worker setup
sudo ./setup-k3s-worker.sh
```

Or run interactively (will prompt for values):
```bash
sudo ./setup-k3s-worker.sh
```

## Example Node Configurations

### Node 1: Baremetal (10.0.0.85)
```bash
NODE_NAME="baremetal"
NODE_LABELS="purpose=baremetal,purpose=immich,type=server"
```

### Node 2: Raspberry Pi (10.0.0.131)
```bash
NODE_NAME="pi-plex"
NODE_LABELS="purpose=plex,purpose=pi,type=raspberrypi"
```

### Node 3: Another server
```bash
NODE_NAME="storage"
NODE_LABELS="purpose=storage,purpose=backup,type=server"
```

## Managing Node Labels

Use the label management script:

```bash
./manage-labels.sh
```

Options:
1. Add label to node
2. Remove label from node
3. Show node labels
4. List nodes by label

### Manual Label Management

```bash
# Add a label
k3s kubectl label node <node-name> purpose=new-purpose

# Remove a label
k3s kubectl label node <node-name> purpose-

# View node labels
k3s kubectl get nodes --show-labels

# Filter nodes by label
k3s kubectl get nodes -l purpose=plex
```

## Deploying Workloads with Node Selectors

### Example: Deploy to specific labeled nodes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: immich-pod
spec:
  nodeSelector:
    purpose: immich
  containers:
  - name: immich
    image: immich-server
```

### Example: Deploy to Plex nodes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: plex
spec:
  selector:
    matchLabels:
      app: plex
  template:
    metadata:
      labels:
        app: plex
    spec:
      nodeSelector:
        purpose: plex
      containers:
      - name: plex
        image: plexinc/pms-docker
```

## Useful Commands

### Cluster Management

```bash
# View all nodes
k3s kubectl get nodes -o wide

# View nodes with labels
k3s kubectl get nodes --show-labels

# Describe a specific node
k3s kubectl describe node <node-name>

# View all pods across namespaces
k3s kubectl get pods -A -o wide

# View cluster info
k3s kubectl cluster-info
```

### Node Filtering

```bash
# List nodes with specific purpose
k3s kubectl get nodes -l purpose=plex

# List nodes with multiple labels
k3s kubectl get nodes -l 'purpose in (plex,immich)'

# List server-type nodes
k3s kubectl get nodes -l type=server
```

### Troubleshooting

```bash
# Check K3s service status (master)
systemctl status k3s

# Check K3s agent status (worker)
systemctl status k3s-agent

# View K3s logs (master)
journalctl -u k3s -f

# View K3s agent logs (worker)
journalctl -u k3s-agent -f

# Check node readiness
k3s kubectl get nodes
k3s kubectl describe node <node-name>
```

## Uninstalling

### On Master Node

```bash
/usr/local/bin/k3s-uninstall.sh
```

### On Worker Nodes

```bash
/usr/local/bin/k3s-agent-uninstall.sh
```

## Port Requirements

### Master Node
- **6443** - Kubernetes API server
- **10250** - Kubelet metrics
- **2379-2380** - etcd (if using embedded etcd)

### All Nodes
- **10250** - Kubelet API
- **8472** - Flannel VXLAN (if using Flannel)
- **51820** - Flannel Wireguard (if using Wireguard backend)

Make sure these ports are open in your firewall.

## Files Created

- `k3s-token.txt` - Node token for joining workers (keep secure!)
- `/etc/rancher/k3s/` - K3s configuration
- `/var/lib/rancher/k3s/` - K3s data directory

## Advanced Usage

### Custom K3s Options

Edit the install commands in the scripts to add custom options:

```bash
# Disable Traefik ingress controller
curl -sfL https://get.k3s.io | sh -s - server --disable traefik

# Use different CNI
curl -sfL https://get.k3s.io | sh -s - server --flannel-backend=wireguard
```

### High Availability

For HA setup with multiple masters, see K3s documentation:
https://docs.k3s.io/installation/ha

## Security Considerations

- The node token in `k3s-token.txt` is sensitive - protect it
- K3s runs containers as root by default - consider using Pod Security Standards
- Enable network policies for pod-to-pod communication control
- Use RBAC for access control

## Next Steps

1. Install `kubectl` on your workstation for remote cluster management
2. Set up persistent storage (local-path-provisioner is included by default)
3. Deploy an ingress controller (Traefik is included, or use nginx-ingress)
4. Set up monitoring (Prometheus/Grafana)
5. Configure backups for cluster state

## Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Node Labels](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [K3s GitHub](https://github.com/k3s-io/k3s)
