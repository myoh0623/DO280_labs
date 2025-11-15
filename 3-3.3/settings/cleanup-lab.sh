#!/bin/bash

# DO280 Lab 3-7 정리 스크립트
# 그룹 기반 권한 관리 실습 환경 초기화

set -e

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "DO280 Lab 3-3.3 환경 정리"
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

# emma로 전환 (그룹 삭제를 위한 관리자 권한 필요)
CURRENT_USER=$(oc whoami)
if [[ "$CURRENT_USER" != "emma" ]]; then
    echo "  - emma 사용자로 전환 중... (그룹 삭제를 위한 관리자 권한 필요)"
    if ! oc login -u emma -p emma123 &>/dev/null; then
        echo -e "${RED}✗ emma 사용자로 로그인할 수 없습니다.${NC}"
        exit 1
    fi
fi

if ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
    echo -e "${RED}✗ 클러스터 관리자 권한이 필요합니다.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 사전 조건 확인 완료${NC}"
echo "  - 현재 사용자: $(oc whoami)"
echo ""

# 1. team-alpha 프로젝트의 그룹 권한 제거
echo -e "${YELLOW}[2/6] team-alpha 프로젝트의 그룹 권한 제거 중...${NC}"

if oc get project team-alpha &>/dev/null; then
    echo "  - team-alpha 프로젝트의 그룹 RoleBinding 제거 중..."
    
    # manager 그룹 권한 제거
    if oc get rolebinding -n team-alpha | grep -q "manager"; then
        MANAGER_ROLEBINDINGS=$(oc get rolebinding -n team-alpha | grep "manager" | awk '{print $1}')
        for rb in $MANAGER_ROLEBINDINGS; do
            oc delete rolebinding "$rb" -n team-alpha 2>/dev/null || true
            echo "    ✓ RoleBinding '$rb' 삭제됨"
        done
    fi
    
    # project-admin 그룹 권한 제거
    if oc get rolebinding -n team-alpha | grep -q "project-admin"; then
        PROJECT_ADMIN_ROLEBINDINGS=$(oc get rolebinding -n team-alpha | grep "project-admin" | awk '{print $1}')
        for rb in $PROJECT_ADMIN_ROLEBINDINGS; do
            oc delete rolebinding "$rb" -n team-alpha 2>/dev/null || true
            echo "    ✓ RoleBinding '$rb' 삭제됨"
        done
    fi
    
    echo "  ✓ team-alpha 프로젝트의 그룹 권한 제거 완료"
else
    echo "  - team-alpha 프로젝트가 존재하지 않음"
fi

echo -e "${GREEN}✓ 프로젝트 그룹 권한 제거 완료${NC}"
echo ""

# 2. 그룹에서 사용자 제거
echo -e "${YELLOW}[3/6] 그룹에서 사용자 제거 중...${NC}"

# manager 그룹에서 alice 제거
if oc get group manager &>/dev/null; then
    if oc get group manager -o jsonpath='{.users[*]}' | grep -q "alice"; then
        oc adm groups remove-users manager alice 2>/dev/null || true
        echo "  ✓ alice가 manager 그룹에서 제거됨"
    else
        echo "  - alice가 manager 그룹에 속하지 않음"
    fi
fi

# project-admin 그룹에서 charlie, david 제거
if oc get group project-admin &>/dev/null; then
    CURRENT_MEMBERS=$(oc get group project-admin -o jsonpath='{.users[*]}' 2>/dev/null || echo "")
    
    if echo "$CURRENT_MEMBERS" | grep -q "charlie"; then
        oc adm groups remove-users project-admin charlie 2>/dev/null || true
        echo "  ✓ charlie가 project-admin 그룹에서 제거됨"
    else
        echo "  - charlie가 project-admin 그룹에 속하지 않음"
    fi
    
    if echo "$CURRENT_MEMBERS" | grep -q "david"; then
        oc adm groups remove-users project-admin david 2>/dev/null || true
        echo "  ✓ david가 project-admin 그룹에서 제거됨"
    else
        echo "  - david가 project-admin 그룹에 속하지 않음"
    fi
fi

echo -e "${GREEN}✓ 그룹에서 사용자 제거 완료${NC}"
echo ""

# 3. 그룹 삭제
echo -e "${YELLOW}[4/6] 그룹 삭제 중...${NC}"

TARGET_GROUPS=("manager" "project-admin")

for group in "${TARGET_GROUPS[@]}"; do
    if oc get group "$group" &>/dev/null; then
        oc delete group "$group" 2>/dev/null || true
        echo "  ✓ 그룹 '$group' 삭제됨"
    else
        echo "  - 그룹 '$group'이 이미 삭제되었거나 존재하지 않음"
    fi
done

echo -e "${GREEN}✓ 그룹 삭제 완료${NC}"
echo ""

# 4. team-alpha 프로젝트 삭제 여부 확인
echo -e "${YELLOW}[5/6] team-alpha 프로젝트 처리 중...${NC}"

if oc get project team-alpha &>/dev/null; then
    echo "  ⚠ team-alpha 프로젝트가 존재합니다."
    echo "  - 이 프로젝트는 다른 실습(3-5)에서도 사용될 수 있습니다."
    echo "  - 필요한 경우 수동으로 삭제하세요: oc delete project team-alpha"
    
    # 샘플 애플리케이션만 삭제
    if oc get deployment team-alpha-app -n team-alpha &>/dev/null; then
        oc delete deployment team-alpha-app -n team-alpha 2>/dev/null || true
        echo "  ✓ team-alpha-app 샘플 애플리케이션 삭제됨"
    fi
else
    echo "  - team-alpha 프로젝트가 존재하지 않음"
fi

echo -e "${GREEN}✓ team-alpha 프로젝트 처리 완료${NC}"
echo ""

# 5. 백업 파일 정리
echo -e "${YELLOW}[6/6] 백업 파일 정리 중...${NC}"

cd "$LAB_DIR"

# 백업 파일들 삭제
BACKUP_FILES=(
    "groups-backup.yaml"
    "team-alpha-rolebindings-backup.yaml"
)

for file in "${BACKUP_FILES[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "  ✓ $file 삭제됨"
    fi
done

echo -e "${GREEN}✓ 백업 파일 정리 완료${NC}"
echo ""

# 정리 완료 메시지
echo -e "${BLUE}=========================================="
echo "실습 환경 정리 완료!"
echo "=========================================="
echo ""
echo "다음 항목들이 정리되었습니다:"
echo "✓ 그룹 삭제 (manager, project-admin)"
echo "✓ 그룹에서 사용자 제거 (alice, charlie, david)"
echo "✓ team-alpha 프로젝트의 그룹 권한 제거"
echo "✓ 샘플 애플리케이션 제거"
echo "✓ 백업 파일 정리"
echo ""
echo "참고사항:"
echo "- 사용자 계정은 유지됩니다 (3-1 실습 결과)"
echo "- team-alpha 프로젝트는 유지됩니다 (다른 실습과 공유)"
echo "- 클러스터 레벨 권한은 유지됩니다 (3-3 실습 결과)"
echo ""
echo "현재 그룹 상태 확인:"
echo "oc get groups"
echo ""
echo "전체 실습 시리즈 정리를 원하는 경우:"
echo "1. Lab 3-3.3 정리 (현재 완료)"
echo "2. Lab 3-3.2 정리: cd ../3-3.2 && ./settings/cleanup-lab.sh"
echo "3. Lab 3-3.1 정리: cd ../3-3.1 && ./settings/cleanup-lab.sh"
echo "4. Lab 3-1 정리: cd ../3-1 && ./settings/cleanup-lab.sh"
echo -e "${NC}"

echo -e "${GREEN}✓ 전체 정리 작업 완료${NC}"