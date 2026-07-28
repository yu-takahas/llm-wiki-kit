---
type: source
tags: [Claude-Code, skill, plugin, MCP, hooks, 開発手法]
sources: []
created: 2026-07-13
updated: 2026-07-13
---

# Claude Code 開発ワークフロー系エコシステム

Claude Code の skill / plugin / MCP server / hooks / settings のうち、開発ワークフローに関連するものを整理する。

## skill / plugin

plugin は skill / subagent / hook / MCP server / command を束ねた installable unit。
公式 marketplace からワンコマンドで入る。

### superpowers

コミュニティ最大級の skill フレームワーク。
brainstorming → worktree 作成 → plan → subagent 開発 → TDD → code-review → finish の skill 連鎖で、いきなり実装に飛ばず構造化されたワークフローを踏ませる。
TDD skill は「失敗テストが存在する前に書かれたコードを削除する」ほど厳格にテスト先行を強制する。
`verification-before-completion`（完了宣言前の確認）も含む。

### Anthropic 公式

`feature-dev`（機能開発ワークフロー）/ `code-review`（confidence スコア付き PR レビュー）/ `commit-commands`（commit/push/PR を 1 コマンドで）/ `webapp-testing`（Playwright 検証）/ `code-simplifier`（可読性クリーンアップ）等。

### テスト / TDD 特化

superpowers 系と hermes-agent 系の TDD skill が人気上位。
いずれも RED → GREEN → REFACTOR とテスト先行を強制する。

## MCP server

MCP はエージェントを外部ツール・データに接続する標準。

- **GitHub MCP**: repo 読み取り・ブランチ作成・PR 作成/レビュー・issue 管理・CI 監視
- **Playwright MCP**: 実ブラウザを駆動して UI 変更を自己検証する
- **Postgres MCP**: read-only DSN でスキーマ把握・クエリを安全に行わせる
- **Context7**: 最新ライブラリのドキュメントを注入し、古い API 記憶による誤りを正す

サーバは 2-3 個に絞る。
5-7 個を超えると tool bloat でエージェント性能が落ちる。

## hooks 活用パターン

`CLAUDE.md` の指示は advisory（守られないことがある）だが、hooks はライフサイクルで必ず走るシェルコマンドで deterministic。
「必ず・例外なく起きるべき」ことは hook に、状況判断が要るものは skill / `CLAUDE.md` に置く。

### 代表パターン

- **テスト/lint ゲート**（`PreToolUse`、matcher = `Bash`）: `git push` を検知したら lint + test を走らせ、失敗で push を hard block
- **自動整形**（`PostToolUse`、matcher = `Write`/`Edit`）: 編集後に formatter を自動実行
- **保護ファイルのブロック**（`PreToolUse`）: migrations や `.env` への write をブロック
- **skill 発火の底上げ**（`UserPromptSubmit`）: プロンプト送信時に「どの skill が該当するか明示せよ」を注入
- **context 注入**（`SessionStart`）: セッション開始時に規約やブランチ情報を注入

`PreToolUse` hook は permission 評価の前に走り、exit code 2 なら allow rule より優先して呼び出しをブロックできる。

## settings.json の permission

`permissions` に `allow` / `ask` / `deny` の配列を持つ。
評価順は deny → ask → allow で、最初のマッチが決定する。

- **allow**: テスト・ビルド・lint 等の反復コマンドを自動許可し permit prompt を減らす
- **deny**: `git push --force` / `rm -rf` / `git reset --hard` 等の危険操作をブロック

注意点: 引数で絞る permission は迂回されやすい（プロトコル違い・リダイレクト・変数展開）。
環境ランナー（`devbox run` / `npx`）は内側コマンドまで含めて書く。
複合コマンドは各サブコマンドが独立にマッチする。

## ガードレールの層構造

AI がテストを消す / skip する / 実装後にテストを書く罠を防ぐには、指示頼みでなく構造で防ぐ。

1. **advisory 層**（`CLAUDE.md` / `rules/`）: ワークフロールール、テスト先行の指示
2. **deterministic 層**（hooks）: テスト/lint の自動実行、push 前ゲート
3. **permission 層**（`settings.json`）: 危険操作の deny、反復操作の allow

advisory で守られなければ hook に昇格、hook でも不十分なら skill に昇格、という段階的なエスカレーションが推奨される。
