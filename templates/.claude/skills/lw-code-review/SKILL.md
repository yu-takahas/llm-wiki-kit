---
name: lw-code-review
description: |
  Wraps the built-in /code-review skill, saves findings to
  /tmp/lw-review/<issue-name>/ as Markdown for fix-review consumption.
  Default effort: medium. Override with --effort low|medium|high|xhigh|max.
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Bash(git *)
  - Bash(date *)
  - Bash(mkdir *)
  - Skill(code-review *)
argument-hint: "[--effort low|medium|high|xhigh|max] [観点]"
---

# lw-code-review

組み込み `/code-review` のラッパー。結果を `/tmp/lw-review/` に保存し、fix-review に接続する。

## Input

- `$ARGUMENTS`: `[--effort low|medium|high|xhigh|max] [追加観点テキスト]`
  - `--effort` 省略時は `medium`
  - 残りの文字列は「追加観点」として `/code-review` に渡す

## Steps

### 1. 引数パース

`$ARGUMENTS` から `--effort` の値を抽出する。省略時は `medium`。
残りの文字列は追加観点として保持する。

ユーザーが `ultra` を指定した場合は「`/code-review ultra` を直接実行してください」と案内して終了する。

### 2. `/code-review` の起動

Skill ツールで `/code-review` を起動する。引数に effort level を渡す。
追加観点がある場合はそれも引数に含める。

Skill 呼び出しは in-process で走るため、findings の全データは context に残る。

### 3. 結果の保存 + サマリ報告

#### 3.1 ブランチ名・base-ref の取得

`git branch --show-current` でブランチ名を取得する。
base-ref は `git symbolic-ref --short refs/remotes/origin/HEAD` → `main` → `master` の順で最初に見つかったものを使う。

#### 3.2 issue-name の取得

llm-wiki ルートの `1_issues.md` を Read し、WIP セクションから対象 issue 名を取得する。
見つからなければ `_no-issue` を使う。

#### 3.3 出力ディレクトリの準備

```bash
mkdir -p /tmp/lw-review/<issue-name>
date '+%Y%m%d-%H%M'
```

#### 3.4 findings を Markdown に変換して Write

保存先: `/tmp/lw-review/<issue-name>/YYYYMMDD-HHMM-code-review.md`

ファイル構成:

```markdown
# コードレビュー: <ブランチ名>

- 対象: <ブランチ名> (base: <base-ref>)
- effort: <effort level>
- 指摘件数: <カテゴリ別の件数>

---

### [category] short_summary

- ファイル: `file`:line
- 概要: summary
- 再現シナリオ: failure_scenario
- 検証: verdict
```

findings が 0 件の場合も Write する:

```markdown
# コードレビュー: <ブランチ名>

- 対象: <ブランチ名> (base: <base-ref>)
- effort: <effort level>
- 指摘件数: 0

指摘なし。
```

#### 3.5 サマリ報告

ユーザーに以下を返す:

- 出力ファイルのパス
- effort level
- カテゴリ別の指摘件数
- 主な指摘 top 3（一行ずつ）

## エラーハンドリング

| 状況                         | 挙動                                                                    |
| ---------------------------- | ----------------------------------------------------------------------- |
| ultra 指定                   | 案内して終了（Step 1 参照）                                             |
| findings 0 件                | 「問題なし」で Write（Step 3.4 参照）                                   |
| `1_issues.md` が見つからない | `_no-issue` で続行（Step 3.2 参照）                                     |
| `--fix` が指定された         | 「`--fix` は受け付けません。`/lw-fix-review` を実行してください」と案内 |
| `--comment` が指定された     | 「`/code-review --comment` を直接実行してください」と案内               |

## ルール

- `--fix` を受け付けない（fix-review の採否判定・蓄積導線を素通りするため）
- `--comment` を受け付けない（`/code-review --comment` を直接使えばよい）
- Write するのは `/tmp/lw-review/` 配下の結果ファイル 1 つのみ
- 結果ファイル以外のファイルに触らない
- findings のフィールドをそのまま使う（doc-review の 6 要素への写像はしない）
