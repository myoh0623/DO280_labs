#!/bin/bash

echo "=============================================="
echo "DO280 Lab 8-5: CronJob 실습 환경 정리"
echo "=============================================="
echo ""

# 확인 메시지
read -p "⚠ scheduler 프로젝트와 모든 리소스를 삭제하시겠습니까? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 정리 작업이 취소되었습니다."
    exit 0
fi

echo ""
echo "🧹 CronJob 실습 환경 정리 중..."
echo ""

# scheduler 프로젝트 삭제 (모든 리소스 포함)
echo "📦 scheduler 프로젝트 삭제 중..."
if oc get project scheduler &>/dev/null; then
    oc delete project scheduler
    echo "✓ scheduler 프로젝트 삭제 완료"
    echo "⏳ 프로젝트 완전 삭제 대기 중..."
    
    # 프로젝트가 완전히 삭제될 때까지 대기
    while oc get project scheduler &>/dev/null; do
        sleep 2
    done
    echo "✓ 프로젝트 완전 삭제 확인"
else
    echo "⚠ scheduler 프로젝트가 존재하지 않습니다."
fi

echo ""
echo "=============================================="
echo "✅ 정리 완료!"
echo "=============================================="
echo ""
echo "삭제된 리소스:"
echo "  - scheduler 프로젝트"
echo "  - job-runner CronJob (생성했다면)"
echo "  - example-cleanup CronJob"
echo "  - trigger-sa ServiceAccount"
echo "  - 관련된 모든 Job, Pod"
echo ""
echo "실습을 다시 시작하려면:"
echo "  cd /home/student/Desktop/DO280_labs/8-5/settings"
echo "  ./setup-lab.sh"
echo ""
echo "=============================================="
