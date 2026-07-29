#!/bin/bash
# Velrix 每日签到脚本
# GitHub Actions 自动执行

API="https://api.velrix.net"
COOKIE="${VELRIX_COOKIE}"

echo "=== Velrix 每日签到 ==="
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"

# 签到
echo ""
echo ">> 签到中..."
RESULT=$(curl -s -X POST "$API/v1/economy/daily" \
  -H "Cookie: $COOKIE" \
  -H "Content-Type: application/json" \
  -H "Origin: https://www.velrix.net" \
  -H "User-Agent: Mozilla/5.0")

SUCCESS=$(echo "$RESULT" | jq -r '.success')
if [ "$SUCCESS" = "true" ]; then
  BALANCE=$(echo "$RESULT" | jq -r '.data.balance')
  echo "✅ 签到成功！当前余额: $BALANCE 分"
elif [ "$SUCCESS" = "false" ]; then
  ERROR=$(echo "$RESULT" | jq -r '.error')
  MSG=$(echo "$RESULT" | jq -r '.message')
  echo "ℹ️  $MSG"
  if [ "$ERROR" = "already_claimed" ]; then
    NEXT=$(echo "$RESULT" | jq -r '.details.nextClaimAt')
    echo "   下次签到: $NEXT"
  fi
else
  echo "❌ 签到失败"
  echo "$RESULT"
fi

# 查余额
echo ""
echo ">> 当前余额:"
curl -s "$API/v1/economy/balance" \
  -H "Cookie: $COOKIE" \
  -H "Origin: https://www.velrix.net" \
  -H "User-Agent: Mozilla/5.0" | jq '.data.balance'