#!/usr/bin/env bash
set -euo pipefail

# --- 引数の解析 --------------------------------------------------------
no_launch=false
wiki_path_arg=""
for arg in "$@"; do
  if [ "$arg" = "--no-launch" ]; then
    no_launch=true
  elif [ -z "$wiki_path_arg" ]; then
    wiki_path_arg="$arg"
  fi
done

# --- 前提チェック -------------------------------------------------------
command -v git >/dev/null 2>&1 || { echo "git が見つかりません。https://git-scm.com からインストールしてください"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "node が見つかりません。https://nodejs.org からインストールしてください"; exit 1; }
if [ "$no_launch" = false ]; then
  command -v claude >/dev/null 2>&1 || { echo "claude が見つかりません。https://claude.com/claude-code からインストールしてください（起動せずに生成だけしたい場合は --no-launch を付けてください）"; exit 1; }
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- wiki_path の決定 ----------------------------------------------------
if [ -n "$wiki_path_arg" ]; then
  wiki_path_input="$wiki_path_arg"
else
  read -r -p "wiki の作成先を入力してください [~/wiki/my-wiki]: " wiki_path_input
  if [ -z "$wiki_path_input" ]; then
    wiki_path_input="~/wiki/my-wiki"
  fi
fi

case "$wiki_path_input" in
  "~") wiki_path_input="$HOME" ;;
  "~/"*) wiki_path_input="$HOME/${wiki_path_input#\~/}" ;;
esac
case "$wiki_path_input" in
  /*) wiki_path="$wiki_path_input" ;;
  *) wiki_path="$(pwd)/$wiki_path_input" ;;
esac

# --- 再実行安全性 --------------------------------------------------------
if [ -d "$wiki_path/.git" ]; then
  echo "既に初期化済みです: $wiki_path"
  exit 1
fi

if [ -d "$wiki_path" ]; then
  read -r -p "ディレクトリが既に存在します。上書きしますか？ [y/N]: " overwrite_answer
  case "$overwrite_answer" in
    y|Y) ;;
    *) echo "セットアップを中止しました。"; exit 1 ;;
  esac
fi

mkdir -p "$wiki_path"

# --- templates/ をコピー --------------------------------------------------
cp -a "$SCRIPT_DIR/templates/." "$wiki_path/"

# --- CLAUDE.md に kit の場所を埋め込む ------------------------------------
# skill / guide / rules が `$KIT/docs/...` で kit 側の設計書と規範を指すため、
# 生成時点の clone 元を実パスで解決しておく（未実行なら placeholder が残り、
# 利用者が手で書き換えられる）。
claude_md="$wiki_path/.claude/CLAUDE.md"
if [ -f "$claude_md" ]; then
  kit_path_escaped="$(printf '%s' "$SCRIPT_DIR" | sed 's/[&|\\]/\\&/g')"
  sed "s|__LLM_WIKI_KIT_PATH__|$kit_path_escaped|g" "$claude_md" > "$claude_md.tmp"
  mv "$claude_md.tmp" "$claude_md"
fi

cd "$wiki_path"

# --- 日付の placeholder を埋める --------------------------------------------
# frontmatter の created / updated と log.md の init 行に生成日を入れる。
# `.claude/` 配下は skill / rule が frontmatter の書式を `YYYY-MM-DD` で例示して
# いるだけなので触らない。
today="$(date +%Y-%m-%d)"
find . -name "*.md" -not -path "./.claude/*" -not -path "./node_modules/*" -print0 |
  while IFS= read -r -d '' file; do
    sed -E "s/^(created|updated): YYYY-MM-DD\$/\1: $today/" "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
  done
sed "s|^- \[YYYY-MM-DD\] init |- [$today] init |" log.md > log.md.tmp
mv log.md.tmp log.md

# --- git init -------------------------------------------------------------
git init

# --- npm install ------------------------------------------------------------
npm install

# --- lefthook install --------------------------------------------------------
npx lefthook install

# --- first commit ---------------------------------------------------------
git add -A
git commit -m "chore: initial commit from llm-wiki-kit"

# --- 完了メッセージ + Claude Code 起動 -----------------------------------
echo "✅ セットアップ完了！"

cat <<'RAIN'

────────────────────────────────────────────────────

        .--.
     .-(    ).
    (___.__)__)
      ' ' ' '
     ' ' ' '

    llm-wiki-kit

    降ってきた情報を raw に溜め、wiki / project に蒸留する。

────────────────────────────────────────────────────

RAIN

if [ "$no_launch" = false ]; then
  printf '\033[1m💬 Claude Code を起動したら、こう話しかけてください:\033[0m\n\n'
  printf '  ┌─\n'
  printf '  │  \033[36m00_issues/tutorial-01-first-wiki.md を読んで、チュートリアルを始めたい。最初のステップから案内して\033[0m\n'
  printf '  └─\n\n'
  read -r -p "Enter を押すと Claude Code が起動します..."
  exec claude
fi
