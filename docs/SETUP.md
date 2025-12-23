# 초기 설정 가이드

이 가이드는 처음부터 EKS 클러스터와 GitOps 환경을 구축하는 상세한 단계를 제공합니다.

## 1. 사전 준비

### 필수 도구 설치

#### AWS CLI
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# AWS 자격 증명 설정
aws configure
```

#### Terraform
```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

#### kubectl
```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

#### Helm
```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

#### ArgoCD CLI
```bash
# macOS
brew install argocd

# Linux
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/
```

## 2. Terraform으로 EKS 클러스터 생성

### Step 1: 변수 설정

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` 편집:
```hcl
cluster_name = "my-eks-cluster"
aws_region   = "ap-northeast-2"

default_tags = {
  Terraform   = "true"
  Environment = "production"
  Team        = "platform"
}

# 노드 그룹 설정
node_group_desired_size  = 3
node_group_min_size      = 2
node_group_max_size      = 6
node_group_instance_types = ["t3.large"]

# 네트워크 설정
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]

# 보안 설정
cluster_endpoint_public_access_cidrs = ["YOUR_IP/32"]  # 본인 IP로 변경
```

### Step 2: Terraform 실행

```bash
# 초기화
terraform init

# Plan 확인
terraform plan

# 적용 (약 15-20분 소요)
terraform apply

# 출력 값 확인
terraform output
```

### Step 3: kubectl 설정

```bash
# kubeconfig 업데이트
aws eks update-kubeconfig --region ap-northeast-2 --name my-eks-cluster

# 클러스터 접속 확인
kubectl get nodes
kubectl get pods -A
```

## 3. 인프라 도구 설치

### 네임스페이스 생성
```bash
kubectl apply -f ../kubernetes/base/namespaces/
kubectl get namespaces
```

### ArgoCD 설치
```bash
# Kustomize로 설치
kubectl apply -k ../kubernetes/infrastructure/argocd/

# 설치 확인
kubectl get pods -n argocd

# 초기 관리자 비밀번호 확인
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Password: $ARGOCD_PASSWORD"

# 포트 포워딩으로 UI 접속
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 브라우저에서 https://localhost:8080 접속
# Username: admin
# Password: 위에서 확인한 비밀번호
```

### Ingress NGINX 설치
```bash
cd ../kubernetes/infrastructure/ingress-nginx
bash install.sh

# 설치 확인
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# LoadBalancer 주소 확인
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Cert-Manager 설치
```bash
cd ../cert-manager

# cluster-issuer.yaml에서 이메일 주소 변경
# email: your-email@example.com

bash install.sh

# 설치 확인
kubectl get pods -n cert-manager
kubectl get clusterissuer
```

### AWS Load Balancer Controller 설치
```bash
cd ../aws-load-balancer-controller

# values.yaml 확인 및 수정
# - clusterName
# - IAM role ARN

bash install.sh

# 설치 확인
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Prometheus + Grafana 설치
```bash
cd ../monitoring

# values.yaml에서 도메인과 비밀번호 변경
# - grafana.example.com → 실제 도메인
# - adminPassword: admin → 강력한 비밀번호

bash install.sh

# 설치 확인 (몇 분 소요)
kubectl get pods -n monitoring

# Grafana 접속
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# http://localhost:3000
```

## 4. GitOps 설정

### Step 1: GitHub 저장소 설정

```bash
# 저장소 초기화 (아직 안 했다면)
git init
git add .
git commit -m "Initial commit: EKS with GitOps"

# GitHub 저장소 생성 후
git remote add origin https://github.com/YOUR-ORG/YOUR-REPO.git
git branch -M main
git push -u origin main
```

### Step 2: ArgoCD Application 설정

모든 `kubernetes/applications/argocd-apps/*.yaml` 파일에서 GitHub 저장소 URL 업데이트:

```yaml
repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git  # 실제 저장소로 변경
```

### Step 3: App of Apps 배포

```bash
# Root application 배포
kubectl apply -f ../kubernetes/applications/argocd-apps/app-of-apps.yaml

# ArgoCD가 자동으로 모든 애플리케이션 동기화
kubectl get applications -n argocd

# ArgoCD CLI로 확인
argocd login localhost:8080
argocd app list
argocd app get app-of-apps
```

## 5. GitHub Actions 설정

### GitHub Secrets 추가

GitHub 저장소 > Settings > Secrets and variables > Actions:

1. **AWS_ACCESS_KEY_ID**
   ```bash
   # IAM 사용자 생성 및 키 발급
   aws iam create-user --user-name github-actions
   aws iam attach-user-policy --user-name github-actions --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
   aws iam create-access-key --user-name github-actions
   ```

2. **AWS_SECRET_ACCESS_KEY**
   - 위 명령에서 출력된 SecretAccessKey

3. **CLUSTER_NAME**
   ```
   my-eks-cluster
   ```

4. **ARGOCD_SERVER**
   ```bash
   # Ingress가 설정되어 있다면
   echo "argocd.yourdomain.com"

   # 또는 LoadBalancer 주소
   kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```

5. **ARGOCD_TOKEN**
   ```bash
   # ArgoCD에서 토큰 생성
   argocd account generate-token --account admin
   ```

### 워크플로우 테스트

```bash
# Terraform 워크플로우 트리거
git add terraform/
git commit -m "Update terraform config"
git push

# GitHub Actions 페이지에서 실행 확인
```

## 6. 도메인 및 DNS 설정

### Route53 설정

```bash
# Hosted Zone이 있다고 가정

# Ingress LoadBalancer 주소 확인
LB_ADDRESS=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Route53에 레코드 추가
aws route53 change-resource-record-sets --hosted-zone-id YOUR_ZONE_ID --change-batch '{
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "*.yourdomain.com",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{"Value": "'$LB_ADDRESS'"}]
    }
  }]
}'
```

### 도메인 업데이트

다음 파일들에서 `example.com`을 실제 도메인으로 변경:
- `kubernetes/infrastructure/argocd/ingress.yaml`
- `kubernetes/infrastructure/monitoring/values.yaml`

```bash
git add .
git commit -m "Update domains"
git push

# ArgoCD가 자동으로 동기화
argocd app sync infrastructure
```

## 7. 검증

### 인프라 검증
```bash
# 모든 노드가 Ready 상태인지 확인
kubectl get nodes

# 시스템 파드 확인
kubectl get pods -A

# ArgoCD 애플리케이션 상태
argocd app list
```

### 모니터링 검증
```bash
# Prometheus targets 확인
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# http://localhost:9090/targets

# Grafana 대시보드 확인
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# http://localhost:3000
```

### Ingress 검증
```bash
# Test deployment 생성
kubectl create deployment nginx --image=nginx -n dev
kubectl expose deployment nginx --port=80 -n dev

# Ingress 생성
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-test
  namespace: dev
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-staging
spec:
  ingressClassName: nginx
  rules:
    - host: test.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx
                port:
                  number: 80
  tls:
    - hosts:
        - test.yourdomain.com
      secretName: nginx-test-tls
EOF

# 접속 테스트
curl https://test.yourdomain.com
```

## 8. 다음 단계

1. **애플리케이션 배포**: `kubernetes/applications/overlays/dev/`에 앱 매니페스트 추가
2. **모니터링 설정**: Grafana 대시보드 커스터마이징
3. **알림 설정**: AlertManager 규칙 추가
4. **백업 설정**: Velero 등 백업 솔루션 추가
5. **보안 강화**: Network Policy, Pod Security Standards 설정

## 문제 해결

### ArgoCD 접속 안 됨
```bash
# Port-forward 재시작
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 비밀번호 재설정
argocd account update-password
```

### Terraform apply 실패
```bash
# State 확인
terraform show

# 리소스 재동기화
terraform refresh

# 특정 리소스만 다시 생성
terraform taint aws_eks_node_group.main
terraform apply
```

### kubectl 접속 안 됨
```bash
# kubeconfig 재설정
rm ~/.kube/config
aws eks update-kubeconfig --region ap-northeast-2 --name my-eks-cluster

# IAM 권한 확인
aws sts get-caller-identity
```