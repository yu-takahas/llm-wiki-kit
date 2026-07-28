---
type: entity
tags: [claude-code, settings, configuration, entity]
sources:
  - https://code.claude.com/docs/en/settings.md
  - conversation
created: 2026-05-25
updated: 2026-05-25
---

# Claude-Code settings.json

Claude Code の挙動を制御する設定ファイル。
本 page は設定キーの一般的な仕様を溜める入れ物。

## スコープと優先順位

3 階層あり、狭いスコープが優先される。

- user: `~/.claude/settings.json`（全プロジェクト共通）
- project: `.claude/settings.json`（リポジトリ共有、commit 対象）
- local: `.claude/settings.local.json`（個人ローカル、gitignore 対象）

個別キーの網羅は公式 doc（`sources` の settings リファレンス）に委ねる。

## attribution（commit / PR の Co-Authored-By 制御）

Claude Code が commit / PR を作る際の共同作成者表記を制御するキー。

- デフォルトで commit メッセージ末尾に `Co-Authored-By: Claude ... <noreply@anthropic.com>` trailer を自動付与する
- `attribution.commit` / `attribution.pr` で付与内容を制御、空文字列 `""` で無効化できる
- trailer のモデル名・バージョン文字列は Claude Code 内部ロジックが決める（settings.json では微調整できない）

含意（一般論）: commit メッセージ本文に trailer を手書きすると、自動付与と合わせて二重付与になりうる。

## 関連

- [[Claude-Code-Hook]] — settings.json と並ぶ Claude Code の挙動制御の仕組み
- [[Claude-Codeのコマンド実行多層防御]] — permissions allow/deny + sandbox が基盤層となる防御パターン
- [[Claude-Codeのステータスライン]] — `statusLine` キーで設定する画面下部の表示バー
