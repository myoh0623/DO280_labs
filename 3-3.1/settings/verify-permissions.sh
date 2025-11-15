#!/bin/bash

# DO280 Lab 3-3: RBAC 권한 검증 스크립트
# 설정된 권한이 요구사항에 맞는지 자동으로 검증

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-3.1 - RBAC 권한 설정 검증"
echo "=========================================="
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 사전 조건 확인
echo -e "${YELLOW}[1/6] 사전 조건 확인 중...${NC}"

if ! oc whoami &>/dev/null; then
    echo -e "${RED}✗ OpenShift 클러스터에 로그인되어 있지 않습니다.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 현재 사용자: $(oc whoami)${NC}"
echo ""

# 1. emma 권한 검증 (cluster-admin)
echo -e "${YELLOW}[2/6] emma 권한 검증 중...${NC}"

if oc get clusterrolebinding | grep -q "emma.*cluster-admin"; then
    echo -e "${GREEN}  ✓ emma는 cluster-admin 권한을 가지고 있습니다.${NC}"
    EMMA_RESULT="PASS"
else
    echo -e "${RED}  ✗ emma에게 cluster-admin 권한이 없습니다.${NC}"
    EMMA_RESULT="FAIL"
fi

# 2. alice 권한 검증 (self-provisioner)
echo -e "${YELLOW}[3/6] alice 권한 검증 중...${NC}"

if oc get clusterrolebinding self-provisioners -o yaml | grep -q "alice"; then
    echo -e "${GREEN}  ✓ alice는 프로젝트 생성 권한을 가지고 있습니다.${NC}"
    ALICE_RESULT="PASS"
else
    echo -e "${RED}  ✗ alice에게 프로젝트 생성 권한이 없습니다.${NC}"
    ALICE_RESULT="FAIL"
fi

# 3. bob 권한 검증 (cluster-reader)
echo -e "${YELLOW}[4/6] bob 권한 검증 중...${NC}"

if oc get clusterrolebinding | grep -q "bob.*cluster-reader"; then
    echo -e "${GREEN}  ✓ bob은 cluster-reader 권한을 가지고 있습니다.${NC}"
    BOB_RESULT="PASS"
else
    echo -e "${RED}  ✗ bob에게 cluster-reader 권한이 없습니다.${NC}"
    BOB_RESULT="FAIL"
fi

# 4. charlie 권한 검증 (cluster-admin 권한 없음)
echo -e "${YELLOW}[5/6] charlie 권한 검증 중...${NC}"

if ! oc get clusterrolebinding | grep -q "charlie.*cluster-admin"; then
    echo -e "${GREEN}  ✓ charlie는 cluster-admin 권한이 없습니다. (정상)${NC}"
    CHARLIE_RESULT="PASS"
else
    echo -e "${RED}  ✗ charlie에게 cluster-admin 권한이 있습니다. (문제)${NC}"
    CHARLIE_RESULT="FAIL"
fi

# 5. david 권한 검증 (프로젝트 생성 권한 없음)
echo -e "${YELLOW}[6/6] david 권한 검증 중...${NC}"

if ! oc get clusterrolebinding self-provisioners -o yaml | grep -q "david"; then
    echo -e "${GREEN}  ✓ david는 프로젝트 생성 권한이 없습니다. (정상)${NC}"
    DAVID_RESULT="PASS"
else
    echo -e "${RED}  ✗ david에게 프로젝트 생성 권한이 있습니다. (문제)${NC}"
    DAVID_RESULT="FAIL"
fi

# 6. kubeadmin 상태 검증
echo -e "${YELLOW}추가 검증: kubeadmin 상태 확인 중...${NC}"

if ! oc get secrets kubeadmin -n kube-system &>/dev/null; then
    echo -e "${GREEN}  ✓ kubeadmin이 제거되었습니다. (보안 강화)${NC}"
    KUBEADMIN_RESULT="PASS"
else
    echo -e "${YELLOW}  ⚠ kubeadmin이 아직 존재합니다.${NC}"
    KUBEADMIN_RESULT="WARNING"
fi

echo ""

# 전체 결과 요약
echo -e "${BLUE}=========================================="
echo "권한 검증 결과 요약"
echo "=========================================="
echo ""

# 결과 표시
echo "요구사항별 검증 결과:"
echo ""

if [ "$EMMA_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ emma: cluster-admin privileges${NC}"
else
    echo -e "${RED}✗ emma: cluster-admin privileges${NC}"
fi

if [ "$ALICE_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ alice: 새 프로젝트 생성 권한${NC}"
else
    echo -e "${RED}✗ alice: 새 프로젝트 생성 권한${NC}"
fi

if [ "$BOB_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ bob: cluster-reader 권한${NC}"
else
    echo -e "${RED}✗ bob: cluster-reader 권한${NC}"
fi

if [ "$CHARLIE_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ charlie: cluster-admin 권한 없음${NC}"
else
    echo -e "${RED}✗ charlie: cluster-admin 권한 있음 (문제)${NC}"
fi

if [ "$DAVID_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ david: 프로젝트 생성 권한 없음${NC}"
else
    echo -e "${RED}✗ david: 프로젝트 생성 권한 있음 (문제)${NC}"
fi

if [ "$KUBEADMIN_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ kubeadmin: 제거됨${NC}"
elif [ "$KUBEADMIN_RESULT" = "WARNING" ]; then
    echo -e "${YELLOW}⚠ kubeadmin: 아직 존재함${NC}"
fi

echo ""

# 성공/실패 개수 계산
PASS_COUNT=0
FAIL_COUNT=0

for result in "$EMMA_RESULT" "$ALICE_RESULT" "$BOB_RESULT" "$CHARLIE_RESULT" "$DAVID_RESULT"; do
    if [ "$result" = "PASS" ]; then
        ((PASS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
done

echo -e "검증 통계: ${GREEN}성공 $PASS_COUNT개${NC}, ${RED}실패 $FAIL_COUNT개${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 모든 RBAC 권한 요구사항이 올바르게 구성되었습니다!${NC}"
    exit 0
else
    echo -e "${RED}⚠ 일부 권한 설정이 요구사항과 맞지 않습니다.${NC}"
    echo "다음 명령으로 권한을 다시 설정해보세요:"
    echo "./settings/auto-configure.sh"
    exit 1
fi

echo -e "${NC}"