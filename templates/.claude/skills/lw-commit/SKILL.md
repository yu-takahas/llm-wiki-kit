---
name: lw-commit
description: commit という区切りで「観察反映 + issue 最新化 + TODO / ICEBOX + log / index + lefthook 先叩き + add + commit」を一括で実行する skill。手動 /lw-commit のみ起動。
argument-hint: "[補足メモ（省略可）]"
allowed-tools:
  [
    Read,
    Edit,
    Write,
    "Bash(git add:*)",
    "Bash(git status:*)",
    "Bash(git diff:*)",
    "Bash(npm run:*)",
    "Bash(grep:*)",
    "Bash(ls:*)",
  ]
disable-model-invocation: true
---

# commit

commit という lead 発火の区切りに、反映 + 最新化 + lint 先叩き + commit を一括で実行する skill。
設計判断の why は `$KIT/docs/lw-kit/40_スキル設計/lw-kit-スキル設計-lw-commit.md`、本ファイルは実行手順の how。

入力: `$ARGUMENTS` は任意の補足メモ（commit 範囲のヒント等）。省略可。

## Process 概観

```text
1. 反映 → 2. issue 最新化 → 3. 1_issues / 2_done → 4. log / index
  → 5. git add → 6. lefthook 先叩き → 7. 差分確認 gate → 8. 再 add・commit（permit gate）
```

ステップ 1-4 は該当なしが普通（軽い commit では不要なことが多い）。
該当なければ skip + 一言報告して次へ進む（暗黙完了しない）。

## 言い訳対戦表（起動前チェック）

| 言い訳                                        | 現実                                                                            |
| --------------------------------------------- | ------------------------------------------------------------------------------- |
| 反映するものは無いから add から始める         | 前回 commit 以降の観察を必ず一度振り返る。無ければ「反映: 該当なし」と報告      |
| trailer を message に書いておく               | 書かない。Claude Code の attribution が自動付与する                             |
| add と commit を `&&` で 1 行にまとめると速い | 別ステップにする。permit gate（別ターミナル確認）を崩さないため                 |
| lint は pre-commit hook が見るから先叩き不要  | 先に叩く。hook で弾かれる前にエラー把握 + format 差分を確認してやり直しを減らす |
| context で issue の状態を知ってるから一巡不要 | `grep -rl` / `find` で機械的に候補を絞り込む。context の記憶で skip しない      |
| テストは緑のはず                              | 先に走らせて確認する。「はず」で commit しない                                  |

## 事前条件

- `.claude/CLAUDE.md`（Git 節 / ターン終了前セルフチェック）が auto load されている前提。未ロードなら読んでから続行
- `git status` で commit 対象を確認（対象なし時の停止文言はエラーハンドリング参照）

## Process（8 ステップ）

### 1. 反映

前回 commit 以降のセッション観察を、反映先 page へ Edit で反映する。

反映先の典型:

- lead の作業スタイル観察 → [[feedback-観察-作業スタイル]]
- 汎用知識 → `30_wiki/<title>.md`
- 案件固有 → `40_project/<案件>/<title>.md`

自走度は 2 段（詳細は `$KIT/docs/lw-kit/40_スキル設計/lw-kit-スキル設計-lw-commit.md`「反映の自走度」セクション）:

- 軽微（既存 page への事例追記レベル）→ 自走 Edit（確認なし）
- 新規 page 作成 / memory 保存 / 主要セクション書き換え → 骨子・要点を提示して lead 確認を挟む

memory 保存は今回限りの指示と長期方針の区別が lead にしか付かないため、必ず確認する。

該当なければ「反映: 該当なし」と報告して次へ。

### 2. issue 最新化（ガード）

commit 前に issue が最新化されているか確認する。
自分では issue を編集しない。更新ロジックは `/lw-update-issue` に一本化されている。

手順:

1. 今セッションで関連する WIP issue があるか確認（会話文脈・worktree 名から推定）
2. 関連 issue の 💧 進行中 / 🌂 中断点が今セッションの作業を反映しているか目視確認
3. 未反映なら `/lw-update-issue` を起動して issue を最新化する
4. `/lw-update-issue` 完了後、TODO 全完了の issue は FIXED 化（`00_issues/.90_fixed/` 移動）の要否を判断し、lead に確認する

issue が既に最新化済み（このセッションで `/lw-update-issue` が実行済み）なら「issue 最新化: 済み」と報告して次へ。
関連 issue が無ければ「issue 最新化: 該当なし」と報告して次へ。

### 3. 1_issues / 2_done

step2 で以下のいずれかが発生した場合、`1_issues.md` / `2_done.md` に反映する。

- issue の TODO を全 `[x]` にした（全完了）→ `1_issues.md` の対応行も `[x]` に
- issue を FIXED 化した → `1_issues.md` から該当行を削除 + `2_done.md` FIXED セクションに追記
- issue を FADED 化した → `1_issues.md` から該当行を削除 + `2_done.md` FADED セクションに追記

いずれも発生していなければ「1_issues / 2_done: 該当なし」と報告して次へ。

### 4. log / index

`.claude/CLAUDE.md` のターン終了前セルフチェック相当を実行する。

- このコミットに含む Edit / Write / mv / rm を `log.md` に追記（append-only、過去エントリは触らない）
- `30_wiki/` / `40_project/` の page 増減 / rename があれば `index.md`、`00_issues/` の出入りがあれば `1_issues.md` / `2_done.md` も更新

### 5. git add（初回）

`git status` で対象を確認してから `git add` で staged に上げる。
関連ファイルを明示列挙して add する（`git add -A` / `git add .` は使わない。無関係な未追跡ファイルを巻き込まないため）。
このステップは自走してよい。

### 6. lefthook 先叩き

pre-commit hook で弾かれる前に、同じ検査を package.json scripts 経由で先に走らせる。

- `npm run format:fix`（= `prettier --write . --log-level warn`、format 差分を事前確認）
- `npm run lint:md`（= `markdownlint-cli2 '**/*.md'`、lint エラーを事前把握）

scripts は repo 全体対象で、lefthook hook の `{staged_files}`（staged のみ）とは範囲が違う。
先叩きは「commit 前の網羅チェック + format 差分の事前確認」が役割なので repo 全体で問題ない。

確認粒度を分ける:

- `format:fix` の再整形差分は精査せず自走で扱う（prettier は内容を大きく変えない前提、空白パディング等が主）
- `lint:md` は内容を確認してエラーを潰す。markdownlint エラーが出たら潰す → 再 add → 再 lint。潰れるまで commit しない

### 7. 差分確認 gate

初回 add 後に先叩きで差分が出たら、再 add の前に `git diff` を提示して lead 確認を待つ。

- `format:fix` で staged 済みファイルが unchanged → 差分なし、そのまま 8 へ
- changed → `git status` で `MM` のファイルを特定し `git diff` を提示 → lead 確認を待つ
- 「format のみは自動 / 内容変更は確認」のような if 分岐は作らない。差分が出たら一律 lead 確認に倒す
- lead ok を待つまで再 add に進まない

### 8. 再 add・commit

差分があれば、7 の gate を lead が通したのを確認してから再度 `git add` し、`type(project)` 形式で message を生成して `git commit` する。
add（5）と別ステップにして permit gate を維持する（`&&` で繋がない）。ここで commit はユーザー確認に止まる。

message の確定ルール:

- 形式: `type(project): 説明`、本文は日本語
- type: `feat` / `fix` / `refactor` / `chore` / `docs`
- project の決め方（主旨優先、変更数で上書きしない）:
  - 案件・シリーズ主導 → その案件 / シリーズのサブディレクトリ名（`40_project/<案件>/` 等）
  - 汎用作業 → ナンバリングディレクトリ名から数字を落とす（`30_wiki/` → `wiki` / `10_raw/` → `raw`）
  - ルートファイル（`index.md` / `log.md` / `1_issues.md` 等）→ ワークスペース名
  - 主旨が判然とせず複数にまたがる時のみ、変更数が最多の project
- `Co-Authored-By:` trailer は message に書かない。Claude Code の attribution が自動付与する（設定は `$KIT/docs/knowledge/Claude-Code-settings.json.md` を参照）

## エラーハンドリング

| ケース                         | 方針                                                                |
| ------------------------------ | ------------------------------------------------------------------- |
| `git add` 対象なし             | 「commit 対象がありません」と報告して停止（空 commit しない）       |
| markdownlint エラー（先叩き）  | エラー箇所を提示、修正 → 再 add → 再 lint。潰れるまで commit しない |
| 反映で判断に迷う               | 要確認側に倒す（聞く方が安い）                                      |
| 新規 page / memory 保存        | 必ず lead 確認を挟む（自走しない）                                  |
| commit message の project 不明 | 主旨優先で決める、判然としなければ変更数最多の project              |

リトライ / 自動回復は持たない（lead 投げで十分）。

## よくあるミス

不変条件は「必須動作」が正本。ここは必須動作の裏返しでない固有の手順違反だけを挙げる。

1. 新規 page / memory 保存を lead 確認なしに自走する（自走度 2 段の要確認側違反、ステップ 1）
2. log.md の過去エントリを編集する（append-only 違反、ステップ 4）
3. staged ファイルにパス参照（`30_wiki/Foo.md` 等）が残っている（CLAUDE.md「文書規約」の `[[link]]` 規約違反。ステップ 1-4 で Write/Edit した page を含め、commit 前に気づいたら修正する）

## 必須動作

- ステップ 1-4 は該当がなくても「該当なし」を一言報告（暗黙完了しない）
- add（5）と commit（8）は別ステップ（permit gate 維持）。先叩きで差分が出たら再 add 前に lead 確認（7 の差分確認 gate）
- trailer は手書きしない（attribution 自動付与）
- `/lw-commit` は反映先 / issue / log / index / `1_issues.md` / `2_done.md` 以外のファイルを触らない（commit フローに閉じる）
