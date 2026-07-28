---
name: lw-create-issue
description: issue を起票する（内容解釈 → 名前・骨子の自動生成 → ファイル生成 / 1_issues.md 登録 / log.md 追記の 3 点セット反映）。lead が明示的に /lw-create-issue を呼んだ時のみ起動。
argument-hint: "<まとめる指示 / 貼り付けテキスト> [wip|icebox]"
allowed-tools: [Read, Edit, Write, Glob]
disable-model-invocation: true
---

# lw-create-issue

issue の起票（ファイル生成 + `1_issues.md` 登録 + `log.md` 追記）を 3 点セットで確実に行う skill。
設計判断の why は `$KIT/docs/lw-kit/40_スキル設計/lw-kit-スキル設計-lw-create-issue.md`、本ファイルは実行手順の how。

入力: `$ARGUMENTS` はまとめる指示（「↑の内容をまとめといて」等）または貼り付けテキスト。
`wip` / `icebox` を含めると配置先を上書きする（デフォルトは TODO）。

## Process 概観

```text
1. 内容解釈 → 2. 骨子生成 + lead 確認 → 3. Write → 4. 登録 → 5. log.md 追記
```

肝は lead が名前を提案しない前提で動くこと。
Claude が内容から名前・骨子・配置を組み立てて提示し、lead は違和感があればその場で直すだけでよい。

## 言い訳対戦表（起動前チェック）

| 言い訳                               | 現実                                                                                   |
| ------------------------------------ | -------------------------------------------------------------------------------------- |
| 名前は lead に確認しよう             | lead は名前を提案しない運用。Claude が自動生成して骨子提示時にまとめて見せるだけでよい |
| `$ARGUMENTS` が短いから止めよう      | 会話文脈も素材になる。「↑の内容」等の参照は追加入力なしで使える                        |
| 骨子確認は軽いから省略しよう         | `skeleton-confirm` の必須対象（新規 issue ファイル）。必ず提示して確認を待つ           |
| 気を利かせて WIP に置いておこう      | デフォルトは TODO。`wip` / `icebox` の明示キーワードがない限り上書きしない             |
| ICEBOX も `1_issues.md` に書けばいい | ICEBOX は `0_icebox.md` が別ファイル。書き先を取り違えない                             |

## 事前条件

- `.claude/rules/issue.md`「作成」セクション（ファイル名規約）を把握している
- カテゴリは `1_issues.md` の既存見出しが正本（新規カテゴリが要る場合のみ追加する）
- `.claude/rules/issue.md`（状態管理・ファイル内部構造）を把握している
- `.claude/rules/skeleton-confirm.md` の骨子確認ルールに従う

## Process（5 ステップ）

### 1. 内容解釈

`$ARGUMENTS` から素材と配置先を特定する。

- 素材ソース: 「↑の内容をまとめといて」等の参照 → 会話文脈が素材（追加読み込み不要）。貼り付けテキスト（メール / Slack コピペ等）があればそれが素材。外部ファイルへの参照（「〜.md を読んで」等）があれば、そのファイルを読み込んで素材にする
- 配置キーワード: `wip` / `icebox` の有無を確認。どちらも無ければデフォルト（TODO）

素材ソースが会話文脈か貼り付けか判断がつかない場合は、推測で進めず lead に確認する。

### 2. 骨子生成 + lead 確認

- `Glob("00_issues/**/*.md")` で全状態の既存ファイル名を取得し、重複を避ける（Bash `find` 等で代用しない）
- 素材の内容から命名規則（`<project>-<subproject>-<verb>-<object>`、kebab-case、日付プレフィックスなし）に沿った名前を生成する。素材が llm-wiki 自身の開発でも既存案件でもない場合（自己分析等）は `_` prefix を付けた bare-name にする（例: `_setup-worktree-parallel-sessions.md`）。`_` は「project なしが意図的」であることを明示するマーカー
- 名前 prefix からカテゴリを推定する（`llm-wiki-` → 🌊 llm-wiki 開発 / `my-project-` 等その他プロジェクト → 🏗️ プロジェクト）。prefix が無い・当てはまらない場合は `1_issues.md` の既存カテゴリ見出しから内容に最も合うものを選ぶ。無ければ新規カテゴリを作る
- 骨子（frontmatter `related` / `source` / `created` / `tags` + `# <name>` + 💧 進行中 / 🌂 中断点 / ☔ TODO / 関連の見出し枠）を組み立てて提示する
- 配置先（TODO / WIP / ICEBOX）とカテゴリもあわせて提示し、lead の確認を待つ
- lead から修正指示（名前含む）があれば反映して再提示してから Write に進む

### 3. Write

- デフォルト: `00_issues/.10_todo/<name>.md`
- `wip` 検出時: `00_issues/<name>.md`
- `icebox` 検出時: `00_issues/.00_icebox/<name>.md`

### 4. 登録

- デフォルト / `wip` 検出時: `1_issues.md` の該当カテゴリに `- [[<name>]] — <一言>` を追記（デフォルトは 🌂 TODO セクション、`wip` 時は ☔ WIP セクション）。該当カテゴリの見出しが無ければ、`1_issues.md` の既存の並び順に合わせて新設する
- `icebox` 検出時: `0_icebox.md` の該当カテゴリに追記（`1_issues.md` には書かない）

### 5. log.md 追記

- `checkpoint` エントリとして `log.md` に追記する（append-only、過去エントリは触らない）

## エラーハンドリング

| ケース                                                 | 方針                                                                                            |
| ------------------------------------------------------ | ----------------------------------------------------------------------------------------------- |
| `$ARGUMENTS` 未指定                                    | `まとめる内容や指示を教えてください。例: /lw-create-issue ↑の内容をまとめといて` と案内して停止 |
| 素材ソースが不明瞭（会話文脈か貼り付けか判断つかない） | lead に確認して停止（内容解釈を推測で進めない）                                                 |
| 既存同名ファイル                                       | `00_issues/<name>.md` がすでに存在する旨を案内して停止（上書きしない）                          |
| 骨子確認で lead が修正指示（名前含む）                 | 修正を反映した骨子を再提示してから Write に進む                                                 |

## よくあるミス

1. ICEBOX 登録を `1_issues.md` に書いてしまう（`0_icebox.md` の誤り、ステップ 4）
2. lead に名前を確認してしまう（自動生成すべきところを聞き返す、ステップ 2 の趣旨違反）
3. 配置キーワードがないのに WIP / ICEBOX に置いてしまう（デフォルトは TODO、ステップ 3・4）
4. 重複確認を `Glob` でなく `allowed-tools` 外の Bash（`find` 等）でやってしまう（Step 2 は `Glob` を使う）
5. Write した issue にパス参照（`30_wiki/Foo.md` 等）を混入する（CLAUDE.md「文書規約」の `[[link]]` 規約違反。`[[Foo]]` を使う）

## 必須動作

- 骨子確認を経ずに Write しない（`skeleton-confirm` 必須対象）
- 配置先はキーワード（`wip` / `icebox`）の明示がない限り TODO をデフォルトにする
- `/lw-create-issue` は Write 対象の issue ファイル、`1_issues.md` / `0_icebox.md`、`log.md` 以外のファイルに触らない（起票フローに閉じる）
