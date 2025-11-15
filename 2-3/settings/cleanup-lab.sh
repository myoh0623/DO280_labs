#!/bin/bash

# DO280 Lab 2-3 Cleanup Script
# Helm Chart를 사용한 애플리케이션 배포 실습 환경 정리

set -e

echo "=== DO280 Lab 2-3 Cleanup: Helm Chart를 사용한 애플리케이션 배포 정리 ==="
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
print_header "Helm 상태 확인"
if ! command -v helm &> /dev/null; then
    print_warning "Helm이 설치되지 않았습니다. Helm 관련 정리를 건너뜁니다."
    HELM_AVAILABLE=false
else
    HELM_VERSION=$(helm version --short --client 2>/dev/null || helm version --short 2>/dev/null || echo "알 수 없음")
    print_success "Helm 버전: $HELM_VERSION"
    HELM_AVAILABLE=true
fi

# Helm Release 정리
if [ "$HELM_AVAILABLE" = true ]; then
    print_header "Helm Release 정리"
    
    # 현재 helm-demo 프로젝트의 Release 확인
    if oc get project helm-demo &> /dev/null; then
        oc project helm-demo 2>/dev/null || true
        
        # 현재 Release 목록 확인
        RELEASES=$(helm list 2>/dev/null | tail -n +2 | awk '{print $1}' || echo "")
        if [ -n "$RELEASES" ]; then
            echo "삭제할 Helm Release:"
            helm list || echo "  (없음)"
            echo
            
            read -p "모든 Helm Release를 삭제하시겠습니까? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_header "Helm Release 삭제"
                
                # 각 Release 삭제
                for release in $RELEASES; do
                    echo "삭제 중: $release"
                    helm uninstall $release --ignore-not-found
                    print_success "$release Release가 삭제되었습니다."
                done
                
                # Pod 종료 대기
                echo "Pod 종료 대기 중..."
                for i in {1..30}; do
                    if ! oc get pods --no-headers 2>/dev/null | grep -q .; then
                        print_success "모든 Pod가 종료되었습니다."
                        break
                    fi
                    echo -n "."
                    sleep 2
                done
                echo
            else
                print_warning "Helm Release 삭제를 취소했습니다."
            fi
        else
            print_warning "삭제할 Helm Release가 없습니다."
        fi
    fi
    
    # Helm Repository 정리
    print_header "Helm Repository 정리"
    if helm repo list 2>/dev/null | grep -qE "nginx-repo|openshift-charts"; then
        echo "삭제할 Repository:"
        helm repo list | grep -E "nginx-repo|openshift-charts" || echo "  (없음)"
        echo
        
        read -p "실습 Repository를 삭제하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            helm repo remove nginx-repo 2>/dev/null || true
            helm repo remove openshift-charts 2>/dev/null || true
            print_success "실습 Repository가 삭제되었습니다."
        else
            print_warning "Repository 삭제를 취소했습니다."
        fi
    else
        print_warning "삭제할 실습 Repository가 없습니다."
    fi
    
    # 최종 Helm 상태 확인
    echo
    echo "=== 정리 후 Helm 상태 ==="
    echo "Repository 목록:"
    helm repo list 2>/dev/null || echo "  (Repository 없음)"
    echo
    echo "Release 목록:"
    if oc get project helm-demo &> /dev/null; then
        oc project helm-demo 2>/dev/null && helm list 2>/dev/null || echo "  (Release 없음)"
    fi
fi

# helm-demo 프로젝트 정리
print_header "helm-demo 프로젝트 정리"
if oc get project helm-demo &> /dev/null; then
    echo "helm-demo 프로젝트에서 생성된 리소스들을 정리합니다..."
    
    # 프로젝트로 전환
    oc project helm-demo 2>/dev/null || true
    
    # 현재 리소스 상태 표시
    echo
    echo "=== 삭제할 리소스 목록 ==="
    
    echo "Deployments:"
    oc get deployments --no-headers 2>/dev/null | awk '{print "  - " $1}' || echo "  (없음)"
    
    echo "Services:"
    oc get services --no-headers 2>/dev/null | grep -v kubernetes | awk '{print "  - " $1}' || echo "  (없음)"
    
    echo "Pods:"
    oc get pods --no-headers 2>/dev/null | awk '{print "  - " $1}' || echo "  (없음)"
    
    echo "ConfigMaps:"
    oc get configmaps --no-headers 2>/dev/null | awk '{print "  - " $1}' || echo "  (없음)"
    
    echo
    
    read -p "helm-demo 프로젝트 전체를 삭제하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_header "프로젝트 삭제"
        oc delete project helm-demo --ignore-not-found=true
        
        # 프로젝트 삭제 완료 대기
        echo "프로젝트 삭제 완료 대기 중..."
        for i in {1..60}; do
            if ! oc get project helm-demo &> /dev/null; then
                print_success "helm-demo 프로젝트가 완전히 삭제되었습니다."
                break
            fi
            echo -n "."
            sleep 1
        done
        echo
    else
        print_warning "프로젝트 삭제를 취소했습니다."
    fi
else
    print_warning "helm-demo 프로젝트가 존재하지 않습니다."
fi

# 작업 디렉터리 정리
print_header "작업 디렉터리 정리"
WORK_DIR="/home/student/helm-lab17"
if [ -d "$WORK_DIR" ]; then
    echo "작업 디렉터리 정리: $WORK_DIR"
    
    # 디렉터리 내용 확인
    if [ "$(ls -A $WORK_DIR 2>/dev/null)" ]; then
        echo "삭제될 파일:"
        ls -la "$WORK_DIR" | grep -v "^total" | awk '{print "  - " $9}'
        echo
        
        read -p "작업 디렉터리를 삭제하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$WORK_DIR"
            print_success "작업 디렉터리가 삭제되었습니다."
        else
            print_warning "작업 디렉터리가 유지되었습니다."
        fi
    else
        print_warning "작업 디렉터리가 비어있습니다."
    fi
else
    print_warning "작업 디렉터리가 존재하지 않습니다."
fi

# 기본 프로젝트로 전환
print_header "기본 프로젝트로 전환"
if oc get project default &> /dev/null; then
    oc project default
    print_success "default 프로젝트로 전환했습니다."
else
    # default 프로젝트가 없는 경우 첫 번째 접근 가능한 프로젝트로 전환
    FIRST_PROJECT=$(oc get projects -o name 2>/dev/null | head -n 1 | cut -d'/' -f2)
    if [ -n "$FIRST_PROJECT" ]; then
        oc project "$FIRST_PROJECT"
        print_success "$FIRST_PROJECT 프로젝트로 전환했습니다."
    else
        print_warning "전환할 수 있는 프로젝트가 없습니다."
    fi
fi

# 정리 완료 상태 확인
print_header "정리 완료 상태 확인"
echo "=== 현재 프로젝트 목록 ==="
oc get projects | grep -E "(NAME|helm-demo)" || echo "helm-demo 프로젝트가 없습니다."

echo
echo "=== 현재 작업 프로젝트 ==="
CURRENT_PROJECT=$(oc project -q 2>/dev/null || echo "없음")
echo "현재 프로젝트: $CURRENT_PROJECT"

if [ "$HELM_AVAILABLE" = true ]; then
    echo
    echo "=== Helm Repository 상태 ==="
    helm repo list 2>/dev/null || echo "Repository 없음"
    
    echo
    echo "=== Helm Release 상태 ==="
    if oc get project helm-demo &> /dev/null; then
        oc project helm-demo 2>/dev/null && helm list 2>/dev/null || echo "Release 없음"
    else
        echo "helm-demo 프로젝트 없음"
    fi
fi

echo
echo "=== 작업 디렉터리 상태 ==="
if [ -d "$WORK_DIR" ]; then
    echo "작업 디렉터리: $WORK_DIR (유지됨)"
    ls -la "$WORK_DIR" 2>/dev/null || echo "디렉터리 접근 불가"
else
    echo "작업 디렉터리: 삭제됨"
fi

# 최종 안내
print_header "정리 완료"
print_success "Lab 2-3 환경 정리가 완료되었습니다!"
echo
echo -e "${YELLOW}정리된 항목:${NC}"
echo "• Helm Release (example-app, alquimia-app 등)"
echo "• Helm Repository (openshift-charts, nginx-repo)"
echo "• OpenShift 프로젝트 (helm-demo)"
echo "• 작업 디렉터리 (선택적)"
echo
echo -e "${BLUE}다시 실습하려면:${NC}"
echo "  ./setup-lab.sh"
echo
echo -e "${GREEN}수고하셨습니다!${NC}"