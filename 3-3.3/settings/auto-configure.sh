#!/bin/bash

# DO280 Lab 3-7: 그룹 기반 권한 관리 자동 구성 스크립트
# 모든 그룹 생성 및 권한 설정을 자동으로 수행

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-3.3 - 그룹 기반 권한 관리 자동 구성"
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

# emma 사용자로 전환 (cluster-admin 권한 필요)
CURRENT_USER=$(oc whoami)
if [[ "$CURRENT_USER" != "emma" ]]; then
    echo "  - emma 사용자로 전환 중..."
    echo "    (그룹 관리를 위한 cluster-admin 권한 필요)"
    if ! oc login -u emma -p emma123 &>/dev/null; then
        echo -e "${RED}✗ emma 사용자로 로그인할 수 없습니다.${NC}"
        echo "먼저 Lab 3-1과 3-3.1을 완료하세요."
        exit 1
    fi
fi

if ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
    echo -e "${RED}✗ cluster-admin 권한이 필요합니다.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 사전 조건 확인 완료${NC}"
echo "  - 현재 사용자: $(oc whoami)"
echo ""

# 1. 그룹 생성
echo -e "${YELLOW}[2/6] 그룹 생성 중...${NC}"

# manager 그룹 생성
if oc get group manager &>/dev/null; then
    echo "  ⚠ manager 그룹이 이미 존재합니다."
else
    oc adm groups new manager
    echo "  ✓ manager 그룹 생성됨"
fi

# project-admin 그룹 생성
if oc get group project-admin &>/dev/null; then
    echo "  ⚠ project-admin 그룹이 이미 존재합니다."
else
    oc adm groups new project-admin
    echo "  ✓ project-admin 그룹 생성됨"
fi

echo -e "${GREEN}✓ 그룹 생성 완료${NC}"
echo ""

# 2. 사용자를 그룹에 추가
echo -e "${YELLOW}[3/6] 사용자를 그룹에 추가 중...${NC}"

# alice를 manager 그룹에 추가
if oc get group manager -o jsonpath='{.users[*]}' | grep -q "alice"; then
    echo "  ⚠ alice가 이미 manager 그룹에 속해 있습니다."
else
    oc adm groups add-users manager alice
    echo "  ✓ alice가 manager 그룹에 추가됨"
fi

# charlie를 project-admin 그룹에 추가
if oc get group project-admin -o jsonpath='{.users[*]}' | grep -q "charlie"; then
    echo "  ⚠ charlie가 이미 project-admin 그룹에 속해 있습니다."
else
    oc adm groups add-users project-admin charlie
    echo "  ✓ charlie가 project-admin 그룹에 추가됨"
fi

# david를 project-admin 그룹에 추가
if oc get group project-admin -o jsonpath='{.users[*]}' | grep -q "david"; then
    echo "  ⚠ david가 이미 project-admin 그룹에 속해 있습니다."
else
    oc adm groups add-users project-admin david
    echo "  ✓ david가 project-admin 그룹에 추가됨"
fi

echo -e "${GREEN}✓ 사용자 그룹 할당 완료${NC}"
echo ""

# 3. team-alpha 프로젝트 생성 (필요한 경우)
echo -e "${YELLOW}[4/6] team-alpha 프로젝트 확인 중...${NC}"

if oc get project team-alpha &>/dev/null; then
    echo "  ✓ team-alpha 프로젝트가 이미 존재합니다."
else
    oc new-project team-alpha --display-name="Team Alpha Development" &>/dev/null
    echo "  ✓ team-alpha 프로젝트 생성됨"
fi

echo -e "${GREEN}✓ team-alpha 프로젝트 확인 완료${NC}"
echo ""

# 4. 그룹별 프로젝트 권한 부여
echo -e "${YELLOW}[5/6] 그룹별 프로젝트 권한 부여 중...${NC}"

# manager 그룹에 team-alpha edit 권한 부여
if oc get rolebinding -n team-alpha | grep -q "manager.*edit"; then
    echo "  ⚠ manager 그룹이 이미 team-alpha에서 edit 권한을 가지고 있습니다."
else
    oc policy add-role-to-group edit manager -n team-alpha
    echo "  ✓ manager 그룹에 team-alpha edit 권한 부여됨"
fi

# project-admin 그룹에 team-alpha view 권한 부여
if oc get rolebinding -n team-alpha | grep -q "project-admin.*view"; then
    echo "  ⚠ project-admin 그룹이 이미 team-alpha에서 view 권한을 가지고 있습니다."
else
    oc policy add-role-to-group view project-admin -n team-alpha
    echo "  ✓ project-admin 그룹에 team-alpha view 권한 부여됨"
fi

echo -e "${GREEN}✓ 그룹별 프로젝트 권한 부여 완료${NC}"
echo ""

# 5. 샘플 애플리케이션 배포 (테스트용)
echo -e "${YELLOW}[6/6] 테스트용 샘플 애플리케이션 배포 중...${NC}"

oc project team-alpha &>/dev/null

if ! oc get deployment team-alpha-app &>/dev/null; then
    oc new-app --name=team-alpha-app --image=nginx &>/dev/null
    echo "  ✓ team-alpha에 샘플 애플리케이션 배포됨"
else
    echo "  ⚠ team-alpha에 샘플 애플리케이션이 이미 존재합니다."
fi

echo -e "${GREEN}✓ 테스트 환경 구성 완료${NC}"
echo ""

# 완료 메시지
echo -e "${BLUE}=========================================="
echo "그룹 기반 권한 관리 자동 구성 완료!"
echo "=========================================="
echo ""
echo "생성된 그룹과 멤버십:"
echo "✓ manager 그룹: alice"
echo "✓ project-admin 그룹: charlie, david"
echo ""
echo "프로젝트 권한 설정:"
echo "✓ manager 그룹: team-alpha edit 권한 (앱 관리 가능)"
echo "✓ project-admin 그룹: team-alpha view 권한 (읽기 전용)"
echo ""
echo "생성된 리소스:"
echo "✓ team-alpha 프로젝트 (샘플 앱 포함)"
echo "✓ 그룹별 RoleBinding 설정"
echo ""
echo "권한 테스트 방법:"
echo ""
echo "1. alice 권한 테스트 (manager 그룹, edit 권한):"
echo "   oc login -u alice -p alice@123"
echo "   oc project team-alpha"
echo "   oc create deployment test-alice --image=httpd  # 성공해야 함"
echo "   oc scale deployment team-alpha-app --replicas=3  # 성공해야 함"
echo ""
echo "2. charlie 권한 테스트 (project-admin 그룹, view 권한):"
echo "   oc login -u charlie -p charlie@123"
echo "   oc project team-alpha"
echo "   oc get all  # 성공해야 함"
echo "   oc create deployment test-charlie --image=nginx  # 실패해야 함"
echo ""
echo "3. david 권한 테스트 (project-admin 그룹, view 권한):"
echo "   oc login -u david -p david@123"
echo "   oc project team-alpha"
echo "   oc get pods  # 성공해야 함"
echo "   oc scale deployment team-alpha-app --replicas=2  # 실패해야 함"
echo ""
echo "Web Console 확인 방법:"
echo "- Administrator View → User Management → Groups"
echo "- Home → Projects → team-alpha → User Management → RoleBindings"
echo ""
echo "권한 검증: ./settings/verify-permissions.sh"
echo "실습 정리: ./settings/cleanup-lab.sh"
echo -e "${NC}"