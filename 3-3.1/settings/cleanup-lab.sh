#!/bin/bash

# DO280 Lab 3-3 정리 스크립트
# RBAC 권한 설정 실습 환경 초기화

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-3.1 환경 정리"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 사전 조건 확인
echo -e "${YELLOW}[1/6] 사전 조건 확인 중...${NC}"

if ! oc whoami &>/dev/null; then
    echo -e "${RED}✗ OpenShift 클러스터에 로그인되어 있지 않습니다.${NC}"
    echo "먼저 'oc login' 명령으로 클러스터 관리자 권한으로 로그인하세요."
    exit 1
fi

# 현재 사용자가 emma인 경우 권한 확인
CURRENT_USER=$(oc whoami)
if [[ "$CURRENT_USER" == "emma" ]]; then
    if ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
        echo -e "${RED}✗ 클러스터 관리자 권한이 필요합니다.${NC}"
        exit 1
    fi
elif ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
    echo -e "${RED}✗ 클러스터 관리자 권한이 필요합니다.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 사전 조건 확인 완료${NC}"
echo ""

# 1. 부여된 권한 제거
echo -e "${YELLOW}[2/6] 부여된 클러스터 권한 제거 중...${NC}"

# emma cluster-admin 권한 제거
if oc get clusterrolebinding | grep -q "emma.*cluster-admin"; then
    oc adm policy remove-cluster-role-from-user cluster-admin emma 2>/dev/null || true
    echo "  ✓ emma cluster-admin 권한 제거됨"
else
    echo "  - emma cluster-admin 권한이 이미 없음"
fi

# alice self-provisioner 권한 제거
if oc get clusterrolebinding self-provisioners -o yaml | grep -q "alice"; then
    oc adm policy remove-cluster-role-from-user self-provisioner alice 2>/dev/null || true
    echo "  ✓ alice self-provisioner 권한 제거됨"
else
    echo "  - alice self-provisioner 권한이 이미 없음"
fi

# bob cluster-reader 권한 제거
if oc get clusterrolebinding | grep -q "bob.*cluster-reader"; then
    oc adm policy remove-cluster-role-from-user cluster-reader bob 2>/dev/null || true
    echo "  ✓ bob cluster-reader 권한 제거됨"
else
    echo "  - bob cluster-reader 권한이 이미 없음"
fi

echo -e "${GREEN}✓ 클러스터 권한 제거 완료${NC}"
echo ""

# 2. 생성된 프로젝트 삭제
echo -e "${YELLOW}[3/6] 실습 중 생성된 프로젝트 삭제 중...${NC}"

# alice가 생성했을 수 있는 프로젝트들 확인 및 삭제
ALICE_PROJECTS=("alice-project" "alice-test")
for project in "${ALICE_PROJECTS[@]}"; do
    if oc get project "$project" &>/dev/null; then
        oc delete project "$project" --wait=false 2>/dev/null || true
        echo "  ✓ 프로젝트 '$project' 삭제 요청함"
    fi
done

# 기타 테스트 프로젝트들 확인 및 삭제
TEST_PROJECTS=("bob-test-project" "charlie-project" "david-project")
for project in "${TEST_PROJECTS[@]}"; do
    if oc get project "$project" &>/dev/null; then
        oc delete project "$project" --wait=false 2>/dev/null || true
        echo "  ✓ 프로젝트 '$project' 삭제 요청함"
    fi
done

echo -e "${GREEN}✓ 프로젝트 삭제 완료${NC}"
echo ""

# 3. kubeadmin 복원 (선택적)
echo -e "${YELLOW}[4/6] kubeadmin 복원 여부 확인 중...${NC}"

if ! oc get secrets kubeadmin -n kube-system &>/dev/null; then
    echo "  ⚠ kubeadmin secret이 제거되어 있습니다."
    echo "  - 운영 환경에서는 kubeadmin을 제거하는 것이 권장됩니다."
    echo "  - 실습 환경에서 kubeadmin이 필요한 경우 수동으로 복원하세요."
else
    echo "  ✓ kubeadmin secret이 존재합니다."
fi

echo -e "${GREEN}✓ kubeadmin 상태 확인 완료${NC}"
echo ""

# 4. self-provisioner 기본 설정 복원
echo -e "${YELLOW}[5/6] self-provisioner 기본 설정 복원 중...${NC}"

# system:authenticated:oauth 그룹에 self-provisioner 권한이 있는지 확인
if ! oc get clusterrolebinding self-provisioners -o yaml | grep -q "system:authenticated:oauth"; then
    echo "  - self-provisioner 기본 설정 복원 중..."
    oc adm policy add-cluster-role-to-group self-provisioner system:authenticated:oauth 2>/dev/null || true
    echo "  ✓ 모든 인증된 사용자에게 self-provisioner 권한 복원됨"
else
    echo "  ✓ self-provisioner 기본 설정이 이미 존재함"
fi

echo -e "${GREEN}✓ self-provisioner 기본 설정 복원 완료${NC}"
echo ""

# 5. 백업 파일 정리
echo -e "${YELLOW}[6/6] 백업 파일 정리 중...${NC}"

cd "$LAB_DIR"

if [ -f clusterrolebinding-backup.yaml ]; then
    rm -f clusterrolebinding-backup.yaml
    echo "  ✓ clusterrolebinding-backup.yaml 삭제됨"
fi

echo -e "${GREEN}✓ 백업 파일 정리 완료${NC}"
echo ""

# 정리 완료 메시지
echo -e "${BLUE}=========================================="
echo "실습 환경 정리 완료!"
echo "=========================================="
echo ""
echo "다음 항목들이 정리되었습니다:"
echo "✓ emma의 cluster-admin 권한 제거"
echo "✓ alice의 self-provisioner 권한 제거"
echo "✓ bob의 cluster-reader 권한 제거"
echo "✓ 실습 중 생성된 프로젝트 삭제"
echo "✓ self-provisioner 기본 설정 복원"
echo "✓ 백업 파일 정리"
echo ""
echo "참고사항:"
echo "- kubeadmin은 보안상 제거된 상태로 유지됩니다"
echo "- 모든 사용자는 기본 권한으로 복원되었습니다"
echo "- 사용자 계정 자체는 유지됩니다 (3-1 실습 결과)"
echo ""
echo "현재 권한 상태 확인:"
echo "oc get clusterrolebinding | grep -E 'emma|alice|bob|charlie|david'"
echo -e "${NC}"

echo -e "${GREEN}✓ 전체 정리 작업 완료${NC}"