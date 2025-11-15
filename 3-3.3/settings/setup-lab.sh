#!/bin/bash

# DO280 Lab 3-3.3: 그룹 기반 권한 관리 실습 환경 설정 스크립트
# 그룹 생성 및 권한 관리를 위한 초기 환경 준비

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-3.3 - 그룹 기반 권한 관리 실습 환경 구성"
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

# 3. 기존 그룹 상태 확인
echo -e "${YELLOW}[3/5] 기존 그룹 상태 확인 중...${NC}"

TARGET_GROUPS=("manager" "project-admin")

echo "  - 그룹 상태 확인:"
for group in "${TARGET_GROUPS[@]}"; do
    if oc get group "$group" &>/dev/null; then
        echo -e "${YELLOW}    ⚠ 그룹 '$group'이 이미 존재합니다.${NC}"
        EXISTING_USERS=$(oc get group "$group" -o jsonpath='{.users[*]}' 2>/dev/null || echo "")
        if [ ! -z "$EXISTING_USERS" ]; then
            echo "      기존 멤버: $EXISTING_USERS"
        fi
    else
        echo "    ✓ 그룹 '$group' 생성 대기 중"
    fi
done

echo -e "${GREEN}✓ 그룹 상태 확인 완료${NC}"
echo ""

# 4. team-alpha 프로젝트 상태 확인
echo -e "${YELLOW}[4/5] team-alpha 프로젝트 상태 확인 중...${NC}"

if oc get project team-alpha &>/dev/null; then
    echo "  ✓ team-alpha 프로젝트가 이미 존재합니다."
    
    # 기존 RoleBinding 확인
    if oc get rolebindings -n team-alpha | grep -E "(manager|project-admin)" &>/dev/null; then
        echo -e "${YELLOW}    ⚠ team-alpha에 기존 그룹 권한이 설정되어 있습니다.${NC}"
        oc get rolebindings -n team-alpha | grep -E "(manager|project-admin)" || true
    fi
else
    echo "  - team-alpha 프로젝트 생성 대기 중"
fi

echo -e "${GREEN}✓ team-alpha 프로젝트 상태 확인 완료${NC}"
echo ""

# 5. 현재 권한 상태 백업
echo -e "${YELLOW}[5/5] 현재 상태 백업 중...${NC}"

cd "$LAB_DIR"

# 기존 그룹 정보 백업
oc get groups -o yaml > groups-backup.yaml 2>/dev/null || echo "groups: []" > groups-backup.yaml

# team-alpha RoleBinding 백업 (존재하는 경우)
if oc get project team-alpha &>/dev/null; then
    oc get rolebindings -n team-alpha -o yaml > team-alpha-rolebindings-backup.yaml 2>/dev/null || true
fi

echo -e "${GREEN}✓ 현재 상태 백업 완료${NC}"
echo ""

# 실습 안내 메시지
echo -e "${BLUE}=========================================="
echo "그룹 기반 권한 관리 실습 준비가 완료되었습니다!"
echo "=========================================="
echo ""
echo "생성할 그룹과 멤버십:"
echo "✓ manager 그룹 → alice"
echo "✓ project-admin 그룹 → charlie, david"
echo ""
echo "프로젝트 권한 설정:"
echo "✓ manager 그룹 → team-alpha edit 권한"
echo "✓ project-admin 그룹 → team-alpha view 권한"
echo ""
echo "다음 단계를 수행하세요:"
echo ""
echo "1. 그룹 생성:"
echo "   oc adm groups new manager"
echo "   oc adm groups new project-admin"
echo ""
echo "2. 사용자를 그룹에 추가:"
echo "   oc adm groups add-users manager alice"
echo "   oc adm groups add-users project-admin charlie david"
echo ""
echo "3. 프로젝트 생성 (필요한 경우):"
echo "   oc new-project team-alpha --display-name='Team Alpha Development'"
echo ""
echo "4. 그룹별 프로젝트 권한 부여:"
echo "   oc policy add-role-to-group edit manager -n team-alpha"
echo "   oc policy add-role-to-group view project-admin -n team-alpha"
echo ""
echo "5. 자동 구성 옵션:"
echo "   ./settings/auto-configure.sh"
echo ""
echo "6. Web Console 사용 방법:"
echo "   - Administrator View → User Management → Groups"
echo "   - 자세한 내용은 README.md 참조"
echo ""
echo "실습 완료 후 './settings/cleanup-lab.sh'를 실행하여 환경을 정리하세요."
echo -e "${NC}"

echo -e "${GREEN}✓ 실습 환경 설정 완료${NC}"