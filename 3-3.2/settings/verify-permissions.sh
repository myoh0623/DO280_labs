#!/bin/bash

# DO280 Lab 3-5: 프로젝트별 권한 설정 검증 스크립트
# 설정된 프로젝트 권한이 요구사항에 맞는지 자동으로 검증

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-3.2 - 프로젝트별 권한 설정 검증"
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

# 1. 프로젝트 존재 확인
echo -e "${YELLOW}[2/6] 프로젝트 존재 확인 중...${NC}"

REQUIRED_PROJECTS=("team-alpha" "team-beta" "finance-apps" "it-automation")
PROJECTS_RESULT="PASS"

for project in "${REQUIRED_PROJECTS[@]}"; do
    if oc get project "$project" &>/dev/null; then
        echo -e "${GREEN}  ✓ 프로젝트 '$project' 존재 확인${NC}"
    else
        echo -e "${RED}  ✗ 프로젝트 '$project'이 존재하지 않음${NC}"
        PROJECTS_RESULT="FAIL"
    fi
done

# 2. alice team-beta admin 권한 확인
echo -e "${YELLOW}[3/6] alice team-beta admin 권한 확인 중...${NC}"

if oc get rolebinding -n team-beta | grep -q "admin.*alice"; then
    echo -e "${GREEN}  ✓ alice는 team-beta에서 admin 권한을 가지고 있습니다.${NC}"
    ALICE_RESULT="PASS"
else
    echo -e "${RED}  ✗ alice에게 team-beta admin 권한이 없습니다.${NC}"
    ALICE_RESULT="FAIL"
fi

# alice 권한 실제 테스트
echo "  - alice 권한 실제 테스트 중..."
if oc auth can-i create deployments --as=alice -n team-beta &>/dev/null && \
   oc auth can-i create rolebindings --as=alice -n team-beta &>/dev/null; then
    echo -e "${GREEN}    ✓ alice admin 권한 동작 확인${NC}"
else
    echo -e "${RED}    ✗ alice admin 권한이 제대로 동작하지 않음${NC}"
    ALICE_RESULT="FAIL"
fi

# 3. charlie finance-apps view 권한 확인
echo -e "${YELLOW}[4/6] charlie finance-apps view 권한 확인 중...${NC}"

if oc get rolebinding -n finance-apps | grep -q "view.*charlie"; then
    echo -e "${GREEN}  ✓ charlie는 finance-apps에서 view 권한을 가지고 있습니다.${NC}"
    CHARLIE_RESULT="PASS"
else
    echo -e "${RED}  ✗ charlie에게 finance-apps view 권한이 없습니다.${NC}"
    CHARLIE_RESULT="FAIL"
fi

# charlie 권한 실제 테스트
echo "  - charlie 권한 실제 테스트 중..."
if oc auth can-i get pods --as=charlie -n finance-apps &>/dev/null && \
   ! oc auth can-i create deployments --as=charlie -n finance-apps &>/dev/null; then
    echo -e "${GREEN}    ✓ charlie view 권한 동작 확인 (읽기 가능, 쓰기 불가)${NC}"
else
    echo -e "${RED}    ✗ charlie view 권한이 제대로 동작하지 않음${NC}"
    CHARLIE_RESULT="FAIL"
fi

# 4. david it-automation edit 권한 확인
echo -e "${YELLOW}[5/6] david it-automation edit 권한 확인 중...${NC}"

if oc get rolebinding -n it-automation | grep -q "edit.*david"; then
    echo -e "${GREEN}  ✓ david는 it-automation에서 edit 권한을 가지고 있습니다.${NC}"
    DAVID_RESULT="PASS"
else
    echo -e "${RED}  ✗ david에게 it-automation edit 권한이 없습니다.${NC}"
    DAVID_RESULT="FAIL"
fi

# david 권한 실제 테스트
echo "  - david 권한 실제 테스트 중..."
if oc auth can-i create deployments --as=david -n it-automation &>/dev/null && \
   ! oc auth can-i create rolebindings --as=david -n it-automation &>/dev/null; then
    echo -e "${GREEN}    ✓ david edit 권한 동작 확인 (앱 관리 가능, 역할 관리 불가)${NC}"
else
    echo -e "${RED}    ✗ david edit 권한이 제대로 동작하지 않음${NC}"
    DAVID_RESULT="FAIL"
fi

# 5. 추가 검증 - 다른 프로젝트 접근 제한 확인
echo -e "${YELLOW}[6/6] 프로젝트 간 접근 제한 확인 중...${NC}"

echo "  - 사용자별 다른 프로젝트 접근 제한 확인:"

# alice가 다른 프로젝트에 접근할 수 없는지 확인
if ! oc auth can-i get pods --as=alice -n finance-apps &>/dev/null; then
    echo -e "${GREEN}    ✓ alice는 finance-apps에 접근할 수 없음 (정상)${NC}"
    ACCESS_CONTROL_RESULT="PASS"
else
    echo -e "${RED}    ✗ alice가 finance-apps에 접근 가능 (문제)${NC}"
    ACCESS_CONTROL_RESULT="FAIL"
fi

# charlie가 다른 프로젝트에 접근할 수 없는지 확인
if ! oc auth can-i get pods --as=charlie -n team-beta &>/dev/null; then
    echo -e "${GREEN}    ✓ charlie는 team-beta에 접근할 수 없음 (정상)${NC}"
else
    echo -e "${RED}    ✗ charlie가 team-beta에 접근 가능 (문제)${NC}"
    ACCESS_CONTROL_RESULT="FAIL"
fi

# david가 다른 프로젝트에 접근할 수 없는지 확인
if ! oc auth can-i get pods --as=david -n team-alpha &>/dev/null; then
    echo -e "${GREEN}    ✓ david는 team-alpha에 접근할 수 없음 (정상)${NC}"
else
    echo -e "${RED}    ✗ david가 team-alpha에 접근 가능 (문제)${NC}"
    ACCESS_CONTROL_RESULT="FAIL"
fi

echo ""

# 전체 결과 요약
echo -e "${BLUE}=========================================="
echo "프로젝트별 권한 검증 결과 요약"
echo "=========================================="
echo ""

# 결과 표시
echo "요구사항별 검증 결과:"
echo ""

if [ "$PROJECTS_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ 모든 필수 프로젝트 존재 (team-alpha, team-beta, finance-apps, it-automation)${NC}"
else
    echo -e "${RED}✗ 일부 프로젝트가 존재하지 않음${NC}"
fi

if [ "$ALICE_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ alice: team-beta 프로젝트 관리자 권한${NC}"
else
    echo -e "${RED}✗ alice: team-beta 관리자 권한 설정 문제${NC}"
fi

if [ "$CHARLIE_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ charlie: finance-apps 조회 권한 (수정/삭제 불가)${NC}"
else
    echo -e "${RED}✗ charlie: finance-apps 조회 권한 설정 문제${NC}"
fi

if [ "$DAVID_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ david: it-automation 편집 권한 (역할 관리 제외)${NC}"
else
    echo -e "${RED}✗ david: it-automation 편집 권한 설정 문제${NC}"
fi

if [ "$ACCESS_CONTROL_RESULT" = "PASS" ]; then
    echo -e "${GREEN}✓ 프로젝트 간 접근 제한 정상 동작${NC}"
else
    echo -e "${RED}✗ 프로젝트 간 접근 제한 문제${NC}"
fi

echo ""

# 성공/실패 개수 계산
PASS_COUNT=0
FAIL_COUNT=0

for result in "$PROJECTS_RESULT" "$ALICE_RESULT" "$CHARLIE_RESULT" "$DAVID_RESULT" "$ACCESS_CONTROL_RESULT"; do
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
echo "1. 프로젝트 확인: oc get projects | grep -E 'team-alpha|team-beta|finance-apps|it-automation'"
echo "2. 권한 바인딩 확인: oc get rolebindings -n <project-name>"
echo "3. 사용자별 권한 테스트: oc auth can-i <verb> <resource> --as=<user> -n <project>"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 모든 프로젝트 권한 요구사항이 올바르게 구성되었습니다!${NC}"
    exit 0
else
    echo -e "${RED}⚠ 일부 권한 설정이 요구사항과 맞지 않습니다.${NC}"
    echo "다음 명령으로 권한을 다시 설정해보세요:"
    echo "./settings/auto-configure.sh"
    exit 1
fi

echo -e "${NC}"