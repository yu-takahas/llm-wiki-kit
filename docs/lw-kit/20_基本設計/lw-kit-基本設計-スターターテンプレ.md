---
type: project
tags: [llm-wiki-kit, templates]
sources:
  - conversation
  - "[[lw-kit-基本設計-ディレクトリ構成]]"
created: 2026-07-20
updated: 2026-07-20
---

# llm-wiki-kit のスターターテンプレ

`setup.sh` がワークスペースに生成する初期ファイル群の雛形。

## テンプレ一覧

`templates/` 配下に置く初期ファイル:

- `index.md` — wiki カタログ（MOC）
- `log.md` — 操作履歴
- `0_icebox.md` — ICEBOX 一覧
- `1_issues.md` — WIP / TODO 一覧
- `2_done.md` — FIXED / FADED 一覧
- `00_issues/tutorial-01-first-wiki.md` — チュートリアル issue 1
- `00_issues/tutorial-02-review.md` — チュートリアル issue 2
- `00_issues/tutorial-03-graduation.md` — チュートリアル issue 3
- `00_issues/tutorial-04-weekly.md` — チュートリアル issue 4
- `00_issues/.guide/` — `dev-guide.md`（アプリ開発 issue 用の手順メニュー）。初期配布はこの 1 本のみ。機構は [[lw-kit-詳細設計-guide]]
- `20_library/library.md` — 書籍管理の説明
- `30_wiki/.doc-review.md` — wiki page のレビュー宣言
- `50_feedback/` — フィードバックテンプレ

## index.md 雛形

```markdown
# index

wiki ページのカタログ（Map of Content）。

## 30_wiki/

（wiki page が増えたらここに追加）

## 40_project/

（案件 page が増えたらここに追加）
```

空の状態から始める。
page を追加するたびに追記する運用は CLAUDE.md のセルフチェックで担保される。

## log.md 雛形

```markdown
# log

操作履歴。append-only。

- [YYYY-MM-DD] init | . | setup.sh で生成
```

初期エントリとして `setup.sh` の実行記録を 1 行入れる。

## issue 一覧ファイル（0_icebox / 1_issues / 2_done）

```markdown
# 1_issues

## WIP

（進行中の issue）

## TODO

（着手待ちの issue）
```

各ファイルは空セクションのみ。
チュートリアル issue を同梱するため、`1_issues.md` の WIP に tutorial-01〜03、TODO に tutorial-04 が入る。
tutorial-01〜03 は `00_issues/` 直下（WIP）、tutorial-04 は溜まってからやるメンテナンスなので TODO。

## 50_feedback/ テンプレ

フィードバックの骨組みと空テンプレ。
フィードバック運用の実績をテンプレ化する。

### 構成

- `feedback.md` — フィードバックループ全体のハブ。命名規則を記す
- `feedback-観察-作業スタイル.md` — user が Claude Code と作業する時の振る舞いパターンの台帳テンプレ（空、フォーマットのみ）
- `feedback-観察-失敗事例.md` — 踏み抜いた失敗パターンと対策の記録テンプレ（空、フォーマットのみ）
- `feedback-観察-特性プロファイル.md` — user 本人の性格・心理特性を整理するテンプレ（空、フォーマットのみ）
- `feedback-指針-行動指針.md` — 観察 2 本（作業スタイル / 特性プロファイル）から抽出する行動指針テンプレ（実運用の 33 項目から汎用的なものを抽出）
- `feedback-プロファイル-wiki.md` / `feedback-プロファイル-エッセイ.md` / `feedback-プロファイル-技術ブログ.md` / `feedback-プロファイル-設計書.md` — `/lw-doc-review` が参照する文書種別ごとのレビュープロファイル（読み手の定義・成功基準）

### 行動指針テンプレの方針

33 項目すべてを移植するのではなく、llm-wiki-kit のユーザーが共通で使える汎用的な指針のみを残す。
特定個人の特性に紐づく指針（例: 正論回避、休憩提案しない等）は除外する。

残す例:

- 設計書と実装の二重管理を避ける
- スコープ外は別 issue に切る
- 推測でなく実物で判断

除外する例:

- 正論で追い詰めず選択肢で迂回する（個人特性）
- 休憩提案を自発的にしない（個人好み）
