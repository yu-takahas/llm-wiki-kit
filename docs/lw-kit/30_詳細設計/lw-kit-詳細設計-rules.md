---
type: synthesis
tags: [claude-code, rules, llm-wiki-kit, design]
sources:
  - conversation
  - "[[lw-kit-詳細設計-CLAUDE.md]]"
  - "[[Claude-Codeのメモリ階層]]"
created: 2026-05-25
updated: 2026-07-07
---

# llm-wiki-kit の rules 設計

`.claude/rules/` の設計・運用・改訂の起点ページ。
rule の新設・改訂・責務の切り分けに迷った時に読む。
[[lw-kit-詳細設計-CLAUDE.md]] が CLAUDE.md を担うのと対で、本ページは rules を担う。
Claude Code の rules / memory 一般論は [[Claude-Codeのメモリ階層]]、本ページは llm-wiki-kit 固有の決定。

## 責務分担

rule をどこに書くかは、4 つの置き場の境界で決める。

| 置き場                   | 持つもの                              | 性質                                 |
| ------------------------ | ------------------------------------- | ------------------------------------ |
| rules (`.claude/rules/`) | 規約・判定（こう書け / こう判定せよ） | 常に正しく保つ、`paths` で条件ロード |
| wiki (`30_wiki/`)        | 設計思想・背景・なぜその設計か        | 設計記録、判断の経緯                 |
| `.claude/CLAUDE.md`      | ワークスペース全体の普遍 index        | 何をどこで管理するかの地図           |
| auto memory              | ユーザー個人の好み                    | 全プロジェクト横断で常時ロード       |

中核の原則は、判定・規約は rules、設計思想・背景は wiki に分けること。
wiki の設計記録は判断時点のスナップショットで後から更新されないため、規約をそこに置くと定義だけが古いまま取り残される。
実例として、wiki の type 判定ラインを wiki に同居させたところ、判定基準が更新されず古いまま残った。

## 現在の rules 構成

| rule                  | paths                                                                                    | 役割                                                                                                                            |
| --------------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `wiki.md`             | `10_raw/**` / `30_wiki/**/*.md` / `40_project/**/*.md`                                   | wiki schema（frontmatter 5 fields / ファイル名・文字種 / type / cross-link / 本文規約: 出典禁止・来歴禁止・時系列ログ蓄積禁止） |
| `wiki-style.md`       | `30_wiki/**/*.md`                                                                        | `30_wiki/` のスタイル規約（issue 参照禁止 / リスト太字禁止 / 英単語混じり / Edit 規律）                                         |
| `project.md`          | `40_project/**/*.md`                                                                     | 案件固有 wiki 規約（サブディレクトリ / case root と派生 page / 置き場判断）                                                     |
| `issue.md`            | `00_issues/**`                                                                           | issue 編集規律（作成 / 内部構造 / merge・廃棄時の確認）                                                                         |
| `log-index.md`        | ルート 5 ファイル（`log.md` / `index.md` / `0_icebox.md` / `1_issues.md` / `2_done.md`） | log の記入規約（フォーマット / type 一覧 / 更新トリガー / append-only / リポジトリ境界）                                        |
| `skeleton-confirm.md` | なし（常時ロード）                                                                       | 新規作成・大きい修正の骨子確認（宣言・プロファイル・知見の事前ロード含む）                                                      |

`paths` はそのファイルが条件付きロードされる対象ディレクトリの glob、なし（常時ロード）は全作業で読み込まれる。

## 粒度・分割・paths 設計

- 基本は `paths` 単位で 1 ファイル（wiki は `30_wiki/`、project は `40_project/`、issue は `00_issues/`）
- 複数ディレクトリ横断の規約は 1 ファイルに集約する（wiki schema は raw / wiki / project にまたがるので `wiki.md` 1 つ）
- 1 ファイルの主題が肥大したら、独立した判定・規約を別ファイルに切り出す

| ロード方式           | 使いどころ                                                   |
| -------------------- | ------------------------------------------------------------ |
| `paths` あり         | そのディレクトリで作業する時だけロード、context 圧迫を避ける |
| `paths` なし（常時） | 全作業に共通する規律（骨子確認のような作業手順）             |

特定ディレクトリの編集にだけ効く規約は `paths` で絞り、作業ディレクトリを問わず効く規律だけ `paths` なしにする。

## wiki / auto memory から rules への昇格

- auto memory vs rules の判断は [[Claude-Codeのメモリ階層]]「使い分けの判断」セクション参照
- wiki に書いた設計思想のうち、判定・規約として固まったものは rules に昇格させる

## 他 page からの参照

本 page が rules への参照を集約するハブ。パターンの詳細は [[lw-kit-詳細設計-CLAUDE.md]]「他 page からの参照」セクション参照。

## 検算チェックリスト

rule を新設・改訂した後に確認する。

- `paths` は作業ディレクトリと一致しているか（常時ロードが本当に必要なものだけ `paths` なしにしているか）
- 規約・判定が wiki の設計記録に残っていないか（残っていれば rules に移す）
- CLAUDE.md に rules の詳細を書き写していないか
- auto memory にワークスペース固有の規約が紛れていないか

## 関連

- [[lw-kit-詳細設計-CLAUDE.md]]: CLAUDE.md の設計、本ページの対
- [[Claude-Codeのメモリ階層]]: Claude Code の rules / memory 一般論
- `.claude/rules/` 配下の各 rule ファイル
