---
type: entity
tags: [implementation, llm-wiki, claude-code]
sources:
  - https://github.com/toolboxmd/karpathy-wiki
  - github/karpathy-wiki/
created: 2026-05-14
updated: 2026-07-01
---

# karpathy-wiki

Andrej Karpathy が提唱した LLM Wiki パターンの実装、toolboxmd 製。
個人 + プロジェクト混在運用に最適化。

## 主要属性

- **作者**: toolboxmd
- **規模**: Shell 82% + Python 17%、220 commits、v0.2.8（2026-07-01 時点）
- **最終コード更新**: 2026-05-06
- **形態**: Claude Code plugin + Bash CLI（`bin/wiki`）
- **依存**: Claude Code + Anthropic API（`claude -p` で背景 ingester）、Git、Bash、Python 3
- **テスト規律**: TDD（RED-GREEN-REFACTOR）、`bash tests/run-all.sh` で全テスト

## skill 構成

| skill                   | 役割                                                                                                            |
| ----------------------- | --------------------------------------------------------------------------------------------------------------- |
| `using-karpathy-wiki`   | SessionStart hook で自動 inject される loader。Iron Laws + TRIGGER 一覧。on-demand skill をいつ load するか指示 |
| `karpathy-wiki-capture` | chat-driven な capture の書き方。main agent が load                                                             |
| `karpathy-wiki-read`    | 6 段階クエリプロトコル。main agent が **質問のたびに** load                                                     |
| `karpathy-wiki-ingest`  | spawned ingester 専用。main agent は読まない、`wiki-spawn-ingester.sh` の spawn prompt から load                |

## ディレクトリ構造

- `~/.wiki-pointer` (main wiki、横断)
- `<project>/wiki/` (project wiki、プロジェクト局所)
- `wiki-resolve.sh` で project/main 切替を解決
- root には `index.md`（小さな MOC）と各カテゴリの `_index.md`（per-directory auto-generated）が並ぶ
- `overview.md` は **存在しない**

## コマンド（bin/wiki）

`wiki status` / `capture` / `ingest-now` / `issues` / `use project|main|both` / `init-main` / `doctor`

各コマンドの実装要点:

| Command                        | 実装要点                                                                                              |
| ------------------------------ | ----------------------------------------------------------------------------------------------------- |
| `wiki status`                  | page count / pending / `.processing` / lock count / quality < 3.5 pages / drift check / git status    |
| `wiki capture`                 | chat-driven → `.wiki-pending/<timestamp>-<slug>.md` を frontmatter 付きで生成                         |
| `ingest-now`                   | validation (`.wiki-config` check) → drift-scan + capture drain（SessionStart phase 4-6 の inline 版） |
| `wiki issues`                  | `.ingest-issues.jsonl` を type × severity でソート・表示                                              |
| `wiki use project\|main\|both` | `.wiki-config` / `.wiki-mode` / `.wiki-pointer` を idempotent に操作                                  |
| `wiki init-main`               | `~/.wiki-pointer` bootstrap                                                                           |
| `wiki doctor`                  | stale lock cleanup（`.processing` > 600 秒） + orphan staging recovery                                |

## Iron Laws（最重要、`using-karpathy-wiki/SKILL.md` 原文）

```text
NO WIKI WRITE IN THE FOREGROUND
NO PAGE EDIT WITHOUT READING THE PAGE FIRST
NO SKIPPING A CAPTURE BECAUSE "IT DOESN'T LOOK WIKI-SHAPED"
NO ANSWERING ANY USER QUESTION WITHOUT ORIENTING FIRST
```

原典では番号付けされていない 4 行のコードブロック。
SessionStart hook が loader skill 全文を `<EXTREMELY_IMPORTANT>` タグで毎セッション inject する。

### Announce contract

capture / ingest / 質問回答のいずれかを行うとき、返信の冒頭に 1 行 prefix:

```text
**Using the karpathy-wiki skill to [capture this / ingest pending captures / answer from wiki].**
```

これ以外の wiki-mechanics 関連の narration はユーザーに見せない。
オリエンテーション・spawn 機構・state-machine 進行は **silently 実行**。

### Subagent stop

subagent として dispatch された場合（Explore / lw-code-review / codex:rescue 等）、この skill は skip。
wiki rule は main agent にだけ適用。

### Resist tables

`using-karpathy-wiki` には 2 つの「forbidden rationalization 一覧表」が含まれる:

1. **Read protocol resist-table**: 「general knowledge だから skip」「trivial だから 2 ファイル読みは overkill」等の言い訳と、それを否定する「reality」
2. **Capture trigger resist-table**: 「user が覚えてる」「trivial」「後で capture する」「memory tool を持ってない」等

「skipped capture is invisible — discipline is yours alone」と明記。

## 6 段階クエリプロトコル（`karpathy-wiki-read/SKILL.md` の deterministic ladder）

| 段階 | 名前                             | 動作                                                                                                                                                                                                                                                                                                                                   |
| ---- | -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| A    | Orient                           | `<wiki>/schema.md` + 該当 `_index.md`（または root `index.md`）を順に読む。**セッション内 1 回だけ**、2 回目以降は memory cache                                                                                                                                                                                                        |
| B    | Count signal-matching candidates | 質問から signal terms 抽出（meaningful nouns / proper-noun phrases / technical terms / version numbers / tool names。stopword: "the/what/how/do/is"）、`_index.md` を walk。match 条件: substring-match title (case-insensitive) OR tag exact match (case-insensitive) OR one-line summary 内 appearance。**0 → F / 1-5 → C / 6+ → E** |
| C    | Inline read                      | 候補全 page を完読。判定: "Does the union of these pages contain every claim my answer would make?" YES → cite & answer / NO → D                                                                                                                                                                                                       |
| D    | Gap-fill via web search          | 未覆蓋 claim ごとに WebSearch / WebFetch、wiki citation + web citation を併記。**完了後 ALWAYS capture**（wiki がこの gap を次回埋められるよう）                                                                                                                                                                                       |
| E    | Explore subagent                 | 候補 6+ で dispatch。subagent に「wiki path + question + 完全 read + cite」を verbatim prompt で投げる。返ってきた synthesis を使う                                                                                                                                                                                                    |
| F    | Cold result                      | match 0 件、wiki にカバー無し → web search → **ALWAYS capture**                                                                                                                                                                                                                                                                        |

**閾値 5/6 は不可変**。"There is no agent judgement at branch points" と明記。
embedding / semantic match は **採用しない**（CLAUDE.md で "do not add: vector search — defer until genuine scaling pain"）。

### Cite contract

- wiki page 引用: `<wiki>/<category>/<page>.md` + 関連性メモ or 短い quote（≤ 2 行）
- web 引用: `[<title>](<url>)`
- citation は **inline**（footer block は NG）
- 訓練データからの claim は `*"(from training data; not in wiki)."*` で **明示的に flag**（uncited を許す唯一の場合）

## ingest skill（`karpathy-wiki-ingest/SKILL.md`、spawned ingester 専用）

### 9 step orientation

1-3. `schema.md` / `index.md` / `log.md` 直近 10 件を読む 4. capture から signal 抽出（タイトル分割 + tags + 本文の名詞/技術語、`raw-direct` capture は filename + 先頭 200 行）5. **substring + tag match で候補 score**（embedding 不使用）6. **上位 7 候補**を pick（match count 降順 → title length 昇順 → alphabetical）7. 候補 page 完読（cold start: < 8 pages の wiki なら 0 候補もあり得る）8. decide: create / augment / no-op 9. issue を `wiki-issue-log.sh` で JSONL に記録

### Ingester 12 step

1. capture claim（`.md.processing` を read）
2. orientation
3. capture 本文 read
4. `.raw-staging/` 経由で evidence を atomic に `raw/` へ rename（POSIX rename）。manifest lock 付。sha256 短絡 / overwrite-detection あり
5. target page 決定
6. 各 target に対して: lock → read-before-write → in-place merge → release lock
   6.5. self-rate（accuracy / completeness / signal / interlinking 各 1-5、`overall` = `round(mean, 2)`）。`rated_by: human` は **clobber 禁止**
7. `wiki-build-index.py` で `_index.md` 再生成（index.md 直接書き込み禁止）
   7.5. missed-cross-link check（cheap model に「`_index.md` の中で link 漏れがある page」を提案させる）
   7.6. `_index.md` size threshold check（> 8KB なら schema-proposal capture）
8. `log.md` append
9. project wiki なら main へ propagation 判定
10. capture archive（`.wiki-pending/archive/YYYY-MM/`）
11. `wiki-commit.sh` で auto-commit
12. exit

### Body-sufficiency floors（最初に reject 判定）

- `raw-direct` → no floor（body は auto-generated）
- `chat-attached` → 1000 bytes
- `chat-only` → 1500 bytes

floor 未満なら `needs_more_detail: true` を frontmatter に追加、`.md.processing` → `.md` rename して次回再ingest 待ち。

## SessionStart hook（`hooks/session-start`、6 phase）

`hooks.json` 定義:

```json
{
  "SessionStart": [{ "matcher": "startup|clear|compact", "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start" }] }],
  "Stop": [{ "matcher": ".*", "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/stop" }] }]
}
```

実行順:

1. **Fork-bomb Guard**: `WIKI_CAPTURE` / `CLAUDE_AGENT_PARENT` が set されてれば即 exit（spawn された ingester や subagent が SessionStart で再 spawn するのを防ぐ）
2. **Loader Injection**: `skills/using-karpathy-wiki/SKILL.md` の本文を `<EXTREMELY_IMPORTANT>` タグで包んで emit。Platform 別に JSON 出力形式を分岐:
   - Cursor: `{"additional_context": "..."}` (snake_case, top-level)
   - Claude Code: `{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "..."}}` (nested、`hookEventName` 必須)
   - GitHub Copilot CLI / SDK 標準: `{"additionalContext": "..."}` (top-level)
3. **Wiki Resolution**: `wiki_root_from_cwd()` で wiki を探す、なければ loader emit のみで exit
4. **Drift Scanning**:
   - inbox/ scan: mtime ≤ 5 秒のファイルは defer（rsync/unzip/in-progress copy 保護）
   - raw/ scan: `wiki-manifest.py diff` で NEW/MODIFIED 検出
   - NEW raw/ は user accident と判定して **inbox/ に戻す**（manifest lock 付き）
   - MODIFIED は drift capture を作る
5. **Capture Drain**: `.wiki-pending/*.md`（`.processing` 除く）の各々で `wiki-spawn-ingester.sh` を detach 起動
6. **Stale Reclaim**: `.md.processing` の age > 600 秒なら `.md` へ rename

drift/drain/reclaim は best-effort（`set -e` なし）、stdout への出力は phase 2 の loader JSON のみ。

## log の扱い（二層構造）

markdown log と JSONL log の二層。

- `<wiki>/log.md`: 人間が読む markdown log
- `<wiki>/.ingest-runs.jsonl`: 機械可読な ingest 実行ログ（後述）
- `<wiki>/.ingest-issues.jsonl`: lint issue の構造化ログ（後述）

ingest skill は orientation（9 step の最初）で `log.md` 直近 10 件を読む規約。
過去履歴を踏まえて重複作業を回避する。
JSONL は `wiki-issue-log.sh` / `flock` で append 競合制御（vector search や検索インデックスは scaling pain が出るまで導入しない方針）。

## JSONL ログスキーマ

### `.ingest-runs.jsonl`（append-only）

```jsonl
{"run_id":"in-<unix_ts>-<random>","capture":"<path>","started_at":"<ISO-8601>","status":"spawned"}
{"run_id":"<same>","ended_at":"<ISO-8601>","status":"completed|failed","exit_code":<int>}
```

`run_id` 生成: `in-$(date +%s)-$(openssl rand -hex 4 2>/dev/null || echo $$)`。
`flock` で append 競合制御（macOS は noclobber spin fallback）。
spawned record だけ残って closing がない場合、**30 分超で stalled flag**。

### `.ingest-issues.jsonl`（append-only、≤ 4096 bytes/line）

```json
{
  "run_id": "<id>",
  "capture": "<relative-path>",
  "page": "<path>",
  "type": "broken-cross-link|contradiction|schema-drift|stale-claim|tag-drift|quality-concern|orphan|other",
  "severity": "error|warn|info",
  "detail": "<message>",
  "suggested_action": "<recommendation>"
}
```

`wiki-issue-log.sh` 経由で書く（detail は超過時 auto-truncate）。

## lint 関連スクリプト群

独立 lint skill は持たないが、複数のスクリプトが lint 的機能を分担する。

### `wiki-lint-tags.py` — タグ一貫性 linter

2 モード: `--all`（wiki 全体スキャン）/ 単一ページモード（新規・重複タグ検出）。

3 種類のシノニム検出:

1. 5 文字以上の共通プレフィックス（case-insensitive）
2. Levenshtein 距離 2 以下（タグ長 4 以上）
3. `schema.md` に明示定義されたペア

加えてオーファンタグ検出（2 ページ未満でしか使われていないタグを flag）。
終了コードは常に 0（hint 用途、blocking しない）。

### `wiki-validate-page.py` — ページバリデータ（v2-hardened schema）

検証項目:

- frontmatter 必須フィールド: `title` / `type` / `tags` / `sources` / `created` / `updated` / `quality`
- 日付形式: ISO-8601 UTC（例 `2026-04-24T13:00:00Z`）
- `tags` / `sources`: flat list、要素は文字列のみ
- ディレクトリ深度: 5 階層以上で reject
- `quality` ブロック: 4 スコア（accuracy / completeness / signal / interlinking）各 1-5、`overall` は算術平均（小数 2 桁丸め）

`--wiki-root` モード有効時の追加検証:

- 全 Markdown リンクのリンク先ファイル存在確認
- source 参照先のファイル存在確認（`conversation` は除外）
- `type` とトップレベルディレクトリ名の一致

終了コード: 0（pass）/ 1（violation）。

### `wiki-commit.sh` — コミットゲート

`git diff --cached` でステージされた Markdown ファイルを列挙（index / capture / staging 除外）し、各ファイルに `wiki-validate-page.py --wiki-root` を実行。
1 ページでも失敗すればコミット拒否（exit 1）。
prose rule を script で二重強制する設計思想の実装。

### `wiki-issues.sh` — issue レンダラー（`wiki issues` コマンド）

`.ingest-issues.jsonl` を読み取り、8 カテゴリに分類・severity 順ソートして Markdown テーブル形式で出力（severity / page / detail / timestamp / ingester run / suggested action）。
issue ゼロ時は "no issues reported"。malformed 行は別カウント、処理は継続。
`--filter` と `--since` は v2.5 に deferred。

### `wiki-status.sh` — lint 統合ステータス

lint 関連のチェックを統合:

- quality rollup: `overall` < 3.5 のページ数カウント
- タグ synonym: `wiki-lint-tags.py` を実行してシノニムペア数を表示
- issue 集計: `.ingest-issues.jsonl` から直近 30 日分を 8 カテゴリで集計
- 構造検証: `index.md` 8KB 超警告 / カテゴリ深度 4 階層違反 / カテゴリ数 8 ソフト上限
- fork asymmetry: main wiki と project wiki 間の 7 日以内の ingest 完了状況比較

## マッチ規則

### ingest 候補ページのマッチ（embedding 不使用）

- Substring: signal term が title を case-insensitive substring match
- Tag match: tag を case-insensitive exact match
- Summary appearance: `_index.md` の one-line summary 内に signal term が現れる

### タグシノニム検出（`wiki-lint-tags.py`、別コンテキスト）

前セクション「lint 関連スクリプト群」の `wiki-lint-tags.py` が「prefix 5+ 文字同一」「Levenshtein 距離 2 以下」を実装。
これは ingest の候補ページマッチではなく、タグの一貫性 lint 用。

## Numeric thresholds

- **page split**: 2+ sources OR > 200 lines
- **raw archive**: 5+ pages から参照される raw → `raw/archive/` に移動
- **category restructure**: 500+ pages
- **index split**: ~200 entries / 8KB / 2000 tokens（Chroma Context Rot research + Obsidian MOC practitioners 25 items + Starmorph 100-200 pages の根拠付き）

閾値 hit 時は schema-proposal capture を `.wiki-pending/schema-proposals/` に置くだけで、その場では restructure しない。

## Category discipline（v2.3+）

- **Rule 1**: 1 page だけのために新 category を作らない（≥3 pages 見込みが必要）
- **Rule 2**: sub-directory **depth ≤ 4** hard cap（validator が reject）
- **Rule 3**: ≥ 8 categories で soft ceiling、9 個目は **schema-proposal capture** を作って既存 best-fit に置く（user が override すれば mkdir 可）

## platform 対応

Claude Code が primary。
v0.2.7 以降 Cursor（`additional_context`）と GitHub Copilot CLI / SDK（`additionalContext`）にも hook output 対応。
ただし non-Claude-Code は **untested、best-effort**。

## ingest skill 設計の深掘り

skill 群を調べて得た知見の要点。横断比較は [[LLM-Wiki-ingest-skillのパターン]] 参照。

### 12 step ingester の step 4 が異常に長い（行数で重み付け）

step 4（evidence copy）が約 36 行、他 step は 1-7 行。9 sub-step の staging dance + crash recovery 注記 + Iron rule + sha256 short-circuit + title-scope check + overwrite-detection recovery を 1 step に詰める。
12 step プロトコルでは「重要な step」と「軽い step」が同じ重みに見えるリスクがあるが、行数で重み付けすることで回避。

### thin-capture rejection を 1 行で思想化

> A thin-capture rejection is a feature, not a failure.

Body-sufficiency check の最後に独立 1 行で配置。
LLM はこの 1 行があるかないかで「reject を回避しようと頑張る」か「淡々と reject する」かが変わる。

### resist-table（forbidden rationalization の対戦表）

read protocol / capture trigger に「skip したくなる時の言い訳一覧」を 5-7 行の対戦表で書く。
agent の judgment を「決断すべき具体例」に分解して肩代わりさせる装置。

例:

| 言い訳                                 | reality                                                              |
| -------------------------------------- | -------------------------------------------------------------------- |
| "I don't have a memory tool available" | This skill IS the memory tool. The loader's presence is the trigger. |

### announce contract（1 行 prefix で silent 化）

> **Using the karpathy-wiki skill to [capture this / ingest pending captures / answer from wiki].**

「ユーザーが見る wiki-mechanics の唯一の line」と明文化。silent mode が default、明示的に 1 行だけ verbose に。

### deterministic ranking（embedding 不要、tie-break まで明文化）

候補 page 選定:

1. Substring match
2. Tag match（case-insensitive exact）
3. Summary appearance

ランキング:

- Signal-match count 降順
- Title length 昇順（短いほど canonical）
- Tie-break: alphabetical

embedding 不要、tie-break まで明文化することで agent judgment を排除。

### "Do not duplicate that schema here" の参照規律

SKILL.md から `references/page-conventions.md` 参照。`Do not duplicate that schema here` を SKILL.md 自身に書くことで、メンテナンス時の重複混入を防ぐ。

### read-before-write Iron rule + 矛盾保持

step 6 の sub-step:

1. acquire page lock
2. read current page content（read-before-write）
3. merge new material（既存 claim を replace せず追加、矛盾は `contradictions:` frontmatter に追加）
4. release lock

> Contradictions are a judgement call, not a validator violation.

「矛盾を残す権利」を agent に与える。LLM の「矛盾解決バイアス」を明示的に禁止。

### prose rule を script で二重強制

`wiki-commit.sh` の validator gate: 「every touched page must pass the validator before commit」を script でも hard gate。
prose → code への移行履歴がコメントに残る（"used to live as prose in the ingest skill. Enforce it here in code."）。

### 階層化された stale threshold

| 対象                      | threshold          |
| ------------------------- | ------------------ |
| inbox/raw mtime defer     | 5 秒（rsync 保護） |
| page lock / manifest lock | 300 秒（5 分）     |
| `.processing` capture     | 600 秒（10 分）    |
| ingest-runs stalled flag  | 1800 秒（30 分）   |

5 秒 / 5 分 / 10 分 / 30 分の 4 段階。意味付けが明確。

### `<EXTREMELY_IMPORTANT>` injection（loader skill の二重強調）

SessionStart hook で XML タグ + markdown 太字の二重強調で skill 全文を 9KB 弱 inject。cost vs reliability の trade-off。
llm-wiki は wiki.md の auto load で代替できるので不要。

## llm-wiki での参考（部分輸入候補）

- **Iron Laws** → llm-wiki の SCHEMA に組み込む候補（[[lw-kit-詳細設計-rules]] schema 設計）
- **SessionStart 自動 ingest** → `00_issues/` の hot droplet 自動列挙の hook 設計参考
- **`<EXTREMELY_IMPORTANT>` injection** → SessionStart で loader skill を inject する手法、llm-wiki の skill 拡張で活用可
- **JSONL append-only ログ** → [[lw-kit-詳細設計-log-index]] の append-only ルールの根拠
- **deterministic ladder** → `/wiki-query` skill の閾値ベース分岐の手本
- **`_index.md` per-directory** → llm-wiki のサブディレクトリ運用との相性が良い（[[wiki-skills]] のフラット運用との折衷）
- **`raw-staging/` 経由の atomic rename + manifest lock** → 並列 ingest 時の安全性
- **self-rate quality** → page 品質追跡の参考（accuracy / completeness / signal / interlinking）

## llm-wiki で採用しない理由

- Bash 主体のインフラが llm-wiki の markdown 中心と合わない（`bin/wiki` CLI、scripts/ 大量）
- multi-wiki 設計（main + project-per-wiki）は「wiki はプロジェクト単位ではない」llm-wiki の方針と逆行
- `claude -p` 背景 ingester は llm-wiki の同期型運用に合わない

Iron Laws の発想と log 設計、SessionStart の loader injection だけ拝借する方針。

## 関連

- [[LLM-Wiki]]: パターン本体
- Andrej Karpathy: 提唱者
- [[lw-kit-詳細設計-rules]]: 部分輸入候補
- [[lw-kit-詳細設計-log-index]]: JSONL append-only の参考
- [[wiki-skills]] / [[claude-obsidian]] / [[llmwiki]]: 同パターンの別実装
