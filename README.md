# AWS EKS Terraform Configuration

이 프로젝트는 AWS에 EKS (Elastic Kubernetes Service) 클러스터를 배포하기 위한 Terraform 구성입니다.

## 주요 기능

- **완전한 VPC 네트워킹**: 퍼블릭 및 프라이빗 서브넷, NAT Gateway, Internet Gateway
- **EKS 클러스터**: 최신 Kubernetes 버전 지원
- **관리형 노드 그룹**: Auto Scaling이 가능한 EC2 워커 노드
- **필수 애드온**:
  - VPC CNI - EKS 네트워킹
  - CoreDNS - DNS 서비스
  - kube-proxy - 네트워크 프록시
  - EBS CSI Driver - 영구 스토리지
- **AWS Load Balancer Controller 지원**: IAM 역할 및 정책 사전 구성
- **보안 설정**: KMS 암호화, 보안 그룹, IAM 역할
- **모니터링**: Control Plane 로깅 활성화

## 사전 요구사항

1. **Terraform**: >= 1.0
2. **AWS CLI**: 최신 버전 설치 및 구성
3. **AWS 계정**: 적절한 권한이 있는 IAM 사용자 또는 역할
4. **kubectl**: Kubernetes 클러스터 관리용

## 빠른 시작

### 1. AWS 자격 증명 설정

```bash
aws configure
```

### 2. 변수 파일 생성

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` 파일을 편집하여 환경에 맞게 값을 수정합니다:

```hcl
cluster_name = "my-eks-cluster"
aws_region   = "ap-northeast-2"
```

### 3. Terraform 초기화

```bash
terraform init
```

### 4. 실행 계획 확인

```bash
terraform plan
```

### 5. 인프라 배포

```bash
terraform apply
```

배포는 약 15-20분 정도 소요됩니다.

### 6. kubectl 구성

```bash
aws eks update-kubeconfig --region ap-northeast-2 --name my-eks-cluster
```

또는 Terraform 출력에서 제공된 명령어를 사용:

```bash
terraform output -raw configure_kubectl | bash
```

### 7. 클러스터 확인

```bash
kubectl get nodes
kubectl get pods -A
```

## AWS Load Balancer Controller 설치

AWS Load Balancer Controller는 Helm을 통해 별도로 설치해야 합니다.

### 방법 1: Helm 사용

```bash
# Helm repo 추가
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Load Balancer Controller 설치
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-eks-cluster \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$(terraform output -raw aws_load_balancer_controller_iam_role_arn)
```

### 방법 2: kubectl 사용

```bash
# CRD 설치
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"

# Controller 배포 (deployment yaml 필요)
```

## 주요 구성 파일

- `versions.tf` - Terraform 및 Provider 버전 설정
- `vpc.tf` - VPC, 서브넷, NAT Gateway 등 네트워킹 리소스
- `eks.tf` - EKS 클러스터 및 보안 그룹
- `node-groups.tf` - 관리형 노드 그룹 설정
- `iam.tf` - IAM 역할 및 정책
- `addons.tf` - EKS 애드온 구성
- `variables.tf` - 입력 변수 정의
- `outputs.tf` - 출력 값 정의

## 주요 변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `cluster_name` | EKS 클러스터 이름 | (필수) |
| `aws_region` | AWS 리전 | `ap-northeast-2` |
| `kubernetes_version` | Kubernetes 버전 | `1.31` |
| `vpc_cidr` | VPC CIDR 블록 | `10.0.0.0/16` |
| `node_group_instance_types` | 노드 인스턴스 타입 | `["t3.medium"]` |
| `node_group_desired_size` | 노드 희망 개수 | `2` |
| `node_group_min_size` | 노드 최소 개수 | `1` |
| `node_group_max_size` | 노드 최대 개수 | `4` |

전체 변수 목록은 `variables.tf` 파일을 참조하세요.

## 주요 출력 값

배포 후 다음 명령어로 출력 값을 확인할 수 있습니다:

```bash
# 모든 출력 값 보기
terraform output

# 특정 출력 값 보기
terraform output cluster_endpoint
terraform output configure_kubectl
```

주요 출력:
- `cluster_endpoint` - EKS API 서버 엔드포인트
- `cluster_id` - 클러스터 ID
- `vpc_id` - VPC ID
- `configure_kubectl` - kubectl 구성 명령어

## 보안 고려사항

### 프로덕션 환경 권장 사항

1. **API 엔드포인트 접근 제한**:
   ```hcl
   cluster_endpoint_public_access_cidrs = ["YOUR_IP/32"]
   ```

2. **KMS 암호화 활성화**:
   ```hcl
   kms_key_arn = "arn:aws:kms:region:account:key/key-id"
   ```

3. **Private 엔드포인트만 사용**:
   ```hcl
   cluster_endpoint_public_access  = false
   cluster_endpoint_private_access = true
   ```

4. **SPOT 인스턴스 사용** (비용 절감):
   ```hcl
   node_group_capacity_type = "SPOT"
   ```

## 비용 관리

이 구성으로 생성되는 주요 비용 요소:

- EKS 클러스터: $0.10/시간 (~$73/월)
- EC2 노드: 인스턴스 타입 및 개수에 따라 다름
- NAT Gateway: $0.059/시간 × AZ 개수 (~$45/월 × 3 = $135/월)
- EBS 볼륨: 노드당 스토리지
- 데이터 전송

**비용 절감 팁**:
- NAT Gateway를 1개만 사용
- SPOT 인스턴스 활용
- Auto Scaling 적극 활용

## 문제 해결

### 노드가 클러스터에 참여하지 못하는 경우

```bash
# 노드 상태 확인
kubectl get nodes

# 노드 그룹 상태 확인
aws eks describe-nodegroup --cluster-name my-eks-cluster --nodegroup-name my-eks-cluster-node-group
```

### AWS Load Balancer Controller 문제

```bash
# Controller 로그 확인
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# ServiceAccount 확인
kubectl get sa -n kube-system aws-load-balancer-controller -o yaml
```

### VPC CNI 문제

```bash
# CNI 로그 확인
kubectl logs -n kube-system -l k8s-app=aws-node
```

## 정리

리소스를 삭제하려면:

```bash
terraform destroy
```

**주의**: 이 명령은 모든 리소스를 삭제합니다. 프로덕션 환경에서는 주의해서 사용하세요.

## 추가 리소스

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## 라이선스

MIT License

## 기여

이슈나 풀 리퀘스트를 환영합니다.