---
type: project
tags: [llm-wiki-kit, requirements]
sources:
  - conversation
created: 2026-07-20
updated: 2026-07-24
---

# lw-kit-要件定義

llm-wiki-kit の要件。
あるべき姿の全量を書く。
実装状況(完了 / 未実装)は case-root([[lw-kit]])と issue が持つ。

## 概要

LLM Wiki を始めるためのスターターキット(skills / rules / wiki 規約 / ディレクトリ構造を同梱)。

## ターゲットユーザー

[[lw-kit-要件定義-ペルソナ]] の P1(感度の高い新規ユーザー)を主要ターゲットとする。
Claude Code を日常的に使い、ナレッジ管理に課題感がある人。

P2(LLM で設計書もやりたいと思い始めた人)はリーチ拡大ターゲット。
README の見せ方とチュートリアルの導線で拾う。

## アーキテクチャ要件

全 cp + lw-sync 方式を採用する。

- `setup.sh` で llm-wiki-kit の全テンプレファイルをワークスペースに cp する
- ワークスペースは独立した git repo として育てる(symlink なし)
- llm-wiki-kit の更新は `lw-sync` skill で選択的に取り込む(LLM が diff を見て merge 要否を判断)
- 各自が skills / rules / wiki 規約を自由にカスタマイズしてよい

不採用にした方式:

- git subtree: コマンドが覚えにくい、1 repo 内に混在して分離が中途半端
- patch 方式: 手動運用で忘れる
- git submodule: update 操作が面倒、個人運用には過剰
- Plugin Marketplace 単体: `.claude/` 配下のみ対象、wiki やディレクトリ構造をカバーしない
- symlink: 各自のカスタマイズを阻害、git status に出ない問題

## 機能要件

### setup.sh

- wiki_path を対話 or 引数で受け取る
- ディレクトリ構造を生成する(`00_issues/` 〜 `90_reports/`)
- テンプレフォルダから初期ファイルを cp する
- `npm install`(`package.json` は templates に同梱)
- `git init` + first commit を行う
- 詳細: [[lw-kit-詳細設計-setup.sh]]

### lw-sync

- llm-wiki-kit の更新を検出する(`last_sync` からの diff)
- ワークスペース側の対応ファイルに変更を反映する
- LLM が diff 内容を見て merge 要否を判断する(反映 / スキップを選択)
- 詳細: [[lw-kit-スキル設計-lw-sync]]

### チュートリアル issue

- llm-wiki-kit に同梱する 4 本のチュートリアル issue(`00_issues/tutorial-01` 〜 `04`)
- issue の仕組みを使いながら全 skill を体験する
- 初回 30 分で「1 本 wiki を作る」成功体験を提供する
- 詳細: [[lw-kit-基本設計-チュートリアル]]

### skill 一式

開発ワークフロー skill を llm-wiki-kit 用(`lw-*` prefix)で提供する。
全 skill は project-local(`.claude/skills/` 配下)に統一。
一覧は [[lw-kit-アーキテクチャ設計]] の「主要 skill 一覧」参照。

### 規約一式

wiki schema / wiki スタイル / project 規約 / issue 規約 / log・index 運用を提供する。

### knowledge

`docs/knowledge/` に汎用 wiki を同梱する。
kit を理解するための参考情報群。
`setup.sh` では cp しない(kit 側に残す)。
手動 cp で取り込む。
集合外への `[[link]]` は平文に戻す。
集合内は温存する。

### Template Repository 化

「Use this template」で新 repo を得る導線。
詳細はワークスペース側のリリース issue が持つ。

### README

セットアップ手順 / ディレクトリ構造 / skill 概要。
世界観の設計はワークスペース側の README 設計を参照。
詳細はワークスペース側のリリース issue が持つ。

## 非機能要件

- 秘匿情報の排除: personal / secret 分類のファイルを llm-wiki-kit に含めない
- カスタマイズ可能: skills / rules / 規約を各自が書き換えられる
- Obsidian 互換: ワークスペースを Obsidian vault として開ける
- Obsidian 非依存: Obsidian がなくても全ワークフローが完走できる
- Node.js 前提: パッケージマネージャは npm を使用する(node が入っていれば動く)
- 再実行安全性: `setup.sh` を既存ディレクトリに再実行した時に安全に振る舞う
- 前提チェック: node / git の存在を確認し、なければ分かるエラーを出す
