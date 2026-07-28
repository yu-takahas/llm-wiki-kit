---
name: lw-lint
description: >
  Audits the llm-wiki for health issues — broken links, missing frontmatter,
  orphan pages, stale claims, and naming violations. Writes a report to /tmp/.
  Does not modify any wiki files. Run after rename/mv work (main source of broken links),
  every 5-10 lw-render executions, or monthly.
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep, Write, "Bash(bash:*)", "Bash(find:*)", "Bash(awk:*)", "Bash(sort:*)", "Bash(comm:*)", "Bash(wc:*)", "Bash(grep:*)", "Bash(date:*)"]
---

# lw-lint

wiki の健全性チェック。レポートを `/tmp/` に出力する。ファイルは一切修正しない。
設計判断の why は `$KIT/docs/lw-kit/40_スキル設計/lw-kit-スキル設計-lw-lint.md`、本ファイルは実行手順の how。

## Process 概観

```text
1. page 一覧 → 2. broken link 検出 → 3. frontmatter 検証 → 4. orphan 検出
  → 5. stale claims → 6. 規約違反 link → 7. index.md 未掲載
  → 8. ファイル名規約違反 → 9. missing cross-ref
  → 10. レポート出力 → 11. 集計報告
```

step 2 が link 一覧（`/tmp/lw-lint-raw-links.txt`）を生成し、step 4・6 が再利用する。
チェック（3-9）は互いに独立。10 で集約して 11 で報告。

## 事前条件

`.claude/rules/wiki.md` が auto load されている前提。未ロードなら Read してから続行。

## Process

### 1. page 一覧を取得

Glob で `30_wiki/**/*.md` / `40_project/**/*.md` を列挙。
この一覧を step 3（frontmatter 検証）/ 4（orphan）/ 5（stale claims）/ 7（missing cross-ref）で使う。
step 2 の抽出は link 専用で、スキャン範囲が異なる（`00_issues/` / `.claude/` / `20_library/` / `50_feedback/` とルート直下メタファイルも含む。`log.md` のみ除外）。

### 2. broken link 検出（Bash）

補助スクリプトを実行する:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/broken-links.sh
```

検出パイプライン（link 抽出 → 名前集合 → ファイル名集合との差集合）はスクリプト内で完結する。
awk を SKILL.md 本文に直書きしない（`$0` / `$2` が skill の引数置換に食われて壊れるため。詳細はスクリプト冒頭コメント）。

出力:

- `/tmp/lw-lint-raw-links.txt` — `<file>\t[[name]]` の全 link 一覧（alias / anchor は name に正規化済み）
- `/tmp/lw-lint-broken.txt` — broken link 名

結果を Read して、broken link ごとに参照元ファイルを `/tmp/lw-lint-raw-links.txt` から grep で特定する。

FIXED / FADED issue（`00_issues/.90_fixed/` / `00_issues/.99_faded/`）のみから参照されている broken link は、レポートに「対応不要（閉じたファイル）」と注記する。

### 3. frontmatter 検証（Bash）

`.claude/rules/wiki.md` の「frontmatter」セクションを Read して必須 field 一覧を取得する。

step 1 の page 一覧に対して、各ファイルの先頭 20 行を Bash で抽出し、必須 field（`type:` / `tags:` / `sources:` / `created:` / `updated:`）の有無を grep で確認する。

除外:

- `10_raw/` 配下
- root メタファイル（`index.md` / `log.md` / `0_icebox.md` / `1_issues.md` / `2_done.md`）
- `assets/` 配下（`md-to-pdf` 用ソース等の非 wiki ファイルが混在するため）

### 4. orphan page 検出

step 2 で取得した link 一覧（`/tmp/lw-lint-raw-links.txt`）を使い、`30_wiki/` / `40_project/` の各 page が一度も参照されていないかを確認する。
index.md も link source に含まれるため、orphan = index にも載っていない完全な迷子（index 掲載漏れ検出を兼ねる。llm-wiki は「全列挙は index に委譲」方針なので、本文相互リンクの有無だけでは orphan 判定しない）。

除外: root メタファイル / `assets/` 配下

### 5. stale claims 検出

`30_wiki/` / `40_project/` の各 page の `updated:` を抽出し、90 日以上前の page を列挙。

該当 page の本文を grep でキーワード検索:

- 日本語: 「現在」「最新」
- 英語: `latest` / `current` / `recent` / `state-of-the-art`
- 年号: 2 年以上古い 4 桁年号（実行年から算出、`$(date +%Y)` - 2 以前）

### 6. 規約違反 link 検出

step 2 の broken link 結果から、半角 space を含む link 名を抽出する。
これらは broken link と同じメカニズムで検出されるが、原因が「ファイル名規約違反」なので severity = warn に分類する。

### 7. index.md 未掲載検出

step 1 の page 一覧から basename（`.md` 除去）を取り、`index.md` 内に `[[basename]]` または `[[basename|` が存在するか grep で確認する。
どちらにもマッチしない page を「index.md 未掲載」として warn 報告する。

除外: root メタファイル / `assets/` 配下

### 8. ファイル名規約違反検出

`40_project/` 配下の `.md` ファイル名を 4 パターンで検査する。

検出パターン:

- `_` を含む（`-` に置換すべき）
- `YYYYMMDD` 日付プレフィックス（`created:` で代替）
- 半角スペースを含む（`-` に置換すべき）
- 派生 page が `<案件名>-` prefix を持たない（case root = ディレクトリ名と同名のファイルは除外）

除外: `assets/` 配下

### 9. missing cross-references 検出

各 page のタイトル（ファイル名から `.md` を除いたもの）で、他の全 page を grep する。
タイトルが本文に出現するが `[[タイトル]]` 形式でリンクされていない箇所を検出する。

ノイズが多いため以下を除外:

- 4 文字以下のタイトル
- 自分自身への言及
- 案件名プレフィックスの部分一致（`llm-wiki` / `my-project` / `side-project` 等）

さらに grep 結果には false positive 3 類型が残る。機械確定せず、レポート記載前に出現箇所の文脈を確認する:

- 長い link の部分文字列（`[[my-project-申請手続き]]` の中の「申請」等）
- 表セル内のエスケープ済み alias link `[[name\|display]]`（リンク済みなのに未リンク扱いになる）
- code span / code fence 内の言及

### 10. レポート出力

`/tmp/lw-lint-YYYY-MM-DD.md` に Write する（確認不要、常に書く）。

レポート形式:

```text
# lw-lint レポート — YYYY-MM-DD

## 集計
- error: N 件
- warn: N 件
- info: N 件

## error: broken link
- `<file>`: [[<name>]] — page が存在しない（参照元: `<source-file>`）
  修正案: plain text 化 / code span 化 / alias 書き換え / 新規 entity 作成

## error: frontmatter 欠落
- `<file>`: `<field>` が欠落
  修正案: field を追加

## warn: orphan page
- `<file>`: inbound link 0
  修正案: 関連 page からリンク追加 or 不要なら削除

## warn: stale claims
- `<file>`（updated: YYYY-MM-DD）: 「<keyword>」を含む
  修正案: 内容を再検証し updated を更新、または「YYYY 年時点で」に書き換え

## warn: 規約違反 link
- `<file>`: [[<name with space>]] — 半角 space を含む
  修正案: space を `-` に置換して [[<name-with-hyphen>]] に書き換え

## warn: index.md 未掲載
- `<file>`: index.md に未掲載
  修正案: index.md の該当 type セクションに追記

## warn: ファイル名規約違反
- `<file>`: <違反内容>（`_` を含む / 日付プレフィックス / 半角スペース / prefix 欠落）
  修正案: リネーム

## info: missing cross-references
- `<file>` が「<title>」に言及しているが [[<title>]] へのリンクなし
  修正案: [[<title>]] リンクを追加
```

検出件数 0 の場合は「問題なし」レポートを出力する。
同日の再実行は上書きする。

### 11. 集計を lead に報告

レポート出力後、集計（error / warn / info の件数）を lead に報告する。
修正はしない。lead が判断する。

## 数値閾値

| 項目            | 値                                                                                       |
| --------------- | ---------------------------------------------------------------------------------------- |
| stale 判定      | 90 日                                                                                    |
| 年号 stale 判定 | 2 年以上                                                                                 |
| orphan 除外     | root メタファイル（`index.md` / `log.md` / `0_icebox.md` / `1_issues.md` / `2_done.md`） |

## エラーハンドリング

| ケース                  | 方針                                                       |
| ----------------------- | ---------------------------------------------------------- |
| 検出件数が全項目 0      | 「問題なし」レポートを出力して報告                         |
| 同日に 2 回実行         | `/tmp/lw-lint-YYYY-MM-DD.md` を上書き                      |
| awk / grep の実行エラー | 該当チェックをスキップ、レポートに「スキップ: 理由」を記載 |
