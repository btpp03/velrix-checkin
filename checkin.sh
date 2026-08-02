#!/bin/bash
# Velrix 每日签到脚本
# GitHub Actions 自动执行

API="https://api.velrix.net"
COOKIE="${VELRIX_COOKIE}"

echo "=== Velrix 每日签到 ==="
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"

# 检查 cookie 是否设置
if [ -z "$COOKIE" ]; then
  echo "❌ VELRIX_COOKIE 未设置或为空"
  exit 1
fi

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
  echo "✅ 签到成功！"
elif [ "$SUCCESS" = "false" ]; then
  ERROR=$(echo "$RESULT" | jq -r '.error')
  MSG=$(echo "$RESULT" | jq -r '.message')
  if [ "$ERROR" = "already_claimed" ]; then
    echo "ℹ️  今天已签过了"
    NEXT=$(echo "$RESULT" | jq -r '.details.nextClaimAt')
    echo "   下次签到: $NEXT"
  else
    echo "❌ 签到失败: $MSG"
    exit 1
  fi
else
  echo "❌ 签到失败（API 无响应或 cookie 失效）"
  echo "$RESULT"
  exit 1
fi

# 查余额
echo ""
echo ">> 当前余额:"
BALANCE=$(curl -s "$API/v1/economy/balance" \
  -H "Cookie: $COOKIE" \
  -H "Origin: https://www.velrix.net" \
  -H "User-Agent: Mozilla/5.0" | jq -r '.data.balance // "unknown"')
echo "💰 余额: $BALANCE 分"
echo "balance=$BALANCE" >> $GITHUB_OUTPUT