---
type: project
tags: [llm-wiki-kit]
sources:
  - conversation
created: 2026-07-20
updated: 2026-07-24
---

# llm-wiki-kit

LLM-Wiki 方式の個人ナレッジワークスペースを構築するスターターキット。
Claude Code と協働して思考を wiki に蓄積・再利用し、最小のコンテキストスイッチでアウトプットにつなげる。

## 背景

llm-wiki-kit はフレームワーク（スターターキット）として、ワークスペースの構造・規約・skill を提供する。
`setup.sh` で全ファイルを cp し、各自が自分の repo として育てる（symlink なし）。
kit の更新は現状手動で取り込む。選択的な取り込みを行う `lw-sync` は設計のみで未実装（[[lw-kit-スキル設計-lw-sync]] を参照）。
各ワークスペースインスタンスの固有情報はインスタンス側の `40_project/` に持つ。

## アーキテクチャ

構造・設計原則・ワークフローの全体像は [[lw-kit-アーキテクチャ設計]] を参照。

## 設計書

### 要件定義(`10_要件定義/`)

- [[lw-kit-要件定義]] — 機能 / 非機能要件
- [[lw-kit-要件定義-ペルソナ]] — ターゲットユーザーの分析

### 基本設計(`20_基本設計/`)

- [[lw-kit-基本設計-ディレクトリ構成]] — llm-wiki-kit のディレクトリ構成
- [[lw-kit-基本設計-スターターテンプレ]] — 初期ファイル群の雛形
- [[lw-kit-基本設計-チュートリアル]] — 新規ユーザーの初回体験設計

### 詳細設計(`30_詳細設計/`)

- [[lw-kit-詳細設計-CLAUDE.md]] — CLAUDE.md / rules / skills 運用の設計
- [[lw-kit-詳細設計-README]] — README を書く / 改訂する時の設計指針
- [[lw-kit-詳細設計-rules]] — rules 設計の起点
- [[lw-kit-詳細設計-issue]] — issue の概念・状態管理・命名規約
- [[lw-kit-詳細設計-guide]] — guide（issue の TODO メニュー）の機構設計
- [[lw-kit-詳細設計-log-index]] — `log.md` / `index.md` の運用設計
- [[lw-kit-詳細設計-library]] — 蔵書管理の設計
- [[lw-kit-詳細設計-Markdown環境]] — prettier / markdownlint / lefthook の設定と運用
- [[lw-kit-詳細設計-setup.sh]] — セットアップスクリプト

### スキル設計(`40_スキル設計/`)

各 skill の個別設計書（ADR 相当）。設計書と実物の境界は [[lw-kit-アーキテクチャ設計]]「設計書の境界」が規定する。

- [[lw-kit-スキル設計-lw-create-issue]] / [[lw-kit-スキル設計-lw-update-issue]] / [[lw-kit-スキル設計-lw-commit]] / [[lw-kit-スキル設計-lw-retro]] / [[lw-kit-スキル設計-lw-archive-weekly]]
- [[lw-kit-スキル設計-lw-render]] / [[lw-kit-スキル設計-lw-lint]] / [[lw-kit-スキル設計-lw-research-doc]]
- [[lw-kit-スキル設計-lw-doc-review]] / [[lw-kit-スキル設計-lw-fix-review]] / [[lw-kit-スキル設計-lw-code-review]]
- [[lw-kit-スキル設計-lw-cmux-teams]] / [[lw-kit-スキル設計-lw-tdd]] / [[lw-kit-スキル設計-lw-sync]]

### ガイド設計(`50_ガイド設計/`)

各 guide（issue の ☔ TODO に流し込むワークフローのメニュー）の設計書。
機構は [[lw-kit-詳細設計-guide]] を参照。

- [[lw-kit-ガイド設計-dev-guide]] — アプリ開発 issue 用（`dev-guide.md`）
- [[lw-kit-ガイド設計-skill-guide]] — skill 設計 issue 用（`skill-guide.md`）
