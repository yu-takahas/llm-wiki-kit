---
type: project
tags: [llm-wiki-kit, tutorial]
sources:
  - conversation
  - "[[lw-kit-要件定義-ペルソナ]]"
created: 2026-07-20
updated: 2026-07-26
---

# llm-wiki-kit のチュートリアル

新規ユーザーの初回体験を設計する。
目標: 30 分以内に「1 本 wiki を作る」成功体験を提供する。

## 前提

ユーザー像は [[lw-kit-要件定義-ペルソナ]] の P1 / P2。
共通前提は「Claude Code を使っている」こと。
skill / rule / ディレクトリ構造の意味は知らない。
Obsidian は使っていなくてもよい。

## 構成

README が担当する前段（セットアップ）と、issue 4 本の本編に分ける。

### README 担当（セットアップ）

1. README を読む
2. `setup.sh` を実行する

`setup.sh` は最後にワークスペースで Claude Code を起動し、話しかけ方の例を表示する。
ユーザーはそれを参考に Claude Code に話しかけるだけでチュートリアルが始まる。

### issue 1: 調べて書く

`00_issues/tutorial-01-first-wiki.md`

1 本 wiki を作る体験。

- `add-dir` で kit を追加する
- `/lw-research-doc` — テーマを調査 → `10_raw/` に保存
- `/lw-render` — 調査結果を `30_wiki/` に wiki 化（ここが成功体験のピーク）
- `/lw-update-issue` — この issue を更新する
- FIXED にする
- `/lw-commit` — commit

research のテーマは「自分のプロジェクトで使っている技術」を推奨するが、何を調べてもよい。

### issue 2: レビューして直す

`00_issues/tutorial-02-review.md`

issue 1 で作った wiki をレビューして改善する体験。

- `/lw-research-doc` — 別のテーマを調査 → `10_raw/` に保存
- `/lw-render` — wiki 化
- `/lw-doc-review` — wiki page をレビューする
- `/lw-cmux-teams` — fable を advisor として立ち上げ、レビュー結果を相談する
- `/lw-fix-review` — レビュー指摘を反映する
- `/lw-update-issue` — この issue を更新する
- `/lw-retro` — ここまでの振り返り
- FIXED にする
- `/lw-commit` — commit

### issue 3: 自分で好きにやって

`00_issues/tutorial-03-graduation.md`

自分のテーマで一通りの流れを自走する。卒業。

- `/lw-create-issue` — 自分の issue を切る

issue のテーマ例:

- P1 向け: 気になっていたテーマのナレッジ整理
- P2 向け: 自分の開発プロジェクトの設計メモ

- FIXED にする
- `/lw-commit` — commit

プログラミングをする場面では `/lw-tdd`（テスト駆動開発）も使える旨を紹介する。

### issue 4: 週次メンテナンス（溜まってきたらやる）

`00_issues/tutorial-04-weekly.md`

wiki がそこそこ溜まってきた頃にやる。スプリント終わりのメンテナンス作業。

- `/lw-lint` — broken link チェック
- `/lw-archive-weekly` — 週次アーカイブ

`/lw-sync`（kit 更新の取り込み）は未実装のため、このチュートリアルでは扱わない。実装はワークスペース側の issue で予定している。

TODO として置いておき、運用が回り始めたら取り組む。

## 設計判断

### issue 分割の狙い

4 本の issue で段階的にスキルを獲得する。

- issue 1: 調べて書く（research → render。最小のワークフロー）
- issue 2: レビューして直す（doc-review → fable 相談 → fix-review。品質改善のサイクル）
- issue 3: 自走（自分のテーマで一通り。ガイドなしでやれるか試す）
- issue 4: 週次メンテナンス（lint / sync / weekly。溜まってからやる方が学びがある）

### issue 1 の research → render が最重要区間

ジャーニーマップの「初体験」ステージに対応する。
research → render の流れで wiki を作るのが最初の実体験。
ここで成功体験を得られないと離脱する。
P2 は wiki 概念自体が初めてなので特に切実。

### issue 2 で fable を使う理由

doc-review → fix-review だけだとソロ作業で終わる。
cmux-teams で fable を立ち上げて相談する体験を入れることで、「1 人で判断に迷った時に advisor に聞ける」というワークフローを体感させる。

### 概念の段階的導入

全ディレクトリの意味を最初に説明しない。
各 step で触るディレクトリだけをその場で説明する。

- issue 1: `10_raw/`（調査結果の一次置き場）、`30_wiki/`（整理された知識の置き場）、`00_issues/`（進行中タスクのメモ）
- issue 4: `90_reports/weekly/`（週次のスナップショット）

`20_library/` / `40_project/` / `50_feedback/` は「使いたくなったら見てね」で十分。

`00_issues/.guide/` は教えない。
チュートリアルの 4 issue にコードを書くタスクがないため、配布する guide が初日には 1 本も該当しない。
guide の存在は、`/lw-create-issue` が起票時に該当するものを提案する形で伝える（[[lw-kit-詳細設計-guide]] の「起票時の導線」）。

### Obsidian の扱い

Obsidian がなくても全 issue が完走できる建て付けにする。
issue 1 の冒頭で「Obsidian があると `[[link]]` を GUI で辿れる（無くても動く）」と一言入れる。

### lint / weekly を初日にやらない理由

初日に実行しても実質 no-op になる（lint はヒットなし、weekly はほぼ空）。
溜まってからやる方が各 skill の価値が体感できる。
issue 4 として「スプリント終わりのメンテナンス」シナリオで体験させる。

### つまずきリカバリ

skill が起動しない / 出力先が想定と違う時のために、各 issue に「困ったらこの issue を開いたまま Claude に聞いてください」と記載する。

### issue のフォーマット

チュートリアル issue 自体が issue の書き方の見本になる。
4 セクション構造（進行中 / 中断点 / TODO / 経緯）で書き、TODO にステップをチェックリストとして列挙する。

### 移植対象の skill

チュートリアルで使う skill の全リスト。すべて `templates/.claude/skills/` に project-local として配置する（ワークスペースごとに独立なので global にする必要がない）。

- `lw-research-doc` / `lw-render` / `lw-update-issue`（旧 update-sketch）/ `lw-commit`
- `lw-create-issue`（旧 create-sketch）/ `lw-retro` / `lw-lint` / `lw-archive-weekly`
- `lw-tdd`（紹介のみ）
- `lw-code-review` / `lw-doc-review` / `lw-fix-review` / `lw-cmux-teams`

`lw-tdd` / `lw-code-review` はチュートリアルでは扱わないが、kit には同梱する。
`lw-sync` は未実装。実装はワークスペース側の issue で予定している。
