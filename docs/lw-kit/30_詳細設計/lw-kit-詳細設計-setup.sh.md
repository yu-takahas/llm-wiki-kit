---
type: project
tags: [llm-wiki-kit, setup]
sources:
  - conversation
  - "[[lw-kit-基本設計-ディレクトリ構成]]"
created: 2026-07-20
updated: 2026-07-28
---

# llm-wiki-kit-setup.sh設計

ワークスペースを生成するセットアップスクリプト。
叩いたらすぐ使える状態まで持っていくワンショットセットアップ。

## 処理フロー

1. 前提チェック（node / git の存在確認）
2. `wiki_path` を決定する（引数 or 対話）
3. ディレクトリ構造を作る（`00_issues/` 〜 `90_reports/`）
4. `templates/` から初期ファイルを cp する
5. `.claude/CLAUDE.md` の `__LLM_WIKI_KIT_PATH__` を clone 元の実パスに置換する
6. `git init`
7. `npm install`（`templates/` 内の `package.json` に基づいて依存インストール）
8. `lefthook install`（hook を `.git/hooks/` に張る）
9. first commit
10. Claude Code を起動する（`cd <wiki_path> && claude`）

### 処理順の制約

- `git init`（6）は `lefthook install`（8）より前に実行する（`.git/` がないと hook を張れない）
- `npm install`（7）は `git init`（6）の後（`package.json` を first commit に含めるため）
- `$KIT` の埋め込み（5）は cp（4）の後、first commit（9）より前（置換後の内容を initial commit に含めるため）

### `$KIT` の埋め込み

配布される `CLAUDE.md` は `$KIT` の定義行に `__LLM_WIKI_KIT_PATH__` を持つ。
`setup.sh` は自分の位置（`$(cd "$(dirname "$0")" && pwd)`）を clone 元として解決し、この placeholder を実パスに置換する。

skill / guide / rules が `$KIT/docs/...` で kit 側の設計書と規範を指しているため、定義がないと参照が解決しない。
説明的な定義だけを置く案は採らない。Claude が実際に Read できずポインタが実行不能なままになり、Bash 文脈では未定義変数が空展開されて誤ったパスを指すため。
判断の経緯は [[lw-kit-ガイド設計-skill-guide]]「決定」セクション。

`setup.sh` を経由せず `templates/` を手でコピーした場合は placeholder が残る。
`__` で囲まれた見た目が未設定を示すので、利用者が書き換えられる。

### Claude Code 起動

`setup.sh` の最後にワークスペースで Claude Code を起動し、チュートリアルへの導線を表示する。

```
✅ セットアップ完了！

Claude Code を起動したら、こう話しかけてみてください:

  00_issues/tutorial-01-first-wiki.md を読んで、チュートリアルを始めたい。最初のステップから案内して

Enter を押すと Claude Code が起動します...
```

`read -r -p` で一時停止し、ユーザーがメッセージを読んでから Enter で Claude Code を起動する。
`exec claude` が即座にターミナルを乗っ取るため、一時停止がないとメッセージが見えないまま消える。

```bash
cd <wiki_path>
read -r -p "Enter を押すと Claude Code が起動します..."
exec claude
```

ユーザーは表示された例文を参考に Claude Code に話しかけるだけで始められる。
チュートリアル issue の TODO の最初の項目で `add-dir` を案内する。

## 前提チェック

スクリプト冒頭で以下を確認し、なければ明確なエラーメッセージを出して終了する。

- `git` コマンドの存在
- `node` コマンドの存在

エラーメッセージはインストール方法を案内する（例: `node が見つかりません。https://nodejs.org からインストールしてください`）。

## wiki_path の決定

引数があればそれを使う。なければ対話で聞く。

```bash
./setup.sh ~/project/wiki/my-wiki
```

or

```
./setup.sh
wiki の作成先を入力してください [~/wiki/my-wiki]:
```

未入力 Enter でデフォルト値 `~/wiki/my-wiki` が使われる。
`~` は展開する。相対パスは絶対パスに解決する。

## 再実行安全性

`wiki_path` が既に存在する場合:

- `.git/` が存在する → 「既に初期化済みです」と警告して終了
- `.git/` がない → 「ディレクトリが既に存在します。上書きしますか？」と確認

中断からの再実行は「最初からやり直し」で対応する（冪等性より分かりやすさを優先）。
