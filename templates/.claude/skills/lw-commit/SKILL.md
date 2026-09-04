---
name: lw-commit
effort: medium
description: commit という区切りで「issue 最新化 + 状態遷移 + 1_issues / 2_done + log / index + add + commit」を一括で実行する skill。手動 /lw-commit のみ起動。
argument-hint: "[--fixed|--faded] [補足メモ（省略可）]"
allowed-tools:
  [
    Read,
    Edit,
    "Bash(git add:*)",
    "Bash(git status:*)",
    "Bash(git mv:*)",
    "Bash(grep:*)",
    "Bash(find:*)",
    "Bash(LANG=ja_JP.UTF-8 date:*)",
  ]
disable-model-invocation: true
---

# lw-commit

commit という lead 発火の区切りに、issue の最新化確認 + 記録 + add + commit を一括で実行する skill。
設計判断の why は `$KIT/docs/lw-kit/40_スキル設計/lw-kit-スキル設計-lw-commit.md`、本ファイルは実行手順の how。

入力: `$ARGUMENTS` は任意。`--fixed` / `--faded` で対象 issue の状態遷移を指示する（自然文の「FIXED にして」「閉じて」も同じ意味で受ける）。残りは補足メモ（commit 範囲のヒント等）として読む。

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
| 手順が context に無いので issue は触らない    | `lw-update-issue/SKILL.md` を Read して手順を得る。止まらない               |
| 特に直すところは無さそうなので issue を見ない | ステップ 1 の 3 項目は毎回見る。「無さそう」は見た後にしか言えない          |
| ついでに背景セクションも整えておく            | 3 項目の外は触らない。issue 本体の改訂は `/lw-update-issue` の責務          |
| 全部 `[x]` になったので FIXED にしておく      | 指示が無ければ状態遷移しない。判断して lead に確認するところまで            |

## 事前条件

- `.claude/CLAUDE.md`「Git」セクションと「ターン終了前セルフチェック」セクションを Read する（ロード済みなら追加コストは無い）

## Process（3 ステップ）

### 1. issue 最新化

commit 前に issue を最新化する。
更新ロジックの正本は `/lw-update-issue` で、同 skill は Claude から起動できない（`disable-model-invocation: true`）。
手順が context に無ければ `.claude/skills/lw-update-issue/SKILL.md` を Read して手に入れる。

手順:

1. `find 00_issues/ -maxdepth 1 -name "*.md"` で WIP issue を列挙し、worktree 名と会話文脈で今セッションの対象を絞る。絞り込みに迷ったら `grep -rl "<作業対象の語>" 00_issues/` で候補を機械的に引く（`$ARGUMENTS` に commit 範囲のヒントがあればその語を使う）
2. 対象 issue で次の 3 つを見る。これ以外は編集しない
   - ☔ TODO: 今セッションで完了した項目を `[x]` にする。この区切りの `- [ ] /lw-commit` 行も含む
   - 💧 進行中 / 🌂 中断点: 今セッションの作業を反映しているか。未反映なら `/lw-update-issue` の手順に従って更新する。🪣 に触る前に `LANG=ja_JP.UTF-8 date` を叩き、見出しの日時を実測で書く
   - 状態遷移: `$ARGUMENTS` に `--fixed` / `--faded`（または同義の自然文）があれば実行する。無ければしない
3. 状態遷移を指示されていれば、`.claude/rules/issue.md`「FIXED / FADED 化時の終端形」に従って 4 セクションを書き換えてから `git mv` する。書き戻し（同 rule「完了 / 廃棄時の規律」）の要否は判断しない。閉じる指示は仕分け済みの意思表示として受ける（page への反映は `/lw-retro` の責務）
   - `find 00_issues/ -name "<name>.md"` で対象の現在のパスを取る（タイトルは全体で一意なので 1 件に決まる）。移動元を `00_issues/<name>.md` と決め打ちしない。FADED はどの状態からでも遷移でき、対象が `.10_todo/` / `.00_icebox/` にいることがある
   - FIXED → `git mv <find の出力> 00_issues/.90_fixed/`
   - FADED → `git mv <find の出力> 00_issues/.99_faded/`
4. `git status --short 00_issues/ | grep -E "\.(90_fixed|99_faded)/"` で、この commit 範囲で閉じられた issue を拾う。前段の `/lw-update-issue --fixed` が mv したものと、この実行の 3 で mv したものが両方出る（`git mv` なら `R` 行、手動 `mv` なら `??` 行）。そのうえで状態が確定しているものを `1_issues.md` / `2_done.md` に転記する
   - TODO を全 `[x]` にした（全完了）→ `1_issues.md` の対応行も `[x]` に
   - FIXED 化した（`.90_fixed/` に出た）→ `1_issues.md` から該当行を削除 + `2_done.md` FIXED セクションに追記
   - FADED 化した（`.99_faded/` に出た）→ `1_issues.md` から該当行を削除 + `2_done.md` FADED セクションに追記

関連 issue が無ければ次へ進む。

指示が無いのに FIXED / FADED 化しない。
要否が出た場合は判断して lead に確認するところまで（`.claude/rules/issue.md`「ユーザー確認」セクション）。

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
| issue が未反映で手順も context に無い | `.claude/skills/lw-update-issue/SKILL.md` を Read して手順を得る（推測で補わない、止まらない）                                                                              |
| 対象 issue が複数あって絞れない       | 候補を列挙して lead に選択を促す。状態遷移の指示がある場合は特に、推定で閉じない                                                                                            |
| `git mv` が not under version control | 起票直後の issue はまだ追跡されていない。`git add <path>` してから `git mv` を再実行する                                                                                    |
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
- `/lw-commit` が触ってよいのは issue（ステップ 1 の 3 項目に限る。更新は `/lw-update-issue` の手順に従う）/ `1_issues.md` / `2_done.md` / `log.md` / `index.md` まで（commit フローに閉じる。page / memory への反映は `/lw-retro` の責務）
- 状態遷移は指示があるときだけ（`--fixed` / `--faded` または同義の自然文）。自発的に閉じない
