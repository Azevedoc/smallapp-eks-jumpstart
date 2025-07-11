# EKS Auto Mode Deployment Guide: Voting App Tutorial

## 🎯 **Overview**

This guide walks you through deploying a real-world microservices application (Docker's Example Voting App) on AWS EKS Auto Mode. Perfect for DevOps interviews, learning Kubernetes, or demonstrating cloud-native deployments.

### **What You'll Build**
- **5 Microservices**: Vote (Python), Result (Node.js), Worker (.NET), Redis, PostgreSQL
- **EKS Auto Mode Cluster**: Latest Kubernetes 1.33 with Karpenter auto-scaling
- **Production Setup**: LoadBalancer services, container registry, external access
- **Time Required**: ~45-60 minutes

### **Architecture**
```
Internet → AWS LoadBalancer → Vote/Result Services
                ↓
         Kubernetes Cluster (Auto Mode)
                ↓
    Redis ← Worker → PostgreSQL
```

---

## 📋 **Prerequisites**

Before starting, ensure you have:

- [x] **AWS CLI** configured with Full Admin credentials
- [x] **kubectl** installed and working
- [x] **eksctl** installed 
- [x] **Docker Desktop** running
- [x] **Helm** installed
- [x] **Git** configured
- [x] **Example Voting App** cloned locally

### **Quick Verification**
```bash
# Verify all tools are working
aws sts get-caller-identity
kubectl version --client
eksctl version
docker --version
helm version

# Clone the voting app repository
git clone https://github.com/Azevedoc/example-voting-app.git
```

---

## 🚀 **Step 1: Create EKS Auto Mode Cluster**

### **1.1 Create Cluster via AWS Console**

**Why Auto Mode?** Latest AWS feature with automatic node management, Karpenter auto-scaling, and Bottlerocket OS.

**Console Steps**:
1. Navigate to **AWS Console → EKS**
2. Click **"Create cluster"**
3. **Choose Auto Mode** (new feature)
4. **Cluster Configuration**:
   - Name: `happy-dance-badger` (or your preferred name)
   - Region: `us-east-1`
   - Kubernetes version: `1.33` (latest)
   - Auto Mode: **Enabled**
5. **Access Configuration**: Keep defaults
6. **Review and Create**

**Duration**: 8-12 minutes

### **1.2 Configure kubectl Access**

```bash
# Update kubeconfig to connect to your cluster
aws eks update-kubeconfig --region us-east-1 --name happy-dance-badger

# Verify connection
kubectl get nodes
```

### **1.3 Fix Authentication (If Needed)**

EKS Auto Mode uses API authentication. If you get credential errors:

```bash
# Add your IAM user to cluster access entries
aws eks create-access-entry \
  --cluster-name happy-dance-badger \
  --principal-arn arn:aws:iam::<your-account-id>:user/<your-username> \
  --region us-east-1

# Associate admin policy
aws eks associate-access-policy \
  --cluster-name happy-dance-badger \
  --principal-arn arn:aws:iam::<your-account-id>:user/<your-username> \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster \
  --region us-east-1
```

### **1.4 Verify Auto Mode Features**

```bash
# Check cluster info
kubectl cluster-info

# View Auto Mode managed resources
kubectl get pods -n kube-system
kubectl get nodes -o wide

# You should see Karpenter-managed nodes with Bottlerocket OS
kubectl describe nodes
```

---

## 🐳 **Step 2: Set Up Container Registry**

### **2.1 Create ECR Repositories**

```bash
# Set environment variables
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Create repositories for each service
aws ecr create-repository --repository-name vote --region $AWS_REGION
aws ecr create-repository --repository-name result --region $AWS_REGION
aws ecr create-repository --repository-name worker --region $AWS_REGION

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
```

### **2.2 Build and Push Images**

```bash
# Navigate to the cloned repository
cd example-voting-app

# Build images from the GitHub repository
docker build -t vote:latest ./vote
docker build -t result:latest ./result
docker build -t worker:latest ./worker

# Tag for ECR
docker tag vote:latest $ECR_REGISTRY/vote:latest
docker tag result:latest $ECR_REGISTRY/result:latest
docker tag worker:latest $ECR_REGISTRY/worker:latest

# Push to ECR
docker push $ECR_REGISTRY/vote:latest
docker push $ECR_REGISTRY/result:latest
docker push $ECR_REGISTRY/worker:latest
```

### **2.3 Verify Images**

```bash
# List repositories
aws ecr describe-repositories --region $AWS_REGION

# Check images
aws ecr describe-images --repository-name vote --region $AWS_REGION
```

---

## ☸️ **Step 3: Deploy Application**

### **3.1 Create Namespace**

```bash
# Create dedicated namespace for the app
kubectl create namespace voting-app
```

### **3.2 Kubernetes Manifests Ready**

**✅ Pre-configured manifests** available in multiple ways:

**Option A: Local manifests** (in your project directory `k8s-specifications/`):
All manifests have been updated with:

**Option B: Direct from GitHub** (if you prefer to use manifests directly from repository):
```bash
# Apply manifests directly from GitHub (alternative approach)
kubectl apply -f https://raw.githubusercontent.com/Azevedoc/example-voting-app/refs/heads/main/k8s-specifications/redis-deployment.yaml -n voting-app
kubectl apply -f https://raw.githubusercontent.com/Azevedoc/example-voting-app/refs/heads/main/k8s-specifications/redis-service.yaml -n voting-app
# ... and so on for each manifest
```

**Current local manifests include:**

**Image References:**
- **vote-deployment.yaml**: Uses `826001400561.dkr.ecr.us-east-1.amazonaws.com/vote:latest`
- **result-deployment.yaml**: Uses `826001400561.dkr.ecr.us-east-1.amazonaws.com/result:latest`
- **worker-deployment.yaml**: Uses `826001400561.dkr.ecr.us-east-1.amazonaws.com/worker:latest`

**Service Configurations:**
- **vote-service.yaml**: `LoadBalancer` type, port `80`
- **result-service.yaml**: `LoadBalancer` type, port `80`

**Data Layer (unchanged):**
- **redis-deployment.yaml** + **redis-service.yaml**: Redis cache
- **db-deployment.yaml** + **db-service.yaml**: PostgreSQL database

### **3.3 Deploy Data Layer**

```bash
# Deploy Redis
kubectl apply -f k8s-specifications/redis-deployment.yaml -n voting-app
kubectl apply -f k8s-specifications/redis-service.yaml -n voting-app

# Deploy PostgreSQL
kubectl apply -f k8s-specifications/db-deployment.yaml -n voting-app
kubectl apply -f k8s-specifications/db-service.yaml -n voting-app
```

### **3.4 Deploy Application Services**

```bash
# Deploy Worker (processes votes)
kubectl apply -f k8s-specifications/worker-deployment.yaml -n voting-app

# Deploy Vote service
kubectl apply -f k8s-specifications/vote-deployment.yaml -n voting-app
kubectl apply -f k8s-specifications/vote-service.yaml -n voting-app

# Deploy Result service
kubectl apply -f k8s-specifications/result-deployment.yaml -n voting-app
kubectl apply -f k8s-specifications/result-service.yaml -n voting-app
```

### **3.5 Verify Deployment**

```bash
# Check all pods are running
kubectl get pods -n voting-app

# Check services (wait for EXTERNAL-IP)
kubectl get services -n voting-app

# Check logs if needed
kubectl logs -l app=vote -n voting-app
kubectl logs -l app=result -n voting-app
kubectl logs -l app=worker -n voting-app
```

---

## 🌐 **Step 4: Access Your Application**

### **4.1 Get External URLs**

```bash
# Get service external IPs
kubectl get services -n voting-app

# You'll see LoadBalancer services with external IPs like:
# vote     LoadBalancer   a1234567890.us-east-1.elb.amazonaws.com   80:31000/TCP
# result   LoadBalancer   a0987654321.us-east-1.elb.amazonaws.com   80:31001/TCP
```

### **4.2 Test the Application**

1. **Vote**: Open `http://<vote-external-ip>` in your browser
2. **Cast votes**: Choose between Cats and Dogs
3. **Results**: Open `http://<result-external-ip>` in another tab
4. **Verify**: Votes should appear in real-time on the results page

---

## 🎯 **Step 5: Demonstrate Advanced Features**

### **5.1 Show Scaling**

```bash
# Scale the vote service
kubectl scale deployment vote -n voting-app --replicas=3

# Watch pods scale up
kubectl get pods -n voting-app -w

# Scale back down
kubectl scale deployment vote -n voting-app --replicas=1
```

### **5.2 Monitor Auto Mode**

```bash
# Check node status and resource usage
kubectl get nodes -o wide
kubectl top nodes

# Check pod distribution across nodes
kubectl get pods -n voting-app -o wide

# View Karpenter-managed system pods
kubectl get pods -n kube-system
```

### **5.3 Troubleshooting Commands**

```bash
# Check pod status
kubectl describe pod <pod-name> -n voting-app

# View pod logs
kubectl logs <pod-name> -n voting-app

# Check service endpoints
kubectl describe svc vote -n voting-app

# Port forward for local testing
kubectl port-forward svc/vote -n voting-app 8080:80
```

---

## 🧹 **Step 6: Cleanup**

### **6.1 Delete Application**

```bash
# Delete entire voting app (removes all pods, services, load balancers)
kubectl delete namespace voting-app

# Verify cleanup
kubectl get namespaces
```

### **6.2 Delete Container Images (Optional)**

```bash
# Delete ECR repositories
aws ecr delete-repository --repository-name vote --force --region us-east-1
aws ecr delete-repository --repository-name result --force --region us-east-1
aws ecr delete-repository --repository-name worker --force --region us-east-1
```

### **6.3 Delete EKS Cluster (Optional)**

**From AWS Console**:
- Navigate to EKS Console
- Select your cluster
- Click "Delete"

**From CLI**:
```bash
aws eks delete-cluster --name happy-dance-badger --region us-east-1
```

---

## 🎯 **Interview Talking Points**

### **Technical Architecture**
- **Microservices**: Vote → Redis → Worker → PostgreSQL → Result
- **Service Discovery**: Kubernetes DNS for internal communication
- **Load Balancing**: AWS ELB for external access
- **Container Orchestration**: Kubernetes managing all components

### **AWS Auto Mode Benefits**
- **Karpenter Auto-scaling**: Automatic node provisioning based on demand
- **Bottlerocket OS**: Security-hardened, minimal container OS
- **ARM64 Graviton**: Cost-effective, high-performance instances
- **Managed Operations**: Reduced operational overhead

### **Production Considerations**
- **Health Checks**: Liveness and readiness probes configured
- **Resource Management**: CPU/memory limits for efficient resource usage
- **Security**: Network policies and RBAC for access control
- **Monitoring**: CloudWatch integration for observability
- **Service Mesh**: Ready for Istio integration if needed

### **DevOps Best Practices Demonstrated**
- **Infrastructure as Code**: Pre-configured Kubernetes manifests in version control
- **Container Registry**: Private ECR repositories with custom images
- **Configuration Management**: Environment-specific image references and service types
- **Deployment Strategy**: Systematic data layer then application layer deployment
- **Version Control**: All deployment configurations tracked in Git
- **Validation**: Comprehensive testing and verification steps

---

## 📚 **Additional Resources**

- [AWS EKS Auto Mode Documentation](https://docs.aws.amazon.com/eks/latest/userguide/eks-auto-mode.html)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Docker Voting App Repository (Your Fork)](https://github.com/Azevedoc/example-voting-app)
- [Original Docker Voting App](https://github.com/dockersamples/example-voting-app)
- [Karpenter Documentation](https://karpenter.sh/)

---