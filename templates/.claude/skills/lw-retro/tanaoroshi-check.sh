#!/bin/bash
# 作業スタイル台帳の棚卸し起動条件を計測する
# 使い方: bash tanaoroshi-check.sh 50_feedback/feedback-観察-作業スタイル.md
FILE="${1:?usage: tanaoroshi-check.sh <file>}"

last_date=$(grep '^前回棚卸し日: ' "$FILE" | head -1 | cut -d' ' -f2)

if [ -z "$last_date" ]; then
  new_n=$(grep -c '^- 事例 ' "$FILE")
  warn="WARNING: 前回棚卸し日行が見つかりません（全件カウント）"
else
  new_n=0
  while IFS= read -r line; do
    edate=$(echo "$line" | cut -d' ' -f3 | cut -c1-10)
    [[ "$edate" > "$last_date" ]] && new_n=$((new_n + 1))
  done < <(grep '^- 事例 ' "$FILE")
fi

inbox_n=0
in_inbox=0
while IFS= read -r line; do
  case "$line" in
    "## INBOX"*) in_inbox=1 ;;
    "## "*) in_inbox=0 ;;
    "#### "*) [[ "$in_inbox" -eq 1 ]] && inbox_n=$((inbox_n + 1)) ;;
  esac
done < "$FILE"

recur_n=0
cur_sd=""
while IFS= read -r line; do
  case "$line" in
    "#### "*)
      cur_sd=""
      ;;
    "- 対策先: "*)
      sd=$(echo "$line" | grep -oE '（[0-9]{4}-[0-9]{2}-[0-9]{2} 設定）' | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
      [ -n "$sd" ] && cur_sd="$sd"
      ;;
    "- 事例 "*)
      if [ -n "$cur_sd" ]; then
        edate=$(echo "$line" | cut -d' ' -f3 | cut -c1-10)
        [[ "$edate" > "$cur_sd" ]] && recur_n=$((recur_n + 1))
      fi
      ;;
  esac
done < "$FILE"

printf '事例 %d 件 / INBOX %d 件 / 再発 %d 件\n' "$new_n" "$inbox_n" "$recur_n"
[ -n "$warn" ] && echo "$warn"
exit 0
