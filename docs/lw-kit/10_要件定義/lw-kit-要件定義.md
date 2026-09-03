---
type: project
tags: [llm-wiki-kit, requirements]
sources:
  - conversation
created: 2026-07-20
updated: 2026-08-31
---

# lw-kit-要件定義

llm-wiki-kit の要件。
あるべき姿の全量を書く。

**本ページは要件そのものを持つ。**
個々の仕組みの手順・具体値・設定値は `docs/lw-kit/` 配下の各設計書と実物が正本で、本ページに写さない。
方式の選定と却下理由（下記「アーキテクチャ要件」）は本ページが正本。
実装状況は `templates/` 配下の実物が示し、「設計のみで未実装」という意図は各設計書の冒頭が持つ。
issue やハブを正本にしないのは、issue が配布物に含まれず、公開された kit の読者から到達しないため。

## 概要

LLM Wiki を始めるためのスターターキット(skills / rules / wiki 規約 / ディレクトリ構造を同梱)。

## ターゲットユーザー

主要ターゲットは [[lw-kit-要件定義-ペルソナ]] の P1、リーチ拡大が P2。
人物像と、それぞれをどう拾うかはペルソナ側が持つ。

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

- llm-wiki-kit の更新を検出する
- ワークスペース側の対応ファイルに変更を反映する
- LLM が diff 内容を見て merge 要否を判断する(反映 / スキップを選択)
- 詳細: [[lw-kit-スキル設計-lw-sync]]

### チュートリアル issue

- llm-wiki-kit にチュートリアル issue を同梱する（実物は `templates/00_issues/tutorial-*.md`）
- issue の仕組みを使いながら全 skill を体験する
- 初回 30 分で「1 本 wiki を作る」成功体験を提供する
- 詳細: [[lw-kit-基本設計-チュートリアル]]

### skill 一式

開発ワークフロー skill を llm-wiki-kit 用(`lw-*` prefix)で提供する。
全 skill は project-local(`.claude/skills/` 配下)に統一。
各 skill の位置づけは [[lw-kit-アーキテクチャ設計]]「開発ワークフロー」セクションが持つ。

### 規約一式

wiki schema / wiki スタイル / project 規約 / issue 規約 / log・index 運用を提供する。

### knowledge

`docs/knowledge/` に汎用 wiki を同梱する。
kit を理解するための参考情報群で、配布物には含めない。
利用者が必要な page だけを手動で取り込む。
取り込み時の `[[link]]` の扱いは [[lw-kit-基本設計-ディレクトリ構成]]「`docs/knowledge/` を取り込む時」を参照。

### Template Repository 化

「Use this template」で新 repo を得る導線を用意する。

### README

セットアップ手順 / ディレクトリ構造 / skill 概要を持たせる。
書き方の指針は [[lw-kit-詳細設計-README]] を参照。

## 非機能要件

- 秘匿情報の排除: personal / secret 分類のファイルを llm-wiki-kit に含めない
- カスタマイズ可能: skills / rules / 規約を各自が書き換えられる
- Obsidian 互換: ワークスペースを Obsidian vault として開ける
- Obsidian 非依存: Obsidian がなくても全ワークフローが完走できる
- Node.js 前提: パッケージマネージャは npm を使用する(node が入っていれば動く)
- 再実行安全性: `setup.sh` を既存ディレクトリに再実行した時に安全に振る舞う
- 前提チェック: node / git / claude の存在を確認し、なければ分かるエラーを出す（claude は起動する経路のときだけ）
