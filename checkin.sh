#!/bin/bash
# Velrix 每日签到脚本（多账号）
# VELRIX_COOKIES 格式: JSON 数组 [{"name":"账号1","cookie":"xxx"},{"name":"账号2","cookie":"yyy"}]

API="https://api.velrix.net"
COOKIES_JSON="${VELRIX_COOKIES:-[]}"

# 兼容旧版单 cookie（VELRIX_COOKIE）
if [ -n "${VELRIX_COOKIE:-}" ] && [ "$COOKIES_JSON" = "[]" ]; then
  COOKIES_JSON="[{\"name\":\"default\",\"cookie\":\"$VELRIX_COOKIE\"}]"
fi

echo "=== Velrix 每日签到（多账号）==="
echo "时间: $(date '+%Y-%m-%d %H:%M:%S') UTC"

# 解析账号数量
ACCOUNT_COUNT=$(echo "$COOKIES_JSON" | jq 'length')
echo "📋 共 $ACCOUNT_COUNT 个账号"

if [ "$ACCOUNT_COUNT" -eq 0 ]; then
  echo "❌ 没有配置任何账号"
  echo "result=error" >> $GITHUB_OUTPUT
  exit 1
fi

ALL_RESULTS=""
ALL_SUCCESS=0
ALL_FAIL=0

for i in $(seq 0 $((ACCOUNT_COUNT - 1))); do
  NAME=$(echo "$COOKIES_JSON" | jq -r ".[$i].name")
  COOKIE=$(echo "$COOKIES_JSON" | jq -r ".[$i].cookie")

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📌 账号: $NAME"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [ -z "$COOKIE" ] || [ "$COOKIE" = "null" ]; then
    echo "❌ Cookie 为空，跳过"
    ALL_RESULTS="${ALL_RESULTS}❌ ${NAME}: Cookie 为空\n"
    ALL_FAIL=$((ALL_FAIL + 1))
    continue
  fi

  # 签到
  echo ">> 签到中..."
  RESULT=$(curl -s -X POST "$API/v1/economy/daily" \
    -H "Cookie: $COOKIE" \
    -H "Content-Type: application/json" \
    -H "Origin: https://www.velrix.net" \
    -H "User-Agent: Mozilla/5.0")

  SUCCESS=$(echo "$RESULT" | jq -r '.success // empty')
  if [ "$SUCCESS" = "true" ]; then
    echo "✅ 签到成功！"
    STATUS="claimed"
  elif [ "$SUCCESS" = "false" ]; then
    ERROR=$(echo "$RESULT" | jq -r '.error')
    if [ "$ERROR" = "already_claimed" ]; then
      echo "ℹ️  今天已签过了"
      STATUS="already_claimed"
    else
      MSG=$(echo "$RESULT" | jq -r '.message // "未知错误"')
      echo "❌ 签到失败: $MSG"
      STATUS="error"
    fi
  else
    echo "❌ 签到失败（API 无响应或 cookie 失效）"
    echo "$RESULT"
    STATUS="error"
  fi

  # 查余额
  BALANCE="?"
  if [ "$STATUS" != "error" ]; then
    BALANCE=$(curl -s "$API/v1/economy/balance" \
      -H "Cookie: $COOKIE" \
      -H "Origin: https://www.velrix.net" \
      -H "User-Agent: Mozilla/5.0" | jq -r '.data.balance // "?"')
    echo "💰 余额: $BALANCE 分"
  fi

  case "$STATUS" in
    claimed) ICON="✅"; ALL_SUCCESS=$((ALL_SUCCESS + 1)) ;;
    already_claimed) ICON="ℹ️"; ALL_SUCCESS=$((ALL_SUCCESS + 1)) ;;
    *) ICON="❌"; ALL_FAIL=$((ALL_FAIL + 1)) ;;
  esac
  ALL_RESULTS="${ALL_RESULTS}${ICON} ${NAME}: ${STATUS} (💰${BALANCE})\n"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 汇总:"
echo -e "$ALL_RESULTS"
echo "成功: $ALL_SUCCESS / 失败: $ALL_FAIL"

# 输出供 workflow 使用
echo "result=$( [ $ALL_FAIL -eq 0 ] && echo success || echo partial )" >> $GITHUB_OUTPUT
echo "summary<<EOF" >> $GITHUB_OUTPUT
echo -e "$ALL_RESULTS" >> $GITHUB_OUTPUT
echo "EOF" >> $GITHUB_OUTPUT

exit 0
