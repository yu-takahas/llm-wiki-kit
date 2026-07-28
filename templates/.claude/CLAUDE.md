# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ディレクトリ構造

```
00_issues/          進行中タスクの中断点メモ（git ブランチ感覚）
10_raw/             取り込み元・調査資料（案件単位は `<案件>/` サブディレクトリ可、横断調査は直下）
20_library/         本の目次 wiki + PDF 置き場（`books/` サブディレクトリに本体）
30_wiki/            wiki ページ（汎用知識、フラット運用）
40_project/         案件固有 wiki ページ（案件名サブディレクトリ）
50_feedback/        フィードバック（行動指針・作業観察・失敗事例）
90_reports/weekly/  週次アーカイブ
```

ライフサイクル: `10_raw/` → `30_wiki/`（汎用）または `40_project/<案件>/`（案件固有）→ `90_reports/weekly/`
ルート: `index.md`（wiki カタログ）/ `log.md`（操作履歴）/ `0_icebox.md`（ICEBOX）/ `1_issues.md`（WIP / TODO）/ `2_done.md`（FIXED / FADED）

## llm-wiki-kit への参照

`$KIT` = `__LLM_WIKI_KIT_PATH__`

このワークスペースを生成した llm-wiki-kit の場所（`setup.sh` が実パスを埋める。`__` で囲まれたままなら未設定なので、clone 先のパスに書き換える）。

skill / guide / rules が `$KIT/docs/...` を指しているのは、設計判断の why（`docs/lw-kit/`）と規範（`docs/knowledge/`）が kit 側にあるため。
`docs/lw-kit/` はワークスペースにコピーされない。`docs/knowledge/` は必要なものを手動で `30_wiki/` に取り込める。
kit を移動したらこの行を書き換える。削除した場合は設計書を辿れなくなるだけで、ワークスペースの運用自体に支障はない。

参照の書き分け: このワークスペース内のファイルは相対パス、kit 側のファイルは `$KIT` 起点で書く。

## wiki

- `.claude/rules/wiki.md`: wiki schema 規約（`30_wiki/` / `40_project/` 共通）
- `.claude/rules/wiki-style.md`: `30_wiki/` 配下のスタイル規約
- `.claude/rules/project.md`: `40_project/` 配下の案件固有規約

詳細は各ファイルを参照。

## 作業スタイル

セッション開始時に `50_feedback/feedback-指針-行動指針.md` を読む（作業スタイルから抽出した Claude の振る舞い指針）。

## log / index

成果物（wiki page / issue の状態 / 設定ファイル）が実質的に動いたら、`log.md` に 1 行追記する。
エントリは編集回数でなく成果物の変化で数える（1 セッション内で同じファイルを何度も編集しても 1 行にまとめる）。
`30_wiki/` / `40_project/` の page 増減・rename 時は `index.md`、`00_issues/` の出入り時は `1_issues.md` / `2_done.md` も更新する。
記入時の具体は `.claude/rules/log-index.md` が正本。
追記は Edit で行い、`cat >>` 等の Bash で書かない（Read が先行しないと上記 rule がロードされず、末尾確認の手順も効かない）。

### ターン終了前セルフチェック

ユーザー報告を返す前に必ず確認する:

- このターンで成果物が実質的に動いていれば `log.md` に記録されているか（編集回数でなく変化の単位で数える）
- page の増減 / rename があれば `index.md`、issue の出入りがあれば `1_issues.md` / `2_done.md` も更新したか
- 未記録があれば、いまここで追記してから報告

## 文書規約

- 文は `。` ごとに改行する
- 進行中タスクは `00_issues/<name>.md` に書く（issue のブランチ感覚、詳細は `.claude/rules/issue.md`）
- ファイルパス・glob・`_` や `*` を含む識別子・コマンド例示は **必ずコードスパン**（`` ` `` で囲む）で書く。
  例: `30_wiki/foo.md` / `10_raw/20260517_xxx.md` / `YYYYMMDD_*.md` / `Bash(rm *)`
  理由: prettier の Markdown formatter は単独 `_` を emphasis マーカーと解釈して `*` に正規化、逆に単独 `*` 同士をペアと認識して `_` に変換するため（CommonMark 仕様）。
- セクション参照に「§」を使わない（応答・思考含む）。書き方は「<節名>」セクション / 番号節は「セクション N」/ 入れ子は「「親」セクションの「子」」。citation の locator も「<section>」表記（§ 不使用）。「§」自体を語る言及（失敗事例・禁止例）は例外。
- wiki page / issue / library への参照は `[[link]]` で書く（パス `30_wiki/Foo.md` ではなく `[[Foo]]`）。
  パスは mv / rename で壊れるが、`[[link]]` なら Obsidian が自動追従する。
  解決: `find 00_issues/ 20_library/ 30_wiki/ 40_project/ -name "Foo.md"` でファイルパスが得られる。タイトルは全体で一意。
  例外: `.claude/` 配下のファイルは Claude Code が直接 Read する設定ファイルなのでパスで書く。
  例外: frontmatter `sources:` の `10_raw/` パスはパスのまま（`wiki.md` の規約通り）。
  例外: ディレクトリ自体の説明（「`30_wiki/` 配下の」等）やファイル名の例示はパスで書く。
- 口語的な比喩や属人的な言い方を使わず、何が起きるかを書く（「腐る」→「参照が解決しなくなる」/「〜に染み付いている」→「運用として定着している」）。文脈を持たない読者に読まれるため。
  対象は wiki page / 設計書 / rule / SKILL.md（issue と会話応答は作業ログなので除く）。

## Git

コミットメッセージは `type(project): 説明` 形式。

- type: `feat` / `fix` / `refactor` / `chore` / `docs`
- project: 作業の主旨で決める。
  - 案件・シリーズ主導の作業 → その案件 / シリーズのサブディレクトリ名（`40_project/<案件>/` 等）。
    過程で `30_wiki/` の汎用 entity を多く触っても、主旨が案件なら案件名を使う（変更数で上書きしない）
  - 汎用作業 → ナンバリングディレクトリ名から数字を落としたもの（例 `30_wiki/<title>.md` → `wiki`、`10_raw/<file>` → `raw`）
  - ルートファイル（`index.md` / `log.md` 等）→ ワークスペース名
  - 主旨が判然とせず複数にまたがる時のみ、変更数が最多の project を使う
