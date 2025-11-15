#!/bin/bash

# DO280 Lab 3-3.1: RBAC 권한 정의 및 적용 실습 환경 설정 스크립트
# RBAC 설정을 위한 초기 환경 준비

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-3.1 - RBAC 권한 정의 및 적용 실습 환경 구성"
echo "=========================================="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. 사전 조건 확인
echo -e "${YELLOW}[1/5] 사전 조건 확인 중...${NC}"

# 클러스터 접근 확인
if ! oc whoami &>/dev/null; then
    echo -e "${RED}✗ OpenShift 클러스터에 로그인되어 있지 않습니다.${NC}"
    echo "먼저 'oc login' 명령으로 클러스터 관리자 권한으로 로그인하세요."
    exit 1
fi

# 클러스터 관리자 권한 확인
if ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
    echo -e "${RED}✗ 클러스터 관리자 권한이 필요합니다.${NC}"
    echo "cluster-admin 권한을 가진 사용자로 로그인하세요."
    exit 1
fi

echo -e "${GREEN}✓ 사전 조건 확인 완료${NC}"
echo "  - 현재 사용자: $(oc whoami)"
echo ""

# 2. 필수 사용자 존재 확인
echo -e "${YELLOW}[2/5] 필수 사용자 계정 확인 중...${NC}"

REQUIRED_USERS=("alice" "bob" "charlie" "david" "emma")
MISSING_USERS=()

for user in "${REQUIRED_USERS[@]}"; do
    if ! oc get user "$user" &>/dev/null; then
        MISSING_USERS+=("$user")
    else
        echo "  ✓ 사용자 '$user' 존재 확인"
    fi
done

if [ ${#MISSING_USERS[@]} -gt 0 ]; then
    echo -e "${RED}✗ 다음 사용자들이 존재하지 않습니다: ${MISSING_USERS[*]}${NC}"
    echo "먼저 Lab 3-1을 완료하여 HTPasswd Identity Provider와 사용자들을 생성하세요."
    exit 1
fi

echo -e "${GREEN}✓ 필수 사용자 계정 확인 완료${NC}"
echo ""

# 3. 현재 권한 상태 백업
echo -e "${YELLOW}[3/5] 현재 권한 상태 백업 중...${NC}"

cd "$LAB_DIR"

# ClusterRoleBinding 백업
oc get clusterrolebinding -o yaml > clusterrolebinding-backup.yaml

# 특정 사용자들의 권한 확인 및 백업
echo "  - 현재 사용자별 권한 상태:"
for user in "${REQUIRED_USERS[@]}"; do
    echo "    $user:"
    # cluster-admin 권한 확인
    if oc get clusterrolebinding | grep -q "$user.*cluster-admin"; then
        echo "      - cluster-admin: Yes"
    else
        echo "      - cluster-admin: No"
    fi
    
    # self-provisioner 권한 확인
    if oc get clusterrolebinding self-provisioners -o yaml | grep -q "$user"; then
        echo "      - self-provisioner: Yes"
    else
        echo "      - self-provisioner: No"
    fi
done

echo -e "${GREEN}✓ 현재 권한 상태 백업 완료${NC}"
echo ""

# 4. kubeadmin 사용자 상태 확인
echo -e "${YELLOW}[4/5] kubeadmin 사용자 상태 확인 중...${NC}"

if oc get secrets kubeadmin -n kube-system &>/dev/null; then
    echo "  ⚠ kubeadmin secret이 존재합니다."
    echo "  - 실습에서 kubeadmin을 제거할 예정입니다."
else
    echo "  ✓ kubeadmin secret이 이미 제거되어 있습니다."
fi

echo -e "${GREEN}✓ kubeadmin 상태 확인 완료${NC}"
echo ""

# 5. 실습 안내 메시지
echo -e "${YELLOW}[5/5] 실습 안내${NC}"
echo -e "${BLUE}=========================================="
echo "RBAC 권한 설정 실습 준비가 완료되었습니다!"
echo "=========================================="
echo ""
echo "권한 설정 요구사항:"
echo "✓ emma: cluster-admin privileges"
echo "✓ alice: 새 프로젝트 생성 권한"
echo "✓ charlie: cluster-admin 권한 없음 (기본)"
echo "✓ david: 프로젝트 생성 권한 없음 (기본)"
echo "✓ bob: cluster-reader 권한"
echo "✓ kubeadmin: 계정 제거"
echo ""
echo "다음 단계를 수행하세요:"
echo ""
echo "1. emma에게 cluster-admin 권한 부여:"
echo "   oc adm policy add-cluster-role-to-user cluster-admin emma"
echo ""
echo "2. alice에게 프로젝트 생성 권한 부여:"
echo "   oc adm policy add-cluster-role-to-user self-provisioner alice"
echo ""
echo "3. bob에게 cluster-reader 권한 부여:"
echo "   oc adm policy add-cluster-role-to-user cluster-reader bob"
echo ""
echo "4. kubeadmin 제거:"
echo "   oc delete secrets kubeadmin -n kube-system"
echo ""
echo "5. 자동 구성 옵션:"
echo "   ./settings/auto-configure.sh"
echo ""
echo "실습 완료 후 './settings/cleanup-lab.sh'를 실행하여 환경을 정리하세요."
echo -e "${NC}"

echo -e "${GREEN}✓ 실습 환경 설정 완료${NC}"