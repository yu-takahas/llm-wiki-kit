---
type: entity
tags: [implementation, llm-wiki, obsidian]
sources:
  - https://github.com/AgriciDaniel/claude-obsidian
  - github/claude-obsidian/
created: 2026-05-14
updated: 2026-07-01
---

# claude-obsidian

Andrej Karpathy が提唱した LLM Wiki パターンの Obsidian + Claude Code 統合実装。
4 実装中の最大規模（8.3k stars、2026-07-01 時点）。

## 主要属性

- **作者**: AgriciDaniel
- **規模**: 8.3k stars（2026-07-01 時点、5 月時点の 4.9k から急増）
- **言語**: Python 69% + Shell 29%
- **形態**: Claude Code plugin + Obsidian vault
- **依存**: **Obsidian 必須**、Templater / Obsidian Git / Excalidraw 等のコミュニティプラグイン
- **マルチモデル対応**: Claude / Gemini / Codex / Cursor / Windsurf
- **最終更新**: 2026-05-28（v1.9.2）

## ディレクトリ構造

```text
claude-obsidian/
├── .raw/                  # 不変、人間が source を放り込む
├── .raw/.manifest.json    # DragonScale manifest（address_map / sha256）
├── .obsidian/             # Obsidian vault 設定
├── .vault-meta/           # DragonScale 用 meta（tiling-thresholds 等）
├── _templates/            # Templater templates（concept / entity / source / comparison / question）
├── _attachments/          # 画像・PDF
├── wiki/
│   ├── index.md / log.md / hot.md / overview.md
│   ├── concepts/ entities/ sources/ questions/ meta/ comparisons/ folds/
├── skills/                # 11 skill（wiki / wiki-ingest / wiki-query / wiki-lint / wiki-fold / save / autoresearch / canvas / defuddle / obsidian-bases / obsidian-markdown）
├── agents/                # subagent 定義（wiki-ingest.md / wiki-lint.md）
├── commands/              # slash command 定義（wiki / canvas / save / autoresearch）
├── hooks/                 # SessionStart / PostCompact / PostToolUse / Stop の 4 hook
└── scripts/               # allocate-address.sh / tiling-check.py / boundary-score.py 等
```

## skill 構成（15 個、v1.9.2 時点）

- `wiki` — セットアップと sub-skill へのルーティング
- `wiki-ingest` — single or batch source ingestion
- `wiki-query` — answer from wiki
- `wiki-lint` — health check（後述）
- `wiki-fold` — DragonScale Mechanism 1（log rollup）
- `wiki-cli` — Obsidian CLI 連携（v1.7+ で追加）
- `wiki-retrieve` — wiki 検索・取得（v1.9+ で追加）
- `wiki-mode` — wiki モード切替（v1.9+ で追加）
- `save` — 現在の会話を構造化 note として file
- `autoresearch` — 3 round 自律研究ループ
- `canvas` — Obsidian canvas 連携
- `think` — 10-principle 思考フレームワーク（v1.9+ で追加）
- `defuddle` — テキスト読みやすさ改善
- `obsidian-bases` / `obsidian-markdown` — Obsidian 連携

## slash command

`/wiki` / `ingest [file]` / `ingest all` / `/save` / `/autoresearch [topic]` / `/canvas` / `lint the wiki` / `update hot cache`

## hot.md（最重要、[[lw-kit-詳細設計-issue]] の発想源）

### 実際のフォーマット

```yaml
---
type: meta
updated: 2026-04-24T13:10:00
tags:
  - meta
  - hot-cache
status: evergreen
related:
  - "[[index]]"
  - "[[log]]"
  - "[[Wiki Map]]"
  - "[[getting-started]]"
  - "[[DragonScale Memory]]"
---

# Recent Context

Navigation: [[index]] | [[log]] | [[overview]]

## Last Updated

2026-04-24 (late night): <要約>
2026-04-24 (night): <要約>
2026-04-24 (evening): <要約>
...

## Plugin State

- Version / Install ID / Skills / Scripts / Setup / Tests / Hooks

## DragonScale Mechanisms

1. Fold operator
2. Deterministic addresses
3. Semantic tiling lint
4. Boundary-first autoresearch

## Key Lessons from This Release Cycle

## Style Preferences

## Active Threads

## Repo Locations
```

### 挙動

- **追記型 reverse-chronological**（私が当初書いた「毎回完全上書き」は誤り）
- 各 update は「2026-04-24 (late night)」のような **時刻ラベル**（朝/午前/昼/夜ではなく、具体的時刻 + 任意のタグ）
- 「~500 words」は CLAUDE.md の `Cross-Project Access` セクションで読み手向け expectation として表記、書き手側の hard limit ではない
- frontmatter `status: evergreen` — 永続的な living document 扱い
- 更新者: `/autoresearch` 完了時に「Update `wiki/hot.md` with the research summary」と明記。`save` skill / orchestrator / ingest 完了時にも更新（parallel sub-agent は触らない）
- セクション固定: `# Recent Context` / `## Last Updated` / `## Plugin State` / `## DragonScale Mechanisms` / `## Key Lessons` / `## Style Preferences` / `## Active Threads` / `## Repo Locations`

## overview.md の扱い

### 実物

```yaml
---
type: overview
created: 2026-04-07
updated: 2026-04-07
tags: [meta, overview]
status: developing
---
```

- **初期 scaffold 時に template 生成**、その後の自動更新メカニズムなし
- 実物の `updated` は **2026-04-07 で停止**（hot.md は 2026-04-24 まで動いてるのと対照的）
- セクション: Purpose / Current Seed Content / Current State / Canvases / Key Themes
- 「Current State」に `Sources ingested: 2` / `Wiki pages: 26` / `Last activity: 2026-04-08` の手動カウント
- 結論: **人間が時々手で書き換える living document、自動更新メカニズムは存在しない**
- [[wiki-skills]] の overview.md（ingest が自動更新）と挙動が **明確に違う**

## `[!contradiction]` / `[!gap]` callout

### contradiction

```markdown
> [!contradiction] [[Page A]] claims X, but [[Page B]] says Y.
```

- 使用: ingest agent が新規 source と既存 page の矛盾検出時、双方の page に追加
- 双方向認識を作る、システムは修正提案を出さない（"requires human judgment"）
- wiki-lint で `> [!contradiction]` 不在の矛盾を flag
- CSS: `--callout-color: 209, 105, 105`（赤系）、icon: `lucide-alert-triangle`

### gap

```markdown
> [!gap] This needs more evidence.
```

- 使用: autoresearch 等で uncertainty（証拠不足・未検証の主張）を明示する時
- hedging language（"it seems" / "perhaps" / "might be"）を避け、代わりに `[!gap]` で明示
- CSS: `--callout-color: 220, 220, 170`（黄系）、icon: `lucide-help-circle`

### その他の custom callout

- `[!key-insight]`: `--callout-color: 79, 193, 255`（青系）、icon: `lucide-lightbulb`
- `[!stale]`: `--callout-color: 128, 128, 128`（灰色）、icon: `lucide-clock`

## `/autoresearch`（3 ラウンド研究ループ）

### topic 選択 3 path

- A. Explicit: `/autoresearch [topic]` で verbatim
- B. Boundary-first（DragonScale Mechanism 4、opt-in）: `boundary_score = (out_degree - in_degree) * recency_weight` で frontier top 5 を提示。**agenda control と明記**、user 承認なしの自動選択なし。helper failure / 空結果なら C へ fall through
- C. User-chosen: 「What topic should I research?」

### 研究ループ

```text
Round 1. Broad search:
  topic を 3-5 angles に分解、各 angle で 2-3 WebSearch、top 2-3 結果を WebFetch、claims/entities/concepts/open questions 抽出
Round 2. Gap fill:
  Round 1 で欠けた・矛盾した部分を targeted search（max 5 queries）
Round 3. Synthesis check（optional）:
  major contradictions or missing piece が残ってれば 1 round 追加、なければ filing へ
```

### 制約（`references/program.md`）

- **Max search rounds**: 3
- **Max wiki pages per session**: 15
- **Max sources fetched per round**: 5
- **Confidence**: high（複数 authoritative sources agree） / medium（single good source or 部分合意） / low（speculation / opinion / 単一 informal source）
- **Stale flag**: 3 年超の source は potentially stale
- **Sources**: prefer .edu / peer-reviewed / official docs / primary sources / last 2 years
- **Exclusions**: Reddit / SNS / undated web pages / 自己引用しない source は high-confidence にしない
- **No hedging**: "it seems" / "perhaps" / "might be" 禁止、代わりに `[!gap]` callout
- **Page split**: < 200 lines、超えたら split
- **Max pages hit 時**: file what you have、`Open Questions` に skipped を記載

### Filing

- `wiki/sources/`: major reference ごとに 1 page
- `wiki/concepts/`: 重要 concept ごとに 1 page（index 確認、既存なら update）
- `wiki/entities/`: person / org / product ごとに 1 page（index 確認、既存なら update）
- `wiki/questions/`: master synthesis 1 page、title は `"Research: [Topic]"`

私が当初書いた「単ラウンド → sources/、複数ラウンド → concepts/」は **誤り**。
実際は entity / concept / source / synthesis の **役割別配置**。

### 完了後

1. `wiki/index.md` に新 page 追加
2. `wiki/log.md` の TOP に append:

   ```
   ## [YYYY-MM-DD] autoresearch | [Topic]
   - Rounds: N / Sources found: N / Pages created: ...
   ```

3. `wiki/hot.md` に研究 summary 追加

## log の扱い

`wiki/log.md` を orchestrator が統一管理。
parallel sub-agent は `wiki/index.md` / `wiki/log.md` / `wiki/hot.md` を触らない契約（後述「parallel ingest の規律」）。

- フォーマット: `## [YYYY-MM-DD] <op> | <topic>` 形式（autoresearch の例: `## [YYYY-MM-DD] autoresearch | [Topic]`、TOP に prepend）
- 統一管理者: orchestrator（main agent）のみが書き込み
- parallel ingest 結果は orchestrator に summary を返却し、orchestrator が log/index/hot を 1 箇所で更新
- DragonScale manifest（`.raw/.manifest.json`）が deterministic address を提供、log と組み合わせてどの raw が処理済みか追跡

## orchestrator パターンと parallel ingest

### DragonScale manifest

`.raw/.manifest.json` が:

- **address_map**: path → unique ID（`c-NNNNNN` 形式の deterministic address）
- **delta tracker**: sha256 / mtime で reprocess 回避
- counter は `scripts/allocate-address.sh` が flock-guarded で管理、`max observed` から recovery 可能

### parallel ingest の規律

`agents/wiki-ingest.md`（subagent 定義）に明文化:

```
Do NOT:
- Modify anything in .raw/
- Update wiki/index.md or wiki/log.md (orchestrator does this)
- Update wiki/hot.md (orchestrator does this)
- Create duplicate pages
- Call scripts/allocate-address.sh from inside a parallel sub-agent (single-writer rule)
```

つまり parallel sub-agent は **page write のみ**。
`address:` フィールドは未設定で、**orchestrator が post-pass で backfill**（atomicity 保証）。
index / log / hot は orchestrator が統一管理。

## ingest [file] の 10 step（`agents/wiki-ingest.md` 原文）

1. source file 完読
2. `wiki/index.md` を読む（重複回避）
3. `wiki/hot.md` を読む（recent context）
4. `wiki/sources/` に source summary page を作る（proper frontmatter）
5. 各 entity（person / org / product / repo）: index 確認、create or update を `wiki/entities/`
6. 各 concept / idea / framework: index 確認、create or update を `wiki/concepts/`
7. 関連 domain page を update（brief mention + wikilink）
8. `wiki/entities/_index.md` と `wiki/concepts/_index.md` を update
9. 既存 page と矛盾なら `> [!contradiction]` callout を追加
10. 何を作って何を update したか summary 返却

[[wiki-skills]] の wiki-ingest（11 step、main agent 単一実行）と異なり、
こちらは parallel sub-agent 想定で **index/log/hot を触らない契約**になっている。

## hook 構成（4 種）

- SessionStart
- PostCompact
- PostToolUse（matcher: `Write|Edit`、wiki/ や .raw/ や .vault-meta/ への変更を stage）
- Stop

`hot.md` から「PostToolUse hook matcher は `Write|Edit` なので Bash writes は fire しない」と明記。
script で tracked state を mutate する時は Bash-only で副作用 commit を避ける運用。

## wiki-lint の詳細（v1.9.2 時点）

skill（`skills/wiki-lint/SKILL.md`）と agent（`agents/wiki-lint.md`）の二重構造。
agent は `model: sonnet` / `maxTurns: 40` で dispatch される。
出力は `wiki/meta/lint-report-YYYY-MM-DD.md`。修正は提案のみ、自動修正はしない。

### Transport 層（v1.7+）

lint は `.vault-meta/transport.json` を読んで transport を選択:

- `cli`: `obsidian-cli read` / `obsidian-cli backlinks` でネイティブなバックリンクグラフ取得
- `mcp-obsidian` / `mcpvault`: MCP 経由
- `filesystem`: Claude の Read / Glob / Grep（最終 fallback、v1.6 以前の挙動）

### 基本チェック（10 項目）

| #   | 検出項目                 | 深刻度       | 説明                                                                                                                |
| --- | ------------------------ | ------------ | ------------------------------------------------------------------------------------------------------------------- |
| 1   | Orphan pages             | Warning      | inbound wikilink が 0 の page                                                                                       |
| 2   | Dead links               | Critical     | 存在しない page への wikilink                                                                                       |
| 3   | Stale claims             | Warning      | 新しい source と矛盾する古い assertion                                                                              |
| 4   | Missing pages            | Suggestion   | 複数 page で言及されるが page がない concept / entity                                                               |
| 5   | Missing cross-references | Suggestion   | entity 名が本文にあるが `[[]]` で囲まれていない                                                                     |
| 6   | Frontmatter gaps         | Critical     | 必須 field（type / status / created / updated / tags）の欠落                                                        |
| 7   | Empty sections           | Warning      | 見出しの下に内容がない                                                                                              |
| 8   | Stale index entries      | Critical     | `wiki/index.md` 内の参照先が rename / delete 済み                                                                   |
| 9   | Address validity         | Error        | DragonScale Mechanism 2 opt-in。format 不正 / 重複 / counter drift / post-rollout で address 欠落 / manifest 不整合 |
| 10  | Semantic tiling          | Error/Review | DragonScale Mechanism 3 opt-in。cosine similarity >= 0.90 は Error、0.80-0.90 は Review                             |

### Writing Style チェック

lint 実行時に文体規約違反も flag:

- 宣言的現在形でない文体（"X basically does Y"）
- source citation 欠落
- uncertainty が `[!gap]` で flag されていない
- 矛盾が `[!contradiction]` で flag されていない

### Naming Convention チェック

| 要素       | 規約                    |
| ---------- | ----------------------- |
| ファイル名 | Title Case with spaces  |
| フォルダ名 | lowercase with dashes   |
| タグ       | lowercase, hierarchical |
| wikilink   | ファイル名と完全一致    |

### agent 追加チェック

- `status: seed` で 30 日以上更新なし
- 300 行超の巨大 page

### 修正方針

安全に自動修正可: missing frontmatter のプレースホルダ追加 / stub page 作成 / unlinked mention へのリンク追加。
要レビュー: orphan page の削除 / 矛盾解消 / duplicate page のマージ。

### Semantic Tiling（DragonScale Mechanism 3、opt-in 詳細）

`scripts/tiling-check.py` が ollama の `nomic-embed-text` モデルで page 間 cosine similarity を計算。

- キャッシュ: `.vault-meta/tiling-cache.json`、`sha256(model + body)` でキー付け（frontmatter 変更では再計算しない）
- 帯域: >= 0.90 は Error（ほぼ重複）、0.80-0.90 は Review（要判断）、< 0.80 は pass
- スケール: 500 page 超で warning、5000 page 超で hard-fail（exit 4）
- exit code 体系: 0（ok）/ 2（usage error）/ 3（cache corrupt）/ 4（scale hard-fail）/ 10（ollama unreachable）/ 11（model missing）

## ingest skill 設計の深掘り

`10_raw/20260515_claude-obsidian_skill群調査.md`（ワークスペース側）で得た知見の要点。横断比較は [[LLM-Wiki-ingest-skillのパターン]] 参照。

### ingest の二重実装（skill と agent の関係）

`skills/wiki-ingest/SKILL.md` と `agents/wiki-ingest.md` が同じ ingest を別 surface で実装:

- skill 側（main agent、11 step）: step 2 で user に "What should I emphasize? How granular?" + `just ingest it` escape hatch
- agent 側（parallel sub-agent、10 step）: step 2 (discuss) と step 7-10 (overview/index/log/hot) を意図的に欠落、structured text 返却

### Delta tracking（hash ベース冪等性）

`.manifest.json` に `{hash, ingested_at, pages_created, pages_updated}` を記録:

- ingest 前: `md5sum [file]` 計算 → manifest と一致なら skip + `Already ingested (unchanged). Use force to re-ingest.`
- ingest 後: pages_created / pages_updated を manifest に書く

### URL / image ingest の分岐パイプライン

- URL: WebFetch → defuddle で 40-60% token 削減 → `.raw/articles/[slug]-[YYYY-MM-DD].md` 保存 → Single Source Ingest 合流
- image: Read tool で OCR + 概念抽出 → `.raw/images/[slug]-[YYYY-MM-DD].md` 保存 + image を `_attachments/` にコピー → Single Source Ingest 合流

### orchestrator + parallel sub-agent の不可侵契約と return format

不可侵リスト: `.raw/` 変更、`wiki/index.md` / `wiki/log.md` / `wiki/hot.md` 更新、duplicate page 作成、`scripts/allocate-address.sh` 直接呼び出し。

orchestrator が post-pass で address backfill + log/index/hot 統一更新。

sub-agent return format（structured text）:

```
Source: [title]
Created: [[Page 1]], [[Page 2]]
Updated: [[Page 3]], [[Page 4]]
Contradictions: [[Page 5]] conflicts with [[Page 6]] on [topic]
Key insight: [one sentence]
```

### PostToolUse hook の Bash/Write 副作用差

`matcher: "Write|Edit"` のため Bash tool での書き込みは hook 起動しない。
副作用回避テクニック: counter（`.vault-meta/address-counter.txt`）は Write/Edit 禁止、Bash helper script のみ使用（`**CRITICAL**` 警告付き）。

### wiki-fold（log rollup）の独自設計

- deterministic fold ID: `fold-k{K}-from-{EARLIEST-DATE}-to-{LATEST-DATE}-n{COUNT}` で重複検出
- dry-run / commit 分離: dry-run は Bash heredoc → stdout のみ、PostToolUse hook を起動しない
- extractive only: outcome bullet は必ず child entry を cite、numeric mismatch は dry-run blocker

### save と ingest の兄弟関係

- ingest = 外部 source を取り込む
- save = 会話内容を取り込む
- type 自動判定: synthesis / concept / source / decision / session

### 避けるべき罠（llm-wiki が踏まないため）

- hot.md の overwrite 指示と実装の乖離（実物は追記型 reverse-chronological）
- overview.md の死蔵（scaffold で作って以降誰も触らない）
- Obsidian custom callout への visual 依存（構文だけ借りる）
- community footer の宣伝
- PostToolUse auto-commit hook（粒度崩壊リスク）

## llm-wiki での参考（部分輸入候補）

- **hot.md の発想** → [[lw-kit-詳細設計-issue]] に採用済（llm-wiki は reverse-chrono 同一ファイル更新ではなく **タスク単位ファイル**）
- **wiki-lint の 10 項目チェック + 文体チェック** → `lw-lint` 設計の直接参考。特に Empty sections / Stale index entries / Writing Style は wiki-skills にない独自項目
- **Transport 層（v1.7+）** → transport 抽象化の先例（llm-wiki は filesystem のみなので直接は不要だが、将来 Obsidian vault 化時の参考）
- **Semantic Tiling** → 規模拡大時の重複検出手段として保留。現状 llm-wiki は 500 page 未満なので不要
- **`[!contradiction]` callout** → lint flag 標準として採用検討
- **`[!gap]` callout** → `lw-render` / query の uncertainty flag として採用検討
- **`/autoresearch` の信頼度 + stale flag + max constraints** → 将来 `/ingest` 拡張時の参考、特に "No hedging language" の規律
- **page 分割 200 lines** → llm-wiki の長文 page split 基準として採用候補
- **orchestrator + parallel sub-agent の単一ライター契約** → `/ingest` を並列化する場合の参考
- **frontmatter `status: evergreen / developing`** → llm-wiki の lifecycle ラベルとして検討

## llm-wiki で採用しない理由

Obsidian 必須が重い。
Vault 化が完了するまで動かせない。
ただし将来 Vault 化したら参考実装としてキープ。

## 関連

- [[LLM-Wiki]]: パターン本体
- [[lw-kit-詳細設計-rules]]: 部分輸入候補
- [[lw-kit-詳細設計-issue]]: hot.md の発想源
- [[wiki-skills]] / [[karpathy-wiki]] / [[llmwiki]]: 同パターンの別実装
