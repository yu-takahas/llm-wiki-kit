---
paths:
  - "10_raw/**"
  - "30_wiki/**/*.md"
  - "40_project/**/*.md"
---

# wiki

llm-wiki の構造規約。
`30_wiki/` と `40_project/` に共通するスキーマ・命名・リンク・本文制約を定める。
配置場所固有の規約は `wiki-style.md`（`30_wiki/`）と `project.md`（`40_project/`）を参照。

## frontmatter（wiki 側、5 fields）

```yaml
---
type: concept | entity | source | synthesis | project
tags: [<tag1>, <tag2>, ...]
sources: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

## sources field の中身

配列、要素は次のいずれか:

- `10_raw/<file>` — raw 側のパス
- `"[[<page-title>]]"` — wiki 内 page 参照（YAML で `[[` は配列開始と衝突するため引用符必須）
- `<URL>` — live URL
- `conversation` — リテラル
- `[]` — 空（メタ・雛形）

## ファイル名

- `30_wiki/<タイトル>.md`: フラット運用、サブディレクトリなし
- `40_project/<案件>/<タイトル>.md`: 案件名サブディレクトリ、内部はフラット（詳細は `project.md`）
- 共通: 日付プレフィックス禁止（`created` で代替）

### 文字種規約

- 半角 space 禁止、`_` 禁止
  - space 禁止理由: terminal / 各種ツールでクォート必須、grep / 補完で扱いにくい
  - `_` 禁止理由: prettier の Markdown formatter が `_` を emphasis マーカーと解釈、H1 や `[[link]]` 内で `\_` エスケープが入る
- 英単語間の半角 space は `-` に置換（例: `Chain of Thought` → `Chain-of-Thought.md`）
- 日本語に隣接する半角 space は削除（例: `Claude Code Skill の書き方` → `Claude-Code-Skillの書き方.md`）
- 日本語タイトルはそのまま維持（ASCII 化しない）

## type 一覧

- `concept`: 抽象概念・パターン・手法
- `entity`: 固有名詞（人 / 組織 / プロダクト / リポジトリ / 論文 / 公式フレームワーク / 命名された原則）
- `source`: raw を render した要約 page（raw との対関係を保つ）
- `synthesis`: 複数 source / entity を横断統合した分析・比較・設計
- `project`: 案件本体、および llm-wiki ワークスペース自身（meta-project）の wiki page（`40_project/<案件>/` の case root、ロードマップ・現状・方針を集約）

### 判定の境界

- entity vs concept: 論文 / プロダクト / 人 / 組織 / 公式フレームワーク名 / 命名された原則と紐づくか。紐づけば entity、紐づかない一般概念は concept（提唱者がいても概念名として扱いたいものは concept、実体は別 entity に分ける）
- source vs synthesis: 1 つの raw（または密接に関連する raw 群）を要約・再構成 → source、複数の source / entity を横断統合 → synthesis
- entity vs project: llm-wiki ワークスペース外の固有物 → entity（`30_wiki/`）、llm-wiki が扱う案件本体および llm-wiki ワークスペース自身（meta-project）→ project（`40_project/<案件>/`）

type 判定はここで完結する。

## cross-link

本文内で `[[<タイトル>]]` 形式。基本原則は CLAUDE.md の文書規約を参照。

- エイリアス記法 `[[target|display]]` は使わない
- link 化は index.md に実在するタイトル、または今後作成する意図のある page に限る（対象が存在せず作成予定もないなら素テキスト）

### broken link チェック対象外

次のパターンは broken link 検出対象外（false positive 抑止）。Obsidian の振る舞いとも一致:

- placeholder（`[[<...>]]` 形式の angle-bracket で囲まれたテンプレート埋め込み用、例: `[[<page-title>]]` / `[[<concept>]]`）
- コードフェンス（` ``` ` 〜 ` ``` `）内の `[[...]]`（マークダウン例示、Obsidian も link 解釈しない）
- コードスパン（バックティックで囲んだ範囲）内の `[[link]]`（link 例示として使う場合、Obsidian も link 解釈しない）
- `10_raw/` 配下のファイル全体（raw 保持原則で外部 quote / Web Clipper 等の `[[...]]` をそのまま含むことがあるため、wiki link 規約の対象外）

## 本文の制約

wiki page は永続的な知識を保持する。
流動的な来歴・出典・時系列は本文ではなく frontmatter `sources:` / `log.md` / issue / commit に分離する。

### 出典を書かない

`30_wiki/` / `40_project/<案件>/` の wiki page 本文に「出典: 〜セッションで〜した実例」のような出典付記を書かない。
参照ソースは frontmatter `sources:` だけで完結させる。
本文出典は日付 / セッション名を含みがちで、永続的な知識として読まれるべき wiki page に流動的な来歴情報を混ぜることになる。

### 来歴を書かない

「元々 X する予定だったが Y に移管」式の検討経緯・時系列を書かない。
判断の理由（why）は残し、履歴（いつ何を経てこうなったか）は消す。来歴は log / issue が持つ。

### 時系列ログを蓄積しない

日付付きの蓄積型ログ（決定ログ / 変更履歴 / セッション別の採否リスト / 作業記録等）を本文に書かない。
日付でグルーピングされたリストやテーブルが増え続ける形式は、wiki page ではなく log / issue / commit が持つ。
「来歴を書かない」が 1 回きりの経緯混入を禁じるのに対し、こちらは行が増え続ける蓄積パターンを禁じる。

例外: 事例集（番号付き事例の蓄積、[[feedback-観察-失敗事例]] 等）、作業スタイル台帳（日付付き事例行の蓄積、[[feedback-観察-作業スタイル]]）、投稿記録（日付が本質的な情報）は時系列が本質的に必要なので対象外。

## raw side（`10_raw/`）

frontmatter なし。ファイル名そのまま（Web Clipper 等で frontmatter が既に付いていれば保持、削らない）。
