#!/bin/bash
# lw-lint: broken link 検出パイプライン
# SKILL.md 本文に awk を直書きすると $0 / $2 が skill の引数置換
# （$N = $ARGUMENTS[N] のショート）に食われて壊れるため、補助スクリプトに分離している。
#
# 出力:
#   /tmp/lw-lint-raw-links.txt   <file>\t[[name]] の全 link 一覧（alias / anchor は name に正規化済み）
#   /tmp/lw-lint-link-names.txt  link 名の一意集合（placeholder 除外済み）
#   /tmp/lw-lint-filenames.txt   解決先ファイル名の一意集合
#   /tmp/lw-lint-broken.txt      broken link 名（差集合）
set -u
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# link 抽出。コードフェンス / コードスパン / 画像 embed を除去し、
# alias [[name|display]] と anchor [[name#section]] は [[name]] に正規化してから抽出する。
# ルート直下のメタファイルも抽出元に含める（index 委譲方針: index.md からのリンクも
# inbound として数え、orphan = index にも載っていない page とする。index.md 内の
# broken link 検出も兼ねる）。log.md だけは追記専用の履歴で旧名 link が残るため除外。
{ find 30_wiki 40_project 00_issues .claude 20_library 50_feedback -name "*.md" -type f -not -path '*/.obsidian/*' -print0; \
  find . -maxdepth 1 -name "*.md" -type f ! -name "log.md" -print0; } \
  | xargs -0 awk '
    FNR==1 { in_fence = 0 }
    /^```/ { in_fence = !in_fence; next }
    !in_fence {
      line = $0
      gsub(/`[^`]*`/, "", line)
      gsub(/!\[\[[^\]]+\]\]/, "", line)
      while (match(line, /\[\[[^][|#]+\|[^][]+\]\]/)) {
        name = substr(line, RSTART, RLENGTH)
        sub(/^\[\[/, "", name); sub(/\|.*$/, "", name)
        sub(/\\+$/, "", name)  # 表セル内の \| エスケープで残る末尾バックスラッシュを除去
        line = substr(line, 1, RSTART - 1) "[[" name "]]" substr(line, RSTART + RLENGTH)
      }
      while (match(line, /\[\[[^][|#]+#[^][]+\]\]/)) {
        name = substr(line, RSTART, RLENGTH)
        sub(/^\[\[/, "", name); sub(/#.*$/, "", name)
        line = substr(line, 1, RSTART - 1) "[[" name "]]" substr(line, RSTART + RLENGTH)
      }
      while (match(line, /\[\[[^][|#]+\]\]/)) {
        print FILENAME "\t" substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' > /tmp/lw-lint-raw-links.txt

# link 名の一意集合（angle-bracket placeholder [[<...>]] を除外）
awk -F'\t' '{print $2}' /tmp/lw-lint-raw-links.txt \
  | sort -u | grep -v "^\[\[<" | sed 's/^\[\[//; s/\]\]$//' | sort -u \
  > /tmp/lw-lint-link-names.txt

# 解決先ファイル名の集合（wiki ディレクトリ群 + ルート直下メタファイル）
{ find 30_wiki 40_project 00_issues .claude 20_library 50_feedback -name "*.md" -type f -not -path '*/.obsidian/*' \
    | awk -F/ '{print $NF}' | sed 's/\.md$//'; \
  ls *.md 2>/dev/null | sed 's/\.md$//'; } | sort -u \
  > /tmp/lw-lint-filenames.txt

# 差集合 = broken link
comm -23 /tmp/lw-lint-link-names.txt /tmp/lw-lint-filenames.txt \
  > /tmp/lw-lint-broken.txt

echo "links: $(wc -l < /tmp/lw-lint-raw-links.txt | tr -d ' ') / broken: $(wc -l < /tmp/lw-lint-broken.txt | tr -d ' ')"
