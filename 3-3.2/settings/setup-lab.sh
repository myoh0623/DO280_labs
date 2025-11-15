#!/bin/bash

# DO280 Lab 3-3.2: 프로젝트별 권한 관리 실습 환경 설정 스크립트
# 프로젝트별 세부 권한 구성을 위한 초기 환경 준비

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-3.2 - 프로젝트별 권한 관리 실습 환경 구성"
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

# 클러스터 관리자 권한 확인 (emma 또는 다른 cluster-admin 사용자)
CURRENT_USER=$(oc whoami)
if [[ "$CURRENT_USER" == "emma" ]]; then
    if ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
        echo -e "${RED}✗ emma 사용자에게 cluster-admin 권한이 없습니다.${NC}"
        echo "먼저 Lab 3-3.1을 완료하여 emma에게 cluster-admin 권한을 부여하세요."
        exit 1
    fi
elif ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
    echo -e "${RED}✗ 클러스터 관리자 권한이 필요합니다.${NC}"
    echo "cluster-admin 권한을 가진 사용자(emma 권장)로 로그인하세요."
    exit 1
fi

echo -e "${GREEN}✓ 사전 조건 확인 완료${NC}"
echo "  - 현재 사용자: $(oc whoami)"
echo ""

# 2. 필수 사용자 존재 확인
echo -e "${YELLOW}[2/5] 필수 사용자 계정 확인 중...${NC}"

REQUIRED_USERS=("alice" "charlie" "david" "emma")
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

# 3. 기존 프로젝트 확인 및 정리
echo -e "${YELLOW}[3/5] 기존 프로젝트 상태 확인 중...${NC}"

TARGET_PROJECTS=("team-alpha" "team-beta" "finance-apps" "it-automation")

echo "  - 실습용 프로젝트 상태 확인:"
for project in "${TARGET_PROJECTS[@]}"; do
    if oc get project "$project" &>/dev/null; then
        echo -e "${YELLOW}    ⚠ 프로젝트 '$project'가 이미 존재합니다.${NC}"
    else
        echo "    ✓ 프로젝트 '$project' 생성 대기 중"
    fi
done

echo -e "${GREEN}✓ 프로젝트 상태 확인 완료${NC}"
echo ""

# 4. 현재 권한 상태 백업
echo -e "${YELLOW}[4/5] 현재 권한 상태 백업 중...${NC}"

cd "$LAB_DIR"

# 각 프로젝트의 RoleBinding 백업 (존재하는 경우)
for project in "${TARGET_PROJECTS[@]}"; do
    if oc get project "$project" &>/dev/null; then
        echo "  - 프로젝트 '$project' RoleBinding 백업 중..."
        oc get rolebindings -n "$project" -o yaml > "rolebindings-${project}-backup.yaml" 2>/dev/null || true
    fi
done

# 전체 프로젝트 목록 백업
oc get projects -o yaml > projects-backup.yaml

echo -e "${GREEN}✓ 권한 상태 백업 완료${NC}"
echo ""

# 5. 실습 안내 메시지
echo -e "${YELLOW}[5/5] 실습 안내${NC}"
echo -e "${BLUE}=========================================="
echo "프로젝트별 권한 관리 실습 준비가 완료되었습니다!"
echo "=========================================="
echo ""
echo "생성할 프로젝트와 권한:"
echo "✓ team-alpha: 개발팀 알파 프로젝트"
echo "✓ team-beta: 개발팀 베타 프로젝트 (alice → admin)"
echo "✓ finance-apps: 재무 애플리케이션 (charlie → view)"
echo "✓ it-automation: IT 자동화 (david → edit)"
echo ""
echo "권한 설정 요구사항:"
echo "- alice: team-beta 프로젝트 관리자"
echo "- charlie: finance-apps 조회 권한만"
echo "- david: it-automation 편집 권한 (역할 관리 제외)"
echo ""
echo "다음 단계를 수행하세요:"
echo ""
echo "1. 프로젝트 생성 (emma로 로그인 필요):"
echo "   oc login -u emma -p emma123"
echo "   oc new-project team-alpha --display-name='Team Alpha Development'"
echo "   oc new-project team-beta --display-name='Team Beta Development'"
echo "   oc new-project finance-apps --display-name='Finance Applications'"
echo "   oc new-project it-automation --display-name='IT Automation'"
echo ""
echo "2. 권한 부여:"
echo "   oc policy add-role-to-user admin alice -n team-beta"
echo "   oc policy add-role-to-user view charlie -n finance-apps"
echo "   oc policy add-role-to-user edit david -n it-automation"
echo ""
echo "3. 자동 구성 옵션:"
echo "   ./settings/auto-configure.sh"
echo ""
echo "4. 권한 검증:"
echo "   ./settings/verify-permissions.sh"
echo ""
echo "실습 완료 후 './settings/cleanup-lab.sh'를 실행하여 환경을 정리하세요."
echo -e "${NC}"

echo -e "${GREEN}✓ 실습 환경 설정 완료${NC}"