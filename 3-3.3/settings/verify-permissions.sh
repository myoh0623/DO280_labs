#!/bin/bash

# DO280 Lab 3-7: 그룹 기반 권한 설정 검증 스크립트
# 그룹과 권한 설정이 요구사항에 맞는지 자동으로 검증

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-3.3 - 그룹 기반 권한 설정 검증"
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

# emma로 전환 (검증을 위한 관리자 권한 필요)
CURRENT_USER=$(oc whoami)
if [[ "$CURRENT_USER" != "emma" ]]; then
    echo "  - emma 사용자로 전환 중... (검증을 위한 관리자 권한 필요)"
    if ! oc login -u emma -p emma123 &>/dev/null; then
        echo -e "${RED}✗ emma 사용자로 로그인할 수 없습니다.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ 현재 사용자: $(oc whoami)${NC}"
echo ""

# 1. 그룹 존재 확인
echo -e "${YELLOW}[2/7] 그룹 존재 확인 중...${NC}"

REQUIRED_GROUPS=("manager" "project-admin")
GROUPS_RESULT="PASS"

for group in "${REQUIRED_GROUPS[@]}"; do
    if oc get group "$group" &>/dev/null; then
        echo -e "${GREEN}  ✓ 그룹 '$group' 존재 확인${NC}"
    else
        echo -e "${RED}  ✗ 그룹 '$group'이 존재하지 않음${NC}"
        GROUPS_RESULT="FAIL"
    fi
done

# 2. 그룹 멤버십 확인
echo -e "${YELLOW}[3/7] 그룹 멤버십 확인 중...${NC}"

# alice가 manager 그룹에 속하는지 확인
if oc get group manager -o jsonpath='{.users[*]}' | grep -q "alice"; then
    echo -e "${GREEN}  ✓ alice는 manager 그룹의 멤버입니다.${NC}"
    ALICE_GROUP_RESULT="PASS"
else
    echo -e "${RED}  ✗ alice가 manager 그룹에 속하지 않습니다.${NC}"
    ALICE_GROUP_RESULT="FAIL"
fi

# charlie가 project-admin 그룹에 속하는지 확인
if oc get group project-admin -o jsonpath='{.users[*]}' | grep -q "charlie"; then
    echo -e "${GREEN}  ✓ charlie는 project-admin 그룹의 멤버입니다.${NC}"
    CHARLIE_GROUP_RESULT="PASS"
else
    echo -e "${RED}  ✗ charlie가 project-admin 그룹에 속하지 않습니다.${NC}"
    CHARLIE_GROUP_RESULT="FAIL"
fi

# david가 project-admin 그룹에 속하는지 확인
if oc get group project-admin -o jsonpath='{.users[*]}' | grep -q "david"; then
    echo -e "${GREEN}  ✓ david는 project-admin 그룹의 멤버입니다.${NC}"
    DAVID_GROUP_RESULT="PASS"
else
    echo -e "${RED}  ✗ david가 project-admin 그룹에 속하지 않습니다.${NC}"
    DAVID_GROUP_RESULT="FAIL"
fi

# 3. team-alpha 프로젝트 존재 확인
echo -e "${YELLOW}[4/7] team-alpha 프로젝트 확인 중...${NC}"

if oc get project team-alpha &>/dev/null; then
    echo -e "${GREEN}  ✓ team-alpha 프로젝트가 존재합니다.${NC}"
    PROJECT_RESULT="PASS"
else
    echo -e "${RED}  ✗ team-alpha 프로젝트가 존재하지 않습니다.${NC}"
    PROJECT_RESULT="FAIL"
fi

# 4. 그룹별 프로젝트 권한 확인
echo -e "${YELLOW}[5/7] 그룹별 프로젝트 권한 확인 중...${NC}"

# manager 그룹의 edit 권한 확인
if oc get rolebinding -n team-alpha -o yaml | grep -A 10 -B 10 "manager" | grep -q "edit"; then
    echo -e "${GREEN}  ✓ manager 그룹이 team-alpha에서 edit 권한을 가지고 있습니다.${NC}"
    MANAGER_PERMISSION_RESULT="PASS"
else
    echo -e "${RED}  ✗ manager 그룹에게 team-alpha edit 권한이 없습니다.${NC}"
    MANAGER_PERMISSION_RESULT="FAIL"
fi

# project-admin 그룹의 view 권한 확인
if oc get rolebinding -n team-alpha -o yaml | grep -A 10 -B 10 "project-admin" | grep -q "view"; then
    echo -e "${GREEN}  ✓ project-admin 그룹이 team-alpha에서 view 권한을 가지고 있습니다.${NC}"
    PROJECT_ADMIN_PERMISSION_RESULT="PASS"
else
    echo -e "${RED}  ✗ project-admin 그룹에게 team-alpha view 권한이 없습니다.${NC}"
    PROJECT_ADMIN_PERMISSION_RESULT="FAIL"
fi

# 5. 실제 권한 동작 테스트
echo -e "${YELLOW}[6/7] 실제 권한 동작 테스트 중...${NC}"

# alice 권한 테스트 (manager 그룹을 통한 edit 권한)
echo "  - alice 권한 테스트 중..."
if oc auth can-i create deployments --as=alice -n team-alpha &>/dev/null && \
   oc auth can-i get pods --as=alice -n team-alpha &>/dev/null; then
    echo -e "${GREEN}    ✓ alice edit 권한 동작 확인 (앱 생성/조회 가능)${NC}"
    ALICE_ACCESS_RESULT="PASS"
else
    echo -e "${RED}    ✗ alice edit 권한이 제대로 동작하지 않음${NC}"
    ALICE_ACCESS_RESULT="FAIL"
fi

# charlie 권한 테스트 (project-admin 그룹을 통한 view 권한)
echo "  - charlie 권한 테스트 중..."
if oc auth can-i get pods --as=charlie -n team-alpha &>/dev/null && \
   ! oc auth can-i create deployments --as=charlie -n team-alpha &>/dev/null; then
    echo -e "${GREEN}    ✓ charlie view 권한 동작 확인 (조회 가능, 생성 불가)${NC}"
    CHARLIE_ACCESS_RESULT="PASS"
else
    echo -e "${RED}    ✗ charlie view 권한이 제대로 동작하지 않음${NC}"
    CHARLIE_ACCESS_RESULT="FAIL"
fi

# david 권한 테스트 (project-admin 그룹을 통한 view 권한)
echo "  - david 권한 테스트 중..."
if oc auth can-i get pods --as=david -n team-alpha &>/dev/null && \
   ! oc auth can-i create deployments --as=david -n team-alpha &>/dev/null; then
    echo -e "${GREEN}    ✓ david view 권한 동작 확인 (조회 가능, 생성 불가)${NC}"
    DAVID_ACCESS_RESULT="PASS"
else
    echo -e "${RED}    ✗ david view 권한이 제대로 동작하지 않음${NC}"
    DAVID_ACCESS_RESULT="FAIL"
fi

# 6. 그룹 구성 세부 정보 확인
echo -e "${YELLOW}[7/7] 그룹 구성 세부 정보 확인 중...${NC}"

echo "  - 그룹별 멤버 목록:"
if oc get group manager &>/dev/null; then
    MANAGER_MEMBERS=$(oc get group manager -o jsonpath='{.users[*]}' 2>/dev/null || echo "")
    echo -e "${BLUE}    manager: $MANAGER_MEMBERS${NC}"
fi

if oc get group project-admin &>/dev/null; then
    PROJECT_ADMIN_MEMBERS=$(oc get group project-admin -o jsonpath='{.users[*]}' 2>/dev/null || echo "")
    echo -e "${BLUE}    project-admin: $PROJECT_ADMIN_MEMBERS${NC}"
fi

echo "  - team-alpha 프로젝트 RoleBinding:"
if oc get project team-alpha &>/dev/null; then
    oc get rolebindings -n team-alpha | grep -E "(manager|project-admin)" 2>/dev/null || echo "    관련 RoleBinding 없음"
fi

echo ""

# 전체 결과 요약
echo -e "${BLUE}=========================================="
echo "그룹 기반 권한 검증 결과 요약"
echo "=========================================="
echo ""

# 결과 표시
echo "요구사항별 검증 결과:"
echo ""

if [ "$GROUPS_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ 필수 그룹 존재 (manager, project-admin)${NC}"
else
    echo -e "${RED}✗ 일부 그룹이 존재하지 않음${NC}"
fi

if [ "$ALICE_GROUP_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ alice: manager 그룹 멤버${NC}"
else
    echo -e "${RED}✗ alice: manager 그룹 멤버 설정 문제${NC}"
fi

if [ "$CHARLIE_GROUP_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ charlie: project-admin 그룹 멤버${NC}"
else
    echo -e "${RED}✗ charlie: project-admin 그룹 멤버 설정 문제${NC}"
fi

if [ "$DAVID_GROUP_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ david: project-admin 그룹 멤버${NC}"
else
    echo -e "${RED}✗ david: project-admin 그룹 멤버 설정 문제${NC}"
fi

if [ "$PROJECT_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ team-alpha 프로젝트 존재${NC}"
else
    echo -e "${RED}✗ team-alpha 프로젝트 없음${NC}"
fi

if [ "$MANAGER_PERMISSION_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ manager 그룹: team-alpha edit 권한${NC}"
else
    echo -e "${RED}✗ manager 그룹: team-alpha edit 권한 설정 문제${NC}"
fi

if [ "$PROJECT_ADMIN_PERMISSION_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ project-admin 그룹: team-alpha view 권한${NC}"
else
    echo -e "${RED}✗ project-admin 그룹: team-alpha view 권한 설정 문제${NC}"
fi

if [ "$ALICE_ACCESS_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ alice: 실제 edit 권한 동작 정상${NC}"
else
    echo -e "${RED}✗ alice: 실제 edit 권한 동작 문제${NC}"
fi

if [ "$CHARLIE_ACCESS_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ charlie: 실제 view 권한 동작 정상${NC}"
else
    echo -e "${RED}✗ charlie: 실제 view 권한 동작 문제${NC}"
fi

if [ "$DAVID_ACCESS_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ david: 실제 view 권한 동작 정상${NC}"
else
    echo -e "${RED}✗ david: 실제 view 권한 동작 문제${NC}"
fi

echo ""

# 성공/실패 개수 계산
PASS_COUNT=0
FAIL_COUNT=0

for result in "$GROUPS_RESULT" "$ALICE_GROUP_RESULT" "$CHARLIE_GROUP_RESULT" "$DAVID_GROUP_RESULT" \
              "$PROJECT_RESULT" "$MANAGER_PERMISSION_RESULT" "$PROJECT_ADMIN_PERMISSION_RESULT" \
              "$ALICE_ACCESS_RESULT" "$CHARLIE_ACCESS_RESULT" "$DAVID_ACCESS_RESULT"; do
    if [ "$result" = "PASS" ]; then
        ((PASS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
done

echo -e "검증 통계: ${GREEN}성공 $PASS_COUNT개${NC}, ${RED}실패 $FAIL_COUNT개${NC}"
echo ""

# 추가 검증 명령어 안내
echo "수동 검증 명령어:"
echo "1. 그룹 확인: oc get groups"
echo "2. 그룹 세부정보: oc describe group manager"
echo "3. 프로젝트 권한: oc get rolebindings -n team-alpha"
echo "4. 사용자별 권한 테스트: oc auth can-i <verb> <resource> --as=<user> -n team-alpha"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 모든 그룹 기반 권한 요구사항이 올바르게 구성되었습니다!${NC}"
    exit 0
else
    echo -e "${RED}⚠ 일부 그룹 권한 설정이 요구사항과 맞지 않습니다.${NC}"
    echo "다음 명령으로 권한을 다시 설정해보세요:"
    echo "./settings/auto-configure.sh"
    exit 1
fi

echo -e "${NC}"