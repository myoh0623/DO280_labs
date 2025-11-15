#!/bin/bash

# DO280 Lab 3-5: 프로젝트별 권한 관리 자동 구성 스크립트
# 모든 프로젝트 생성 및 권한 설정을 자동으로 수행

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-3.2 - 프로젝트별 권한 관리 자동 구성"
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
    echo "    (프로젝트 생성을 위한 cluster-admin 권한 필요)"
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

# 1. 프로젝트 생성
echo -e "${YELLOW}[2/6] 프로젝트 생성 중...${NC}"

# 프로젝트 정보 배열
declare -A PROJECTS=(
    ["team-alpha"]="Team Alpha Development"
    ["team-beta"]="Team Beta Development"
    ["finance-apps"]="Finance Applications"
    ["it-automation"]="IT Automation"
)

for project in "${!PROJECTS[@]}"; do
    if oc get project "$project" &>/dev/null; then
        echo "  ⚠ 프로젝트 '$project'가 이미 존재합니다."
    else
        oc new-project "$project" --display-name="${PROJECTS[$project]}" &>/dev/null
        echo "  ✓ 프로젝트 '$project' 생성됨"
    fi
done

echo -e "${GREEN}✓ 프로젝트 생성 완료${NC}"
echo ""

# 2. alice에게 team-beta admin 권한 부여
echo -e "${YELLOW}[3/6] alice에게 team-beta 관리자 권한 부여 중...${NC}"

oc policy add-role-to-user admin alice -n team-beta

echo -e "${GREEN}✓ alice team-beta admin 권한 부여 완료${NC}"
echo "  - alice는 team-beta 프로젝트의 모든 리소스를 관리할 수 있습니다."
echo ""

# 3. charlie에게 finance-apps view 권한 부여
echo -e "${YELLOW}[4/6] charlie에게 finance-apps 조회 권한 부여 중...${NC}"

oc policy add-role-to-user view charlie -n finance-apps

echo -e "${GREEN}✓ charlie finance-apps view 권한 부여 완료${NC}"
echo "  - charlie는 finance-apps 프로젝트의 리소스를 조회할 수 있습니다."
echo ""

# 4. david에게 it-automation edit 권한 부여
echo -e "${YELLOW}[5/6] david에게 it-automation 편집 권한 부여 중...${NC}"

oc policy add-role-to-user edit david -n it-automation

echo -e "${GREEN}✓ david it-automation edit 권한 부여 완료${NC}"
echo "  - david는 it-automation 프로젝트의 애플리케이션을 관리할 수 있습니다."
echo "  - 단, 역할 및 권한 관리는 불가능합니다."
echo ""

# 5. 샘플 애플리케이션 배포 (검증용)
echo -e "${YELLOW}[6/6] 샘플 애플리케이션 배포 중...${NC}"

# team-alpha에 샘플 앱
oc project team-alpha &>/dev/null
if ! oc get deployment alpha-app &>/dev/null; then
    oc new-app --name=alpha-app --image=nginx &>/dev/null
    echo "  ✓ team-alpha에 샘플 애플리케이션 배포됨"
fi

# team-beta에 샘플 앱
oc project team-beta &>/dev/null
if ! oc get deployment beta-app &>/dev/null; then
    oc new-app --name=beta-app --image=httpd &>/dev/null
    echo "  ✓ team-beta에 샘플 애플리케이션 배포됨"
fi

# finance-apps에 샘플 앱
oc project finance-apps &>/dev/null
if ! oc get deployment finance-app &>/dev/null; then
    oc new-app --name=finance-app --image=nginx &>/dev/null
    echo "  ✓ finance-apps에 샘플 애플리케이션 배포됨"
fi

# it-automation에 샘플 앱
oc project it-automation &>/dev/null
if ! oc get deployment automation-app &>/dev/null; then
    oc new-app --name=automation-app --image=httpd &>/dev/null
    echo "  ✓ it-automation에 샘플 애플리케이션 배포됨"
fi

echo -e "${GREEN}✓ 샘플 애플리케이션 배포 완료${NC}"
echo ""

# 완료 메시지
echo -e "${BLUE}=========================================="
echo "프로젝트별 권한 관리 자동 구성 완료!"
echo "=========================================="
echo ""
echo "생성된 프로젝트와 권한:"
echo "✓ team-alpha: 개발팀 알파 프로젝트 (샘플 앱 배포됨)"
echo "✓ team-beta: 개발팀 베타 프로젝트 (alice → admin, 샘플 앱 배포됨)"
echo "✓ finance-apps: 재무 애플리케이션 (charlie → view, 샘플 앱 배포됨)"
echo "✓ it-automation: IT 자동화 (david → edit, 샘플 앱 배포됨)"
echo ""
echo "권한 설정 상세:"
echo "- alice: team-beta 프로젝트 관리자 (모든 작업 가능)"
echo "- charlie: finance-apps 조회 권한만 (읽기 전용)"
echo "- david: it-automation 편집 권한 (앱 관리 가능, 역할 관리 불가)"
echo ""
echo "권한 테스트 방법:"
echo ""
echo "1. alice 권한 테스트 (team-beta admin):"
echo "   oc login -u alice -p alice@123"
echo "   oc project team-beta"
echo "   oc scale deployment beta-app --replicas=3"
echo "   oc policy add-role-to-user view bob -n team-beta"
echo ""
echo "2. charlie 권한 테스트 (finance-apps view):"
echo "   oc login -u charlie -p charlie@123"
echo "   oc project finance-apps"
echo "   oc get all  # 성공해야 함"
echo "   oc scale deployment finance-app --replicas=2  # 실패해야 함"
echo ""
echo "3. david 권한 테스트 (it-automation edit):"
echo "   oc login -u david -p david@123"
echo "   oc project it-automation"
echo "   oc scale deployment automation-app --replicas=2  # 성공해야 함"
echo "   oc policy add-role-to-user view alice -n it-automation  # 실패해야 함"
echo ""
echo "권한 검증: ./settings/verify-permissions.sh"
echo "실습 정리: ./settings/cleanup-lab.sh"
echo -e "${NC}"