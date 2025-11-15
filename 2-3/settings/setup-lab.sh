#!/bin/bash

# DO280 Lab 2-3 Setup Script
# Helm Chart를 사용한 애플리케이션 배포 실습 환경 구성

set -e

echo "=== DO280 Lab 2-3 Setup: Helm Chart를 사용한 애플리케이션 배포 ==="
echo

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 헬퍼 함수들
print_header() {
    echo -e "${BLUE}==== $1 ====${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# OpenShift 로그인 상태 확인
print_header "OpenShift 로그인 상태 확인"
if ! oc whoami &> /dev/null; then
    print_error "OpenShift에 로그인하지 않았습니다."
    echo "다음 명령으로 로그인하세요:"
    echo "oc login -u <username> -p <password> <cluster-url>"
    exit 1
fi

CURRENT_USER=$(oc whoami)
print_success "현재 사용자: $CURRENT_USER"

# Helm 설치 상태 확인
print_header "Helm 설치 상태 확인"
if ! command -v helm &> /dev/null; then
    print_error "Helm이 설치되지 않았습니다."
    echo "다음 방법으로 Helm을 설치하세요:"
    echo
    echo "=== Linux (curl 방법) ==="
    echo "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    echo
    echo "=== Package Manager 방법 ==="
    echo "# RHEL/CentOS/Fedora:"
    echo "sudo dnf install helm"
    echo
    echo "# Ubuntu/Debian:"
    echo "curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -"
    echo "echo \"deb https://baltocdn.com/helm/stable/debian/ all main\" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list"
    echo "sudo apt-get update"
    echo "sudo apt-get install helm"
    echo
    echo "=== 바이너리 직접 다운로드 ==="
    echo "https://github.com/helm/helm/releases"
    exit 1
fi

HELM_VERSION=$(helm version --short --client 2>/dev/null || helm version --short 2>/dev/null || echo "알 수 없음")
print_success "Helm 버전: $HELM_VERSION"

# helm-demo 프로젝트 생성
print_header "helm-demo 프로젝트 생성"
if oc get project helm-demo &> /dev/null; then
    print_warning "helm-demo 프로젝트가 이미 존재합니다. 기존 프로젝트를 정리합니다."
    oc delete project helm-demo --ignore-not-found=true
    
    # 프로젝트 삭제 완료 대기 (최대 60초)
    echo "프로젝트 삭제 완료 대기 중..."
    for i in {1..60}; do
        if ! oc get project helm-demo &> /dev/null; then
            print_success "기존 프로젝트가 완전히 삭제되었습니다."
            break
        fi
        echo -n "."
        sleep 1
    done
    echo
fi

# 새 프로젝트 생성
oc new-project helm-demo --description="Helm Chart 실습용 프로젝트" --display-name="Helm Demo Project"
print_success "helm-demo 프로젝트가 생성되었습니다."

# 프로젝트로 전환
oc project helm-demo
print_success "helm-demo 프로젝트로 전환했습니다."

# 기존 Helm Repository 정리
print_header "Helm Repository 초기화"
if helm repo list &> /dev/null; then
    print_warning "기존 Helm Repository가 존재합니다. 정리합니다."
    
    # 기존 Repository 목록 확인
    echo "기존 Repository 목록:"
    helm repo list || echo "  (없음)"
    echo
    
    # 이전 실습 Repository가 있다면 제거
    if helm repo list 2>/dev/null | grep -q "nginx-repo"; then
        helm repo remove nginx-repo
        print_success "기존 nginx-repo Repository가 제거되었습니다."
    fi
    if helm repo list 2>/dev/null | grep -q "openshift-charts"; then
        helm repo remove openshift-charts
        print_success "기존 openshift-charts Repository가 제거되었습니다."
    fi
else
    print_success "Helm Repository가 깨끗한 상태입니다."
fi

# Helm Repository 상태 확인
echo "현재 Repository 상태:"
helm repo list 2>/dev/null || echo "  (Repository 없음 - 정상)"
echo

# 작업 디렉터리 생성
print_header "작업 디렉터리 구성"
WORK_DIR="/home/student/helm-lab17"
if [ -d "$WORK_DIR" ]; then
    print_warning "기존 작업 디렉터리를 정리합니다: $WORK_DIR"
    rm -rf "$WORK_DIR"
fi

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
print_success "작업 디렉터리 생성: $WORK_DIR"

# 실습 참조 파일 생성
print_header "실습 참조 파일 생성"

# Helm 명령어 참조 파일
cat > helm-commands.txt << 'EOF'
=== DO280 Lab 2-3: Helm Chart 실습 명령어 참조 ===

1. Repository 추가:
   helm repo add openshift-charts https://charts.openshift.io/

2. Repository 확인:
   helm repo list
   helm repo update

3. Chart 검색:
   helm search repo openshift-charts
   helm search repo openshift-charts/redhat-nginx
   helm search repo openshift-charts/alquimia-runtime-helm --versions

4. Nginx 애플리케이션 설치:
   helm install example-app openshift-charts/redhat-nginx-template

5. Alquimia 애플리케이션 설치 (버전 0.1.0):
   helm install alquimia-app openshift-charts/alquimia-runtime-helm --version 0.1.0

6. 설치 상태 확인:
   helm list
   helm status alquimia-app

7. 업그레이드 (버전 0.2.0 또는 0.2.1):
   helm upgrade alquimia-app openshift-charts/alquimia-runtime-helm --version 0.2.1

8. 업그레이드 히스토리:
   helm history alquimia-app

9. 리소스 확인:
   oc get all -l app.kubernetes.io/instance=example-app
   oc get all -l app.kubernetes.io/instance=alquimia-app

10. Chart 정보 확인:
    helm show chart openshift-charts/redhat-nginx-template
    helm show values openshift-charts/alquimia-runtime-helm --version 0.2.1

11. 정리:
    helm uninstall example-app
    helm uninstall alquimia-app
    helm repo remove openshift-charts
EOF

print_success "Helm 명령어 참조 파일이 생성되었습니다: helm-commands.txt"

# values.yaml 템플릿 생성
cat > values-template.yaml << 'EOF'
# DO280 Lab 2-3 - 사용자 정의 Values 템플릿
# 필요에 따라 이 파일을 수정하여 사용하세요

# 복제본 수
replicaCount: 1

# 이미지 설정
image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: ""

# 서비스 설정
service:
  type: ClusterIP
  port: 80

# 리소스 제한
resources: {}
  # limits:
  #   cpu: 100m
  #   memory: 128Mi
  # requests:
  #   cpu: 100m
  #   memory: 128Mi

# 노드 선택기
nodeSelector: {}

# 톨러레이션
tolerations: []

# 어피니티
affinity: {}
EOF

print_success "Values 템플릿 파일이 생성되었습니다: values-template.yaml"

# 실습 스크립트 생성
cat > run-lab.sh << 'EOF'
#!/bin/bash

# DO280 Lab 2-3 실습 스크립트
# 이 스크립트는 실습 단계를 자동으로 실행합니다

set -e

echo "=== DO280 Lab 2-3: Helm Chart 실습 실행 ==="
echo

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}단계 $1: $2${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# OpenShift 프로젝트 전환
oc project helm-demo

print_step "1" "Repository 추가"
if helm repo list 2>/dev/null | grep -q "openshift-charts"; then
    print_warning "openshift-charts가 이미 존재합니다."
else
    helm repo add openshift-charts https://charts.openshift.io/
    print_success "openshift-charts Repository가 추가되었습니다."
fi

print_step "2" "Repository 업데이트"
helm repo update
print_success "Repository가 업데이트되었습니다."

print_step "3" "사용 가능한 Chart 확인"
echo "Repository 목록:"
helm repo list
echo
echo "Red Hat Nginx Charts:"
helm search repo openshift-charts/redhat-nginx
echo
echo "Alquimia Runtime Helm (모든 버전):"
helm search repo openshift-charts/alquimia-runtime-helm --versions

print_step "4" "Nginx 애플리케이션 설치"
if helm list | grep -q "example-app"; then
    print_warning "example-app이 이미 설치되어 있습니다."
    helm uninstall example-app
    sleep 5
fi

helm install example-app openshift-charts/redhat-nginx-template
print_success "example-app이 Red Hat Nginx template으로 설치되었습니다."

print_step "5" "Alquimia 애플리케이션 초기 설치 (버전 0.1.0)"
if helm list | grep -q "alquimia-app"; then
    print_warning "alquimia-app이 이미 설치되어 있습니다."
    helm uninstall alquimia-app
    sleep 5
fi

helm install alquimia-app openshift-charts/alquimia-runtime-helm --version 0.1.0
print_success "alquimia-app이 버전 0.1.0으로 설치되었습니다."

print_step "6" "설치 상태 확인"
echo "Helm Release 목록:"
helm list
echo
echo "Nginx Release 상태:"
helm status example-app
echo
echo "Alquimia Release 상태:"
helm status alquimia-app
echo
echo "Kubernetes 리소스:"
oc get all

print_step "7" "업그레이드 (버전 0.2.1)"
helm upgrade alquimia-app openshift-charts/alquimia-runtime-helm --version 0.2.1
print_success "alquimia-app이 버전 0.2.1로 업그레이드되었습니다."

print_step "8" "업그레이드 결과 확인"
echo "Release 목록:"
helm list
echo
echo "Alquimia Release 히스토리:"
helm history alquimia-app
echo
echo "업데이트된 리소스:"
oc get all

print_success "Lab 2-3 실습이 완료되었습니다!"
echo
echo "=== 추가 명령어 ==="
echo "• Nginx Release 정보: helm get all example-app"
echo "• Alquimia Release 정보: helm get all alquimia-app"
echo "• 매니페스트 확인: helm get manifest alquimia-app"
echo "• Values 확인: helm get values alquimia-app"
echo "• 정리: helm uninstall example-app alquimia-app && helm repo remove openshift-charts"
EOF

chmod +x run-lab.sh
print_success "실습 자동 실행 스크립트가 생성되었습니다: run-lab.sh"

# 현재 상태 표시
print_header "실습 환경 상태 확인"
echo "=== OpenShift 프로젝트 ==="
oc get projects | grep helm-demo || echo "helm-demo 프로젝트 정보"

echo
echo "=== Helm Repository 상태 ==="
helm repo list 2>/dev/null || echo "Repository 없음 (정상 - 실습에서 추가 예정)"

echo
echo "=== 작업 디렉터리 ==="
echo "위치: $WORK_DIR"
echo "파일 목록:"
ls -la "$WORK_DIR"

# 실습 준비 완료 안내
print_header "실습 준비 완료"
print_success "Lab 2-3 환경 구성이 완료되었습니다!"
echo
echo -e "${YELLOW}실습 시작 방법:${NC}"
echo "1. 수동 실습: README.md 파일의 단계별 가이드를 따라하세요"
echo "2. 자동 실습: ./run-lab.sh 스크립트를 실행하세요"
echo
echo -e "${YELLOW}작업 디렉터리:${NC}"
echo "cd $WORK_DIR"
echo
echo -e "${YELLOW}주요 파일:${NC}"
echo "• helm-commands.txt: 명령어 참조"
echo "• values-template.yaml: Values 파일 템플릿"
echo "• run-lab.sh: 자동 실습 스크립트"
echo
echo -e "${BLUE}실습 가이드:${NC} README.md 파일을 참조하세요."
echo -e "${BLUE}정리 명령:${NC} ./cleanup-lab.sh"
echo

print_success "Lab 2-3 실습을 시작하세요!"