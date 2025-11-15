#!/bin/bash

echo "=============================================="
echo "DO280 Lab 8-5: CronJob 실습 환경 구성"
echo "=============================================="
echo ""

# scheduler 프로젝트 생성
echo "📦 scheduler 프로젝트 생성 중..."
if oc get project scheduler &>/dev/null; then
    echo "⚠ scheduler 프로젝트가 이미 존재합니다. 삭제 후 재생성합니다."
    oc delete project scheduler
    echo "⏳ 프로젝트 삭제 대기 중..."
    sleep 10
fi

oc new-project scheduler --display-name="CronJob Scheduler"
echo "✓ scheduler 프로젝트 생성 완료"
echo ""

# trigger-sa ServiceAccount 생성
echo "👤 ServiceAccount 생성 중..."
oc create serviceaccount trigger-sa -n scheduler
echo "✓ trigger-sa ServiceAccount 생성 완료"
echo ""

# 참고용 CronJob 예제 생성 (실습에서 참고할 수 있도록)
echo "📋 참고용 CronJob 예제 배포 중..."
cat <<EOF | oc apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: example-cleanup
  namespace: scheduler
spec:
  schedule: "0 2 * * 0"  # 매주 일요일 02:00
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: trigger-sa
          containers:
          - name: cleanup
            image: registry.access.redhat.com/ubi8/ubi:8.8
            command:
            - /bin/sh
            - -c
            - echo "Example cleanup job at \$(date)"
          restartPolicy: OnFailure
EOF

echo "✓ 참고용 CronJob 배포 완료"
echo ""

echo "=============================================="
echo "현재 상태 확인"
echo "=============================================="
echo ""

echo "📋 ServiceAccount:"
oc get sa -n scheduler
echo ""

echo "📋 CronJobs:"
oc get cronjobs -n scheduler
echo ""

echo "=============================================="
echo "✅ 실습 환경 구성 완료!"
echo "=============================================="
echo ""
echo "과제:"
echo "  다음 요구사항으로 CronJob을 생성하세요:"
echo ""
echo "  - CronJob 이름: job-runner"
echo "  - 이미지: bitnami/nginx:latest"
echo "  - 스케줄: 매월 2일 04:05 AM"
echo "  - 성공 작업 히스토리: 14"
echo "  - ServiceAccount: trigger-sa"
echo "  - 프로젝트: scheduler"
echo ""
echo "다음 단계:"
echo "  cd /home/student/Desktop/DO280_labs/8-5"
echo "  README.md 파일을 참고하여 실습을 진행하세요"
echo ""
echo "참고:"
echo "  - Web Console 또는 CLI로 생성 가능"
echo "  - example-cleanup CronJob을 참고용으로 사용하세요"
echo ""
echo "=============================================="
