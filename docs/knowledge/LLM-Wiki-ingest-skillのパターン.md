---
type: synthesis
tags: [llm-wiki, ingest, skill-design, pattern]
sources:
  - "[[wiki-skills]]"
  - "[[claude-obsidian]]"
  - "[[karpathy-wiki]]"
  - "[[llmwiki]]"
created: 2026-05-15
updated: 2026-07-07
---

# LLM Wiki ingest skill のパターン

4 実装（[[wiki-skills]] / [[claude-obsidian]] / [[karpathy-wiki]] / [[llmwiki]]）の ingest skill 設計を横断調査した synthesis。
各実装の固有詳細は該当 entity page の「ingest skill 設計の深掘り」を参照。
本ページは「4 実装で一致するパターン」「分岐するパターン」「llm-wiki の選択」を集約する。

本ページの `ingest` / `/ingest` は調査当時の呼称。現在の skill 名と動作概念は `/lw-render` / render で、対応関係は 1 対 1。

## TL;DR

- 4 実装の共通核は「markdown prompt として書く / 議論してから書く / 書く前に読む / log は追記専用 / バックリンク走査」の 5 点
- llm-wiki の核心判断: 同期型 single agent、lead 手動レビュー、フラット日本語タイトル、矛盾は frontmatter `contradictions:` に保持
- 借りない設計: 並列化、SQLite、embedding、自動 commit hook、status state machine
- 後続: 本ページの 12 要件を満たす llm-wiki 固有の SKILL.md は別 synthesis で展開

## 共通パターン（4 実装で一致）

### 1. ingest workflow は markdown prompt で記述

コードではなく SKILL.md / GUIDE_TEXT に prompt として書く。

4 実装すべて、ingest の本体はコードではなく markdown ファイルに書かれている。

- [[wiki-skills]]: `skills/wiki-ingest/SKILL.md`
- [[claude-obsidian]]: `skills/wiki-ingest/SKILL.md` + `agents/wiki-ingest.md`（二重実装）
- [[karpathy-wiki]]: `skills/karpathy-wiki-ingest/SKILL.md`(428 行、最大)
- [[llmwiki]]: `mcp/tools/guide.py:154-162` の `GUIDE_TEXT`

含意: llm-wiki も SKILL.md ベースで自然、コード化不要。

### 2. 波及範囲の期待値を明示

「1 source → N pages」を description に書いて LLM の自己監視を起動する。

"One ingest may touch 10-15 wiki pages" / "5-15 wiki pages — that's expected" のような文言。

含意: llm-wiki も明示する（1 raw → wiki 5-10 pages 程度）。

### 3. 議論してから書く順序

書く前にユーザーに要点を提示し、強調すべき点 / 削るべき点を確認してから着手。

- wiki-skills: step 3 で "BEFORE writing anything" + 原文ママ質問 + 待機指示
- [[claude-obsidian]]: step 2 で "What should I emphasize?" + `just ingest it` 逃げ道
- [[karpathy-wiki]]: orientation 後にユーザー確認
- [[llmwiki]]: step 2 で議論

含意: 「読む → 既存と矛盾チェック → ユーザーに要点提示 → 書く」を厳格化。逃げ道（`just ingest`）も入れる。

### 4. 書く前に読む（read-before-write）+ 既存に追加（in-place merge）

既存 page を必ず読んでから追加、上書きせず追加、時系列追記（`## YYYY-MM-DD 追記`）も禁止。

- [[karpathy-wiki]] Iron Law 2: `NO PAGE EDIT WITHOUT READING THE PAGE FIRST`
- wiki-skills の「よくあるミス」第 1 項: 時系列追記セクションを増やすな

含意: llm-wiki でも採用必須。既存 page への追加 + frontmatter `updated` + log 記録の三点セット。

### 5. log は追記専用（append-only）

log は履歴記録、過去エントリは触らない、新エントリで上書きする。

4 実装すべて log.md は追記専用。[[llmwiki]] は `delete.py:8` の `_PROTECTED_FILES` で強制制約、[[karpathy-wiki]] は markdown + JSONL の二層追記専用。

含意: llm-wiki は既に追記専用規約あり（[[lw-kit-詳細設計-log-index]]）。継続。

### 6. 「新規生成は無確認 / 既存変更は要確認」の二分原則

新規作成と log / report への追記は自走、既存編集は diff 提示 + ページごとの確認。

[[wiki-skills]] が 5 skill 横断で明示、他 3 実装も実態同じ。

含意: llm-wiki でも採用、lead / worker 文化と整合。

### 7. バックリンク走査と影響範囲報告

ingest 完了時に「他 page への影響」を出力、双方向リンクを維持する。

- wiki-skills: step 7「backlink audit — do not skip」二重警告
- [[llmwiki]]: write 完了時に `_get_wiki_impact()` で「N pages reference this」を返す
- [[claude-obsidian]]: orchestrator が並列 agent の返却から index / log / hot を統一更新
- [[karpathy-wiki]]: 漏れたクロスリンク検査が step 7.5 で独立

含意: ingest 完了時に「この wiki page を参照している他 page 一覧」を出力する。

### 8. schema は 1 箇所、ingest skill は参照のみ

schema 定義は別ファイルに集約、SKILL.md からは「重複させるな」命令で参照する。

- [[karpathy-wiki]]: `references/page-conventions.md` に分離、SKILL.md から `Do not duplicate that schema here` 命令
- wiki-skills: SCHEMA.md（wiki-init が生成）
- [[llmwiki]]: `_PROTECTED_FILES` で守る

含意: llm-wiki は既に rules の wiki schema（[[lw-kit-詳細設計-rules]]）として分離済み。`/ingest` SKILL.md は参照のみ、複製しない。

### 9. 数値で決め、ベクトルに頼らない

本文長下限 / ページ分割 / 波及範囲などを数値で明文化、embedding は壊れるまで導入しない。

- [[karpathy-wiki]]: 本文長下限 (1000/1500 byte)、ページ分割 (2+ sources OR > 200 行)、index 分割 (~200 entries / 8KB)、上位 7 候補
- wiki-skills: lint 頻度 "Run after every 5-10 ingests"
- [[llmwiki]]: MAX_CHUNK_CHARS = 10_000

[[karpathy-wiki]] が最も明示: 「壊れるまで vector search を入れない」原則。

含意: llm-wiki でも初版で 3-4 個の数値閾値を明文化。embedding 不要。

## llm-wiki 固有の制約

- `raw` frontmatter なし（YYYYMMDD\_<title>.md 形式、Web Clipper の frontmatter は保持）
- `wiki` は 6 fields frontmatter（type / title / tags / sources / created / updated）
- `[[wiki-link]]` 構文、フラット運用、O(1) lookup（パス解決不要）
- SQLite / index DB なし、grep + plain text
- remote push なし

## 分岐パターン（llm-wiki の選択）

| 設計軸             | [[wiki-skills]]        | [[claude-obsidian]]            | [[karpathy-wiki]]              | [[llmwiki]]          | llm-wiki 選択                      |
| ------------------ | ---------------------- | ------------------------------ | ------------------------------ | -------------------- | ---------------------------------- |
| ingest 実装        | 単一 main              | 二重（main / 並列 sub）        | 別プロセス起動（非同期）       | MCP tool             | 単一 main                          |
| 並列化             | なし                   | あり（DragonScale + manifest） | あり（別プロセス起動）         | なし                 | なし                               |
| log 形式           | 2-3 行 / skill 差      | 構造化レポート                 | markdown + JSONL 二層          | markdown             | 既存 3 カラム markdown             |
| index 更新         | skill 内自動           | orchestrator 統一              | 後処理                         | guide prompt         | lead 手動レビュー                  |
| 議論ステップ       | 必須                   | 必須 + `just ingest` 逃げ道    | 必須                           | 必須                 | 必須 + 逃げ道                      |
| slug 化            | あり（小文字ハイフン） | あり                           | フラット想定                   | パス解決             | 不採用（日本語タイトル保持）       |
| エラーハンドリング | 最小                   | hook bug 警告                  | 階層化 stale threshold         | status state machine | 最小 + lead 投げ                   |
| 矛盾の扱い         | callout                | callout                        | frontmatter `contradictions:`  | 明示なし             | frontmatter `contradictions:`      |
| schema 場所        | SCHEMA.md（自動生成）  | references/                    | references/page-conventions.md | guide.py prompt      | rules（[[lw-kit-詳細設計-rules]]） |

### 主要な分岐の根拠

- 同期型 single agent: llm-wiki は個人用、raw → wiki 頻度低、並列化の保守コスト > 利得
- lead 手動レビュー: 厳守事項として既に決定。skill 出力は下書き、追記は lead 判断
- フラット運用 + 日本語タイトル: 既決定（[[lw-kit-詳細設計-rules]]）
- `contradictions:` frontmatter: karpathy 方式、ingest 中に解決しない（資源節約 + 判断は別タイミング）

## `/ingest` skill が満たすべき要件

各要件の末尾に対応する「llm-wiki 流の工夫候補」（後述）の番号を `→ 工夫 N` で示す。
共通由来 / llm-wiki 制約由来は出典を明示。

1. SKILL.md 冒頭の `description` フィールド（"Use when..." + 波及範囲の期待値）+ 言い訳対戦表（resist-table） → 工夫 1, 6
2. 事前条件で wiki.md 参照、raw 素材の存在確認、同名 wiki page 既存時の分岐 → 工夫 2
3. 議論ステップ（逃げ道あり） → 工夫 7
4. 書く前に読む（read-before-write）厳守、既存に追加（in-place merge） → 工夫 4
5. 矛盾は frontmatter `contradictions:` に残す、ingest 中に解決しない → 工夫 4
6. バックリンク走査必須、二重警告 → 共通 7 由来
7. 影響範囲報告（参照元ページのリスト） → 工夫 8
8. log / index は下書きのみ提示、lead が追記判断 → llm-wiki 制約由来
9. よくあるミス（Common Mistakes）セクション 4 項目以上 → 共通由来（wiki-skills の偏在パターン）
10. 言い訳対戦表（llm-wiki 固有 4 項目） → 工夫 1
11. 引用は本文内に書く軽量形式（例: `(raw セクション 2)`） → llm-wiki 流（工夫候補に直接対応なし）
12. 数値閾値 3-4 個明文化（本文長下限 / ページ分割 / 波及範囲の期待値） → 工夫 5

### llm-wiki 初版の暫定数値閾値

別 synthesis で確定する想定の暫定値。括弧内は参考にする 4 実装の数字。

- 本文長下限: 未定（karpathy 1000-1500 byte 参考）
- ページ分割: 未定（karpathy 2+ sources OR > 200 行 参考）
- 波及範囲の期待値: 1 raw → wiki 5-10 pages（共通 2 既出）
- lint 頻度: 未定（wiki-skills 5-10 ingest ごと参考）

### よくあるミスの候補（後続 SKILL.md への転記用）

要件 9 の「よくあるミス」セクションに最低限載せる候補。後続 synthesis で 4 項目以上に確定させる。

1. 既存 wiki page を読まずに上書きする（共通 4 違反）
2. 時系列追記（`## YYYY-MM-DD 追記`）でセクションを増やす（共通 4 違反）
3. 矛盾を見つけて消す、または無視する（`contradictions:` frontmatter に残さない）
4. バックリンク走査を省略する（共通 7 違反）
5. lead レビュー前に log / index へ追記する（llm-wiki 厳守事項違反）
6. raw 原文を言い換えで済ます、自分の synthesis を書かない

## llm-wiki 流の工夫候補（4 実装からの組合せ）

要件側からは番号で参照される（前セクション）。

1. 言い訳対戦表（resist-table）を冒頭に書く（karpathy 方式）
   - 「issue のまま放置」「軽すぎる」「あとで ingest」「raw を言い換えで済ます」の言い訳と現実を対戦表化
   - LLM の自己監視を最も強く揺さぶる装置
2. schema を 1 箇所に集約 + `Do not duplicate` 命令（karpathy 方式）
3. 文章ルールを script で二重強制（karpathy 方式）
   - frontmatter 6 fields 必須は markdownlint or 軽量 script で強制制約
4. 書く前に読む + 既存に追加 + 矛盾保持（4 実装共通）
5. 数値閾値の明文化（karpathy 方式）
   - 本文長下限 / ページ分割 / 波及範囲の期待値の 3-4 個を初版で決める
6. 1 行プレフィックスで告知（karpathy 方式）
   - `Using /ingest skill to ingest 10_raw/<file>.md` でフェーズ可視化
7. 議論ステップ + `just ingest` 逃げ道（[[claude-obsidian]] 方式）
8. 完了時に影響範囲報告([[llmwiki]] 方式)
9. delete-and-rebuild 方式の参照同期（[[llmwiki]] 方式、llm-wiki は index.md の再構築で代替）
10. 二段階 synthesis 階層（llm-wiki 流）
    - 段階 1: 本ページ（4 実装横断、外部知識）
    - 段階 2: llm-wiki 固有判断（[[lw-kit-詳細設計-CLAUDE.md]] と同じ二段階階層、外部知識 → 固有設計）

## llm-wiki が借りない / 避ける設計

| カテゴリ     | 要素                                                                                                   | 避ける理由                                                           |
| ------------ | ------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------- |
| 並列・非同期 | 別プロセス起動の ingester / 並列 sub-agent + manifest lock / status state machine                      | llm-wiki は同期型 single agent、規模に対して overkill                |
| index 高度化 | SQLite index / embedding / DragonScale address counter / 三段 lookup フォールバック                    | plain text + grep + フラット namespace で十分（500+ page まで保留）  |
| 自動化       | filesystem watcher / 自動 commit hook                                                                  | 能動 ingest（LLM 呼び出し）で完結、1 ingest = 1 意図的 commit を保つ |
| 視覚要素     | Obsidian の callout（`> [!type]` 形式の強調引用、Obsidian で色やアイコンで装飾される）の見た目への依存 | `> [!contradiction]` 構文だけ借りる、装飾は不要                      |
| スコープ外   | HTTP upload / community footer                                                                         | llm-wiki の用途では不要                                              |

## 次のステップ

詳細な step 設計と SKILL.md 本文は llm-wiki 固有の synthesis page で別途展開する。
本ページの 12 要件を満たす実装方針 / 数値閾値の確定値 / よくあるミスの最終リスト / 言い訳対戦表の確定文言 を、後続 synthesis に集約する。

## 関連

- [[LLM-Wiki]] — パターン本体
- [[wiki-skills]] / [[claude-obsidian]] / [[karpathy-wiki]] / [[llmwiki]] — 各実装の詳細（「ingest skill 設計の深掘り」セクション参照）
- [[lw-kit-詳細設計-log-index]] — log / index の更新タイミング
- [[Claude-Code-Skillの書き方]] — SKILL.md のベストプラクティス
- [[lw-kit-詳細設計-CLAUDE.md]] — 同じ二段階 synthesis 階層の先例（concept = メモリ階層 / synthesis = CLAUDE.md 設計）
- [[lw-kit-詳細設計-rules]] — rules の構成（schema 規約、重複させない）
