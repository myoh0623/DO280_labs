#!/bin/bash

# DO280 Lab 3-3: RBAC 권한 설정 자동 구성 스크립트
# 모든 권한 요구사항을 자동으로 적용

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-3.1 - RBAC 권한 설정 자동 구성"
echo "=========================================="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 사전 조건 확인
echo -e "${YELLOW}[1/7] 사전 조건 확인 중...${NC}"

if ! oc whoami &>/dev/null; then
    echo -e "${RED}✗ OpenShift 클러스터에 로그인되어 있지 않습니다.${NC}"
    exit 1
fi

if ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
    echo -e "${RED}✗ 클러스터 관리자 권한이 필요합니다.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 사전 조건 확인 완료${NC}"
echo ""

# 1. emma에게 cluster-admin 권한 부여
echo -e "${YELLOW}[2/7] emma에게 cluster-admin 권한 부여 중...${NC}"

oc adm policy add-cluster-role-to-user cluster-admin emma

echo -e "${GREEN}✓ emma cluster-admin 권한 부여 완료${NC}"
echo "  - emma는 이제 모든 클러스터 관리 작업을 수행할 수 있습니다."
echo ""

# 2. alice에게 self-provisioner 권한 부여
echo -e "${YELLOW}[3/7] alice에게 프로젝트 생성 권한 부여 중...${NC}"

oc adm policy add-cluster-role-to-user self-provisioner alice

echo -e "${GREEN}✓ alice 프로젝트 생성 권한 부여 완료${NC}"
echo "  - alice는 이제 새로운 프로젝트를 생성할 수 있습니다."
echo ""

# 3. bob에게 cluster-reader 권한 부여
echo -e "${YELLOW}[4/7] bob에게 cluster-reader 권한 부여 중...${NC}"

oc adm policy add-cluster-role-to-user cluster-reader bob

echo -e "${GREEN}✓ bob cluster-reader 권한 부여 완료${NC}"
echo "  - bob은 이제 클러스터 전체 리소스를 조회할 수 있습니다."
echo ""

# 4. charlie와 david 권한 확인 (기본적으로 제한됨)
echo -e "${YELLOW}[5/7] charlie와 david 권한 상태 확인 중...${NC}"

echo "  - charlie 권한 상태:"
if oc get clusterrolebinding | grep -q "charlie.*cluster-admin"; then
    echo -e "${RED}    ⚠ charlie에게 cluster-admin 권한이 있습니다. 제거해야 합니다.${NC}"
    oc adm policy remove-cluster-role-from-user cluster-admin charlie 2>/dev/null || true
    echo "    ✓ charlie cluster-admin 권한 제거됨"
else
    echo "    ✓ charlie는 cluster-admin 권한이 없습니다. (정상)"
fi

echo "  - david 권한 상태:"
if oc get clusterrolebinding self-provisioners -o yaml | grep -q "david"; then
    echo -e "${RED}    ⚠ david에게 프로젝트 생성 권한이 있습니다. 제거해야 합니다.${NC}"
    oc adm policy remove-cluster-role-from-user self-provisioner david 2>/dev/null || true
    echo "    ✓ david 프로젝트 생성 권한 제거됨"
else
    echo "    ✓ david는 프로젝트 생성 권한이 없습니다. (정상)"
fi

echo -e "${GREEN}✓ charlie와 david 권한 상태 확인 완료${NC}"
echo ""

# 5. kubeadmin 사용자 제거
echo -e "${YELLOW}[6/7] kubeadmin 사용자 제거 중...${NC}"

if oc get secrets kubeadmin -n kube-system &>/dev/null; then
    echo "  - kubeadmin secret 제거 중..."
    oc delete secrets kubeadmin -n kube-system
    echo -e "${GREEN}  ✓ kubeadmin secret 제거 완료${NC}"
else
    echo "  ✓ kubeadmin secret이 이미 제거되어 있습니다."
fi

echo -e "${GREEN}✓ kubeadmin 제거 완료${NC}"
echo ""

# 6. 권한 설정 검증
echo -e "${YELLOW}[7/7] 권한 설정 검증 중...${NC}"

echo "  - 최종 권한 상태:"

# emma 확인
if oc get clusterrolebinding | grep -q "emma.*cluster-admin"; then
    echo "    ✓ emma: cluster-admin 권한 있음"
else
    echo -e "${RED}    ✗ emma: cluster-admin 권한 없음${NC}"
fi

# alice 확인
if oc get clusterrolebinding self-provisioners -o yaml | grep -q "alice"; then
    echo "    ✓ alice: self-provisioner 권한 있음"
else
    echo -e "${RED}    ✗ alice: self-provisioner 권한 없음${NC}"
fi

# bob 확인
if oc get clusterrolebinding | grep -q "bob.*cluster-reader"; then
    echo "    ✓ bob: cluster-reader 권한 있음"
else
    echo -e "${RED}    ✗ bob: cluster-reader 권한 없음${NC}"
fi

# charlie 확인
if ! oc get clusterrolebinding | grep -q "charlie.*cluster-admin"; then
    echo "    ✓ charlie: cluster-admin 권한 없음 (정상)"
else
    echo -e "${RED}    ✗ charlie: cluster-admin 권한 있음 (문제)${NC}"
fi

# david 확인
if ! oc get clusterrolebinding self-provisioners -o yaml | grep -q "david"; then
    echo "    ✓ david: self-provisioner 권한 없음 (정상)"
else
    echo -e "${RED}    ✗ david: self-provisioner 권한 있음 (문제)${NC}"
fi

# kubeadmin 확인
if ! oc get secrets kubeadmin -n kube-system &>/dev/null; then
    echo "    ✓ kubeadmin: 제거됨"
else
    echo -e "${RED}    ✗ kubeadmin: 아직 존재함${NC}"
fi

echo -e "${GREEN}✓ 권한 설정 검증 완료${NC}"
echo ""

# 완료 메시지
echo -e "${BLUE}=========================================="
echo "RBAC 권한 설정 자동 구성 완료!"
echo "=========================================="
echo ""
echo "적용된 권한 설정:"
echo "✓ emma: cluster-admin privileges (모든 관리 작업 가능)"
echo "✓ alice: self-provisioner (새 프로젝트 생성 가능)"
echo "✓ bob: cluster-reader (클러스터 전체 리소스 조회 가능)"
echo "✓ charlie: 기본 사용자 권한 (제한된 접근)"
echo "✓ david: 기본 사용자 권한 (프로젝트 생성 불가)"
echo "✓ kubeadmin: 제거됨 (보안 강화)"
echo ""
echo "권한 테스트 방법:"
echo "1. oc login -u emma -p emma123"
echo "   oc auth can-i '*' '*' --all-namespaces"
echo ""
echo "2. oc login -u alice -p alice@123"
echo "   oc new-project alice-test"
echo ""
echo "3. oc login -u bob -p bob123"
echo "   oc get pods --all-namespaces"
echo ""
echo "실습 완료 후 './settings/cleanup-lab.sh'를 실행하여 환경을 정리하세요."
echo -e "${NC}"