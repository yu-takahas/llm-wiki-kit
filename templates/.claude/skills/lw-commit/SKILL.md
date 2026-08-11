---
name: lw-commit
effort: medium
description: commit という区切りで「issue 最新化の確認 + 1_issues / 2_done + log / index + add + commit」を一括で実行する skill。手動 /lw-commit のみ起動。
argument-hint: "[補足メモ（省略可）]"
allowed-tools:
  [
    Read,
    Edit,
    "Bash(git add:*)",
    "Bash(git status:*)",
    "Bash(grep:*)",
    "Bash(find:*)",
    "Bash(LANG=ja_JP.UTF-8 date:*)",
  ]
disable-model-invocation: true
---

# lw-commit

commit という lead 発火の区切りに、issue の最新化確認 + 記録 + add + commit を一括で実行する skill。
設計判断の why は `$KIT/docs/lw-kit/40_スキル設計/lw-kit-スキル設計-lw-commit.md`、本ファイルは実行手順の how。

入力: `$ARGUMENTS` は任意の補足メモ（commit 範囲のヒント等）。省略可。

## Process 概観

```text
1. issue 最新化 → 2. log / index を追記して git add → 3. commit（permit gate） → 完了報告
```

観察の反映（page / memory への書き込み）は `/lw-retro` が持つ。本 skill は畳む（活用）に専念する。
ステップ 1 は一巡した結果、該当が無ければ次へ進む。

## 言い訳対戦表（起動前チェック）

| 言い訳                                        | 現実                                                                        |
| --------------------------------------------- | --------------------------------------------------------------------------- |
| trailer を message に書いておく               | 書かない。方針として付けない（設計書「trailer を付けない」セクション）      |
| add と commit を `&&` で 1 行にまとめると速い | 別ステップにする。permit gate（別ターミナル確認）を崩さないため             |
| context で issue の状態を知ってるから一巡不要 | `grep -rl` / `find` で機械的に候補を絞り込む。context の記憶で skip しない  |
| 反映するものがあるから page に書いてから畳む  | 書かない。反映は `/lw-retro` が持つ。触ってよいファイルは「必須動作」が正本 |

## 事前条件

- `.claude/CLAUDE.md`「Git」セクションと「ターン終了前セルフチェック」セクションを Read する（ロード済みなら追加コストは無い）

## Process（3 ステップ）

### 1. issue 最新化

commit 前に issue が最新化されているか確認する。
更新ロジックの正本は `/lw-update-issue` で、同 skill は Claude から起動できない（`disable-model-invocation: true`）。
未反映のときの動きは、`/lw-update-issue` の手順を context に持っているかで分かれる。

手順:

1. `find 00_issues/ -maxdepth 1 -name "*.md"` で WIP issue を列挙し、worktree 名と会話文脈で今セッションの対象を絞る。絞り込みに迷ったら `grep -rl "<作業対象の語>" 00_issues/` で候補を機械的に引く（`$ARGUMENTS` に commit 範囲のヒントがあればその語を使う）
2. 関連 issue の 💧 進行中 / 🌂 中断点が今セッションの作業を反映しているか目視確認
3. 未反映なら分岐する
   - 今セッションで `/lw-update-issue` が起動済みで手順が context にある → その手順に従って自分で issue を更新する。🪣 に触る前に `LANG=ja_JP.UTF-8 date` を叩き、見出しの日時を実測で書く
   - 手順が context に無い → lead に `/lw-update-issue` の起動を依頼して止まる（手順を推測で補わない）
4. lead 確認済みで状態が確定しているものは `1_issues.md` / `2_done.md` に転記する
   - TODO を全 `[x]` にした（全完了）→ `1_issues.md` の対応行も `[x]` に
   - FIXED 化した → `1_issues.md` から該当行を削除 + `2_done.md` FIXED セクションに追記
   - FADED 化した → `1_issues.md` から該当行を削除 + `2_done.md` FADED セクションに追記

issue が既に最新化済み（このセッションで `/lw-update-issue` が実行済み）か、関連 issue が無ければ次へ進む。

本セッションで新たに FIXED / FADED 化の要否が出た場合は、判断して lead に確認するところまで。`00_issues/.90_fixed/` への mv は本 skill では行わない（`.claude/rules/issue.md`「ユーザー確認」セクション）。

### 2. log / index を追記して git add

このコミットに含む Edit / Write / mv / rm を `log.md` に 1 行追記する（append-only、過去エントリは触らない）。
`30_wiki/` / `40_project/` の page 増減 / rename があれば `index.md` も更新する。
記入の具体は `.claude/rules/log-index.md` が正本。確認のタイミングは `.claude/CLAUDE.md`「ターン終了前セルフチェック」セクションに従う。

そのうえで `git status` で対象を確認し、関連ファイルを明示列挙して `git add` する。
`git add -A` / `git add .` は使わない（無関係な未追跡ファイルを巻き込まないため）。
このステップは自走してよい。

### 3. commit

`type(project)` 形式で message を生成して `git commit` する。
add（2）と別ステップにして permit gate を維持する（`&&` で繋がない）。ここで commit はユーザー確認に止まる。
`Bash(git commit:*)` は意図的に `allowed-tools` に入れていない（足すと permit gate が消える）。

commit の実行中に pre-commit hook の `format` ジョブが prettier をかけ、整形結果を staged に戻す。
permit 時に terminal で見た diff と実際に commit される内容が format 分ずれるが、format 差分だけなら止めずに通す。

message の確定ルール:

- 形式: `type(project): 説明`、本文は日本語
- type: `feat` / `fix` / `refactor` / `chore` / `docs`
- project の決め方（主旨優先、変更数で上書きしない）:
  - 案件・シリーズ主導 → その案件 / シリーズのサブディレクトリ名（`40_project/<案件>/` 等）
  - 汎用作業 → ナンバリングディレクトリ名から数字を落とす（`30_wiki/` → `wiki` / `10_raw/` → `raw`）
  - ルートファイル（`index.md` / `log.md` / `1_issues.md` 等）→ ワークスペース名
  - 主旨が判然とせず複数にまたがる時のみ、変更数が最多の project
- `Co-Authored-By:` trailer は message に書かない（方針として付けない。根拠は設計書「trailer を付けない」セクション）

commit 後、3 ステップの結果を 1 行にまとめて完了報告を 1 回出す（例: 「issue 最新化: 済み / log・index: 追記 / commit: `<hash>` `<message>`」）。

## エラーハンドリング

| ケース                                | 方針                                                                                                                                                                        |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| commit 対象なし                       | 「commit 対象がありません」と報告して停止（空 commit しない）                                                                                                               |
| issue が未反映で手順も無い            | lead に `/lw-update-issue` の起動を依頼して止まる（手順を推測で補わない）                                                                                                   |
| markdownlint エラー（commit 時 hook） | hook が commit を止める。対象が「必須動作」の allowlist 内なら修正 → 再 add → 再 commit（permit は 2 回目が走る）。page 等 allowlist 外ならエラー箇所を提示して lead に渡す |
| commit message の project 不明        | 主旨優先で決める、判然としなければ変更数最多の project                                                                                                                      |

リトライ / 自動回復は持たない（lead 投げで十分）。

## よくあるミス

不変条件は「必須動作」が正本。ここは必須動作の裏返しでない固有の手順違反だけを挙げる。

1. `log.md` の過去エントリを編集する（append-only 違反、ステップ 2）
2. staged ファイルにパス参照（`30_wiki/Foo.md` 等）が残っている（CLAUDE.md「文書規約」の `[[link]]` 規約違反。commit 前に気づいたら lead に報告する。page の修正は本 skill の範囲外）

## 必須動作

- 完了報告を 1 回出す（個別ステップの「該当なし」報告は出さない）
- add（2）と commit（3）は別ステップ（permit gate 維持）
- trailer は手書きしない（方針として付けない）
- `/lw-commit` が触ってよいのは issue（手順が context にある場合のみ）/ `1_issues.md` / `2_done.md` / `log.md` / `index.md` まで（commit フローに閉じる。page / memory への反映は `/lw-retro` の責務）
