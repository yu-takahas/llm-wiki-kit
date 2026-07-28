---
type: entity
tags: [implementation, llm-wiki, claude-code]
sources:
  - https://github.com/kfchou/wiki-skills
  - github/wiki-skills/
created: 2026-05-14
updated: 2026-07-07
---

# wiki-skills

Andrej-Karpathy の LLM Wiki パターンを Claude Code プラグインとして実装したリポジトリ。
llm-wiki-kit のベース実装に採用。

## 主要属性

- **作者**: kfchou
- **規模**: 159 stars / 25 forks、9 commits（2026-07-01 時点）
- **形態**: Claude Code plugin（純正）
- **依存**: Claude Code のみ（Obsidian / 外部 LLM / MCP すべて不要）
- **最終コード更新**: 2026-05-10

## リポジトリ構造

```text
wiki-skills/
├── .claude-plugin/{marketplace.json, plugin.json}
├── README.md
└── skills/
    ├── wiki-init/{SKILL.md, codebase.md}
    ├── wiki-ingest/SKILL.md
    ├── wiki-query/SKILL.md
    ├── wiki-lint/SKILL.md
    ├── wiki-update/SKILL.md
    └── wiki-audit/SKILL.md
```

`SCHEMA.md` はリポジトリには **存在しない**。
`wiki-init` がユーザー側の wiki ルートに生成する文書。

## init が生成するディレクトリ構造

```text
<wiki-root>/
├── SCHEMA.md         ← conventions + 絶対パス（他 skill が wiki を見つける標識）
├── raw/              ← 不変、人間が放り込む source
├── wiki/
│   ├── index.md      ← page カタログ、カテゴリ別
│   ├── log.md        ← append-only operation log
│   ├── overview.md   ← evolving synthesis
│   └── pages/        ← **フラット、サブディレクトリ禁止**、slug-named
└── assets/           ← downloaded images, PDFs
```

## 共通: 全 skill の前提

全 skill が冒頭で `SCHEMA.md` を探す（cwd から上方探索、または `~/wikis/`）。
見つからなければ「`wiki-init` を先に実行してください」と返す。
SCHEMA.md から wiki root path / frontmatter format / citation 規約 / log 形式 / index カテゴリを読む。

## 各 skill の挙動

### wiki-init

1. ユーザーに 4 つ質問（path / domain / source types / index categories）
2. ディレクトリ構造作成
3. `SCHEMA.md` を書く（identity / frontmatter / cross-ref / citations / log entry format / index categories / conventions）
4. `wiki/index.md` を書く（カテゴリ見出しのみ）
5. `wiki/log.md` を書く（init エントリ付き）
6. `wiki/overview.md` を書く（後述の雛形）

研究 default のカテゴリ: `Sources | Entities | Concepts | Analyses`。
codebase default: `Modules | APIs | Decisions | Flows`（`codebase.md` で詳細）。

### wiki-ingest（11 step）

1. source 受け取り（file path / URL / pasted text）
2. 完読（長尺は section 分割）
3. **書く前に** takeaway 3-5 点・新出 entity/concept・矛盾候補をユーザーに提示、emphasize 確認
4. slug 生成（lowercase, hyphen, no special chars）
5. `wiki/pages/<slug>.md` 書き出し（summary / key takeaways / entities & concepts / relation to other pages）
   5b. **citation を書きながら付ける**（後追いではない、common-knowledge は除外）
   5c. self-check（unfootnoted な factual claim を再走査）
6. entity / concept page 更新（既存なら追記、なければ生成）
7. **backlink 監査**（全 pages を scan、新 source の entity に言及してるけどリンクしてないページに `[[new-slug]]` 追加）
8. `wiki/index.md` に該当カテゴリへエントリ追加
9. **`wiki/overview.md` 更新**（後述）
10. `wiki/log.md` に append

### wiki-query

1. `wiki/index.md` を先に読む
2. 関連 page 完読、`[[link]]` を 1 レベル辿る
3. 引用付き合成（factual → 散文、comparison → 表、how-it-works → 番号付き、what-do-we-know → 構造化要約 + open questions）
4. **常に save 提案**: "Worth saving as `wiki/pages/<slug>.md`?"

### wiki-lint

ページ inventory → 全 check 走査 → severity 分類した `wiki/pages/lint-<date>.md` を **無条件で書く**（offer 不要）。
concrete fix を 1 項目ずつ提案、diff を見せてから書く。

### wiki-update

ページ単位の改訂。

- 必ず `Current / Proposed / Reason / **Source**` の 4 点を提示
- 1 page ずつ confirm before write
- 下流チェック: `[[slug]]` で grep して影響範囲提示
- contradiction sweep: 同じ claim が複数 page にあるかチェック
- overview.md に波及する場合は提案

### wiki-audit

2 phase 構造、1 page /run。

- **Phase A**（1 subagent）: 該当ページ全文 + SCHEMA citation 規約 + sources list を渡し、unfootnoted factual claim を `(line, claim, suggested source)` で返させる
- **Phase B**（N subagent 並列）: footnote ごとに target 解決 → **ファイル単位で group** → PDF を 1 度読んで複数 footnote を検証（PDF 高コスト対策）
- verdict: ✅ supported / ❌ unsupported / ⚠️ partial / 🚫 source-missing

`wiki/pages/audit-<slug>-<date>.md` を書く。

## overview.md の生涯（最重要）

llm-wiki でもこの挙動を踏襲する想定。

### init 時の雛形

```markdown
---
tags: [overview, synthesis]
sources: []
updated: <today>
---

# <Domain> — Overview

> Evolving synthesis of everything in the wiki. Updated by wiki-ingest when sources shift the understanding.

## Current Understanding

*No sources ingested yet.*

## Open Questions

*Add questions here as they arise.*

## Key Entities / Concepts

*Populated as pages are created.*
```

### ingest が更新する条件（step 9）

ingest 完了時に現在の overview.md を読み直し、新 source が:

- **significant concept** を導入 → `Key Entities / Concepts` に追加
- **理解全体を shift** → `Current Understanding` を更新
- **新しい問い** を提起 → `Open Questions` に追加

frontmatter の `updated` 日付を更新。

### 結論

overview.md は **人間メンテではなく ingest が自動更新する生きたページ**。
ただし全 ingest で必ず更新されるわけではない（"sources shift the understanding" が条件）。
update / lint / audit も波及する場合は overview.md を改訂候補に含める。

## citation 規約

cite every non-common-knowledge factual claim。
"common knowledge" = うんちく不要な undergraduate-level の事実。
granularity は段落 or claim 単位、per-sentence ではない。

### 2 種の citation

**Quote citation**（推奨）:

```
The model uses 8 attention heads.[^1]

[^1]: attention-is-all-you-need §3.2.2 — "We employ h = 8 parallel attention layers"
```

**Synthesis citation**（単一 quote で捉えられない時）:

```
The architecture is fundamentally an encoder-decoder with attention.[^2]

[^2]: attention-is-all-you-need §3.2-3.4 [synthesis] — encoder, decoder, and
      attention sections together describe the full multi-head architecture
```

### 3 つの valid target

1. `[[source-slug]]` — source-type の wiki page（ingest 済 source）、推奨
2. `raw/<file>` or `assets/<file>` — local file path（drive-by citation 用）
3. `<URL>` — live URL, tweet, ephemeral source（no local copy）

entity / concept / analysis page は cite 不可（それ自体が synthesis なので）。

### 必須要素

- **locator**: `§<section>`, `p.<n>`, `[HH:MM:SS]`, URL anchor, `(YYYY-MM-DD)` のいずれか
  - ※ llm-wiki で採用する場合、locator の `§<section>` は使わず「<section>」表記に置換する（「§」禁止のため、CLAUDE.md の文書規約、[[lw-kit-詳細設計-CLAUDE.md]]）
- **verbatim quote** または **`[synthesis]` tag + 説明**

citation を作れない場合: source を探す / claim を弱める / 削る、の三択。

## log の扱い

`wiki/log.md` に append-only で記録。

- 形式: `## [YYYY-MM-DD] <operation> | <title>` の 2 カラム（header 記法 `##`）
- operation: `init / ingest / query / update / lint / audit`
- 形式定義は `SCHEMA.md` 内（wiki-init skill が template として生成）
- 過去エントリ書き換え禁止

llm-wiki は 3 カラム化（type / 対象パス / 説明）に拡張、type も llm-wiki 独自を追加（[[lw-kit-詳細設計-log-index]] 参照）。

## wiki-lint の checks 一覧

**🔴 errors**（must fix）:

- broken `[[slug]]` link（対応 page なし）
- missing frontmatter（title / tags / sources / updated）

**🟡 warnings**（should fix）:

- orphan page（inbound link 0、index/overview 除く）
- contradictions（同 entity が page 間で異なる説明）
- stale claims（90 日以上未更新で "current/latest/recent/state-of-the-art" を含む or 2 年以上古い year literal）
- **chronological update sections**（`## [Month] \d+` / `**[Month] \d+ update` パターン — page 内に journal 化された更新履歴）

**🔵 info**（consider）:

- missing concept pages（`[[slug]]` が 3+ 回出るが page なし）
- coverage gaps（overview.md の Open Questions に答えられそうな ingest 候補）
- missing cross-references（同 entity を扱うのにリンクしてないペア）

## common mistakes（ingest skill 内で明文化）

1. **chronological update を pages に追記**: pages は living document、`## April 27 update:` のようなセクションを増やさない。in-place で編集し、frontmatter の `updated` を更新、log.md に変更を記録
2. **backlink 監査の skip**（最も skip されると明記）: bidirectional links がコンパウンディングの源泉
3. **abstract をリフレーズしただけ**: summary は自分の synthesis を書く

## ingest skill 設計の深掘り

`10_raw/llm-wiki/20260515_wiki-skills_skill群調査.md` で得た知見の要点。横断比較は [[LLM-Wiki-ingest-skillのパターン]] 参照。

### 5 skill 共通の 4 ブロック構造

全 skill（init を除く 5 skill）が同じテンプレに従う:

1. YAML frontmatter（`name` + `description`）
2. タイトル + 1 文サマリ（何をして・どこを触り・どこに log するか）
3. Pre-condition（SCHEMA.md 探索 → 見つからなければ wiki-init を案内）
4. Process（番号付き step、厳密順序）

### description 文体パターン（auto-load 判定の鍵）

- "Use when ..." で始める
- 対象を列挙（"a paper, article, URL, file, transcript, ..."）
- 副作用規模を予告（"One ingest may touch 10-15 wiki pages"）
- 否定形で default 抑制（"Do not answer from general knowledge"）
- 頻度目安（"Run after every 5-10 ingests"）

### ingest は実質 13 step（5b/5c 派生）

公式は 11 step だが `5b: Cite as you write` / `5c: Self-check before continuing` を独立番号で書く設計。failure mode を step 内に明示することで強い負の prompt として機能する（"this is the most common failure mode in long ingest sessions"）。

### "BEFORE writing anything" のゲート設計

step 3 で takeaway を提示 → verbatim 質問（`**"Anything specific you want me to emphasize or de-emphasize?"**` 太字 + 引用）→ "Wait for the user's response before proceeding."

caps + verbatim + 待機指示の三重ゲート。

### 「新規生成は無確認 / 既存変更は要確認」の二分原則

5 skill 横断:

- 新規生成（report ファイル / log 追記）: "do not ask permission" を何度も登場
- 既存変更（page 編集）: 必ず diff 提示 + per-page confirmation

### citation 3 択の強制

`5b` で "Find one, weaken the claim ('the paper suggests...'), or drop it." と 3 択を強制。claim を残したまま citation なしを許さない原則。footnote は末尾固定 + 出現順 numbering。

### entity page の `## Appearances in Sources` が backlink 代替

bidirectional link を別装置に頼らず、entity page 自身が「どの source で言及されているか」を維持する装置。

### Common Mistakes セクションの偏在

ingest / query / update のみに存在、lint / audit / init には無い。LLM が default 挙動として陥りやすい操作にだけ書く設計。

### slug 化は不採用（llm-wiki 分岐点）

wiki-skills は lowercase-hyphens slug 化、llm-wiki は日本語タイトル保持。`/lw-render` SKILL.md に明示的な分岐点として書く。

## llm-wiki での採用理由

- Karpathy gist にもっとも忠実な構造
- 依存ゼロ → llm-wiki の「ローカル完結」思想と合致
- skill 粒度が適度（6 個）→ llm-wiki の既存 skill 文化と接続しやすい
- 規模が小さくカスタマイズしやすい
- overview.md の挙動が明確 → llm-wiki の `overview.md` 設計の手本

## llm-wiki でのカスタマイズ予定

- **動詞化**: `wiki-ingest` / `wiki-lint` を動詞名の skill にする（現在は `/lw-render` / `/lw-lint`）
- **00_issues/ 中断点メモ追加**: wiki-skills には進行中メモがない（[[claude-obsidian]] の hot.md に相当するもの）
- **log フォーマット 3 カラム化**: type / 対象パス / 説明（[[lw-kit-詳細設計-log-index]]）
- **PDF 対応**: render skill に PDF page 指定を追加（[[llmwiki]] の `read` ツール参考）
- **Iron Laws 検討**: [[karpathy-wiki]] の 4 条規律を llm-wiki の SCHEMA に組み込むか検討

## 関連

- [[LLM-Wiki]]: パターン本体
- Andrej-Karpathy: パターン提唱者
- [[claude-obsidian]] / [[karpathy-wiki]] / [[llmwiki]]: 同パターンの別実装
- [[lw-kit-詳細設計-log-index]]: llm-wiki での log 拡張
- [[lw-kit-詳細設計-issue]]: 中断点メモ（wiki-skills にない要素）
