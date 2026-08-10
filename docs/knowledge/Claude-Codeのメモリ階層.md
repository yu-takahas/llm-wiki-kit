---
type: concept
tags: [claude-code, CLAUDE.md, rules, skills, context-management, best-practice]
sources:
  - https://code.claude.com/docs/en/memory
  - https://code.claude.com/docs/en/skills
  - https://code.claude.com/docs/en/best-practices
  - https://howborisusesclaudecode.com/
  - https://www.humanlayer.dev/blog/writing-a-good-claude-md
  - https://www.builder.io/blog/claude-md-guide
  - https://zenn.dev/cureapp/articles/65b9a99d22ce2b
  - https://arxiv.org/abs/2307.03172
created: 2026-05-14
updated: 2026-08-10
---

# Claude Code のメモリ階層

context にロードされるドキュメントの設計指針。
「常時 vs 条件付き vs オンデマンド vs 自動蓄積」の 4 段階を使い分ける。
Andrej-Karpathy の LLM Wiki のような、大きな構造定義をどこに置くかを考える時に必要になる知識。

## 4 つのロード方式

| 方式        | 場所                                                                              | ロードタイミング                                          | 用途                                      |
| ----------- | --------------------------------------------------------------------------------- | --------------------------------------------------------- | ----------------------------------------- |
| CLAUDE.md   | `~/.claude/CLAUDE.md` / `./CLAUDE.md` / `./.claude/CLAUDE.md` / `CLAUDE.local.md` | 毎セッション常時                                          | 全セッションに必要な普遍ルール            |
| Rules       | `.claude/rules/<name>.md`                                                         | `paths` なし → 常時、`paths` あり → matching file Read 時 | 領域別の規約（特定 path 編集時のみ必要）  |
| Skills      | `.claude/skills/<name>/SKILL.md`                                                  | invoke 時（`/name` または Claude が relevant 判定）       | タスク固有のワークフロー・手順            |
| Auto memory | `~/.claude/projects/<project>/memory/MEMORY.md`                                   | 毎セッション常時（先頭 200 行 / 25KB）                    | Claude が自動蓄積する学習・パターン・好み |

MEMORY.md の 200 行 / 25KB 制限は MEMORY.md のみに適用される（先に達した方が上限）。
CLAUDE.md は長さに関係なく全文ロードされる（ただし短い方が遵守率は高い）。
上限に近づくと Claude Code が短縮を促し、超えた状態で書き込むと書き込み自体は成功したうえでエラーが返る（超過分は次回ロード時に落ちるため）。
計測対象はロードされる内容だけで、YAML frontmatter と block-level HTML コメントは除外される（v2.1.211 以降）。

## 使い分けの判断

公式の guidance：

> Treat CLAUDE.md as the place you write down what you'd otherwise re-explain.
> If an entry is a multi-step procedure or only matters for one part of the codebase, move it to a **skill** or a **path-scoped rule** instead.

判断フロー：

- すべてのセッションに必要な普遍的なルール → `CLAUDE.md`
- 既存ファイル編集時だけ必要な規約 → `.claude/rules/<name>.md` + `paths:` frontmatter
- 新規ファイル作成タイミングが本質のルール（issue 切り出し / 新規 wiki page 作成 / 骨子確認等） → `.claude/rules/<name>.md` paths なし（matching file がまだ存在せず `paths` では機能しないため）
- 多段手順 / オンデマンドで起動するワークフロー → `.claude/skills/<name>/SKILL.md`
- Claude の学習・修正パターン・個人の好み → auto memory（Claude が自動で書く、人は編集・削除で管理）

auto memory と rules は両方 persistent な context だが性格が違う:

| 軸       | auto memory                                               | `.claude/rules/`                   |
| -------- | --------------------------------------------------------- | ---------------------------------- |
| 場所     | `~/.claude/projects/<project>/memory/`                    | `<workspace>/.claude/rules/`       |
| ロード   | 全セッション常時                                          | paths 条件付き or 常時             |
| スコープ | git リポジトリ単位。同じリポジトリのどこで作業しても乗る  | workspace 内、paths で path 限定可 |
| 性格     | ユーザー個人の好み・知識・運用ルール                      | workspace 規約                     |
| 例       | commit type の好み / 中間ファイル片付け / lead の作業分担 | wiki / issue                       |

特定の path でしか要らない規約を auto memory に書くと、その規約が関係ない作業中も常時 context に乗る。
path で絞れる規約は `.claude/rules/` + `paths:` 条件付きにして、該当ファイルを扱う時だけロードする。

## auto memory の格納先と共有範囲

格納先は `~/.claude/projects/<project>/memory/`。
`MEMORY.md` が索引で、topic file が詳細を持つ。

`<project>` は git リポジトリから導出される。
**同じリポジトリの worktree とサブディレクトリは 1 つの auto memory を共有する。**
リポジトリ外では作業ディレクトリのルートが使われる。
マシンローカルで、他のマシンやクラウド環境とは共有されない。

| 設定                              | 効果                                             |
| --------------------------------- | ------------------------------------------------ |
| `autoMemoryEnabled`               | 既定は有効。`/memory` のトグルか settings で切る |
| `autoMemoryDirectory`             | 格納先を変える。絶対パスか `~/` 始まり           |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY` | 環境変数で無効化                                 |

`autoMemoryDirectory` を project の settings に書いた場合は、ワークスペース信頼ダイアログを承認して初めて有効になる（hook と同じ扱い）。

frontmatter を持つ memory ファイルには、書き込みのたびに `modified`（ISO 8601）が記録される（v2.1.214 以降）。
frontmatter が無いファイルに Claude Code が frontmatter を足すことはない。

topic file は起動時にロードされない。
必要になった時に Claude が通常のファイルツールで読む。

## ファイル階層と優先度

ロード順（広い順 → 狭い順、後にロードされた方が context 内で新しい位置に来て効きやすい）：

1. Managed policy（IT/DevOps 管理、OS 別の system path）
2. User: `~/.claude/CLAUDE.md`
3. Project: `./CLAUDE.md` / `./.claude/CLAUDE.md`（cwd から root まで walk-up）
4. Local: `./CLAUDE.local.md`（gitignore 推奨）
5. Auto memory: `~/.claude/projects/<project>/memory/MEMORY.md`

サブディレクトリ内の `CLAUDE.md` はオンデマンド（そのサブディレクトリのファイル Read 時にロード）。
ancestor の `CLAUDE.md` は 起動時に全部ロードされて concatenate される。
連結順は root から cwd に向かう向きで、同じディレクトリ内では `CLAUDE.local.md` が `CLAUDE.md` の後に来る。

除外と追加のスイッチが 3 つある。

- `claudeMdExcludes` — glob で特定の CLAUDE.md をロード対象から外す。monorepo で他チームのものを避ける用途。managed policy のものは除外できない
- `claudeMd`（managed settings のキー）— ファイルを配らずに設定内へ直接内容を書く。managed / policy の設定でのみ効く
- `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` — `--add-dir` で足したディレクトリの CLAUDE.md / rules をロードする（既定では読まれない）

## `.claude/rules/` の `paths:` frontmatter

```yaml
---
paths:
  - "src/api/**/*.ts"
  - "src/**/*.{ts,tsx}"
---

# API 規約
...
```

- `paths` なし → `.claude/CLAUDE.md` と同じ優先度で 起動時ロード
- `paths` あり → Claude が matching file を Read した瞬間にロード、セッション中保持
- glob + brace expansion 対応
- symlinks 対応（複数 project で共有可能）
- user-level rules: `~/.claude/rules/` も同様（project rules より前にロード）
- `.md` は再帰的に発見されるので、`frontend/` `backend/` のようにサブディレクトリで整理できる

`paths:` 付き rule が、常時ロードを避ける主な手段。
paths なしで常時ロードする運用は「使い分けの判断」セクション参照。

## Skills の `paths:` frontmatter

Skills にも `paths` frontmatter がある:

```yaml
---
name: api-helper
description: REST API 実装支援
paths:
  - "src/api/**/*.ts"
---
```

Skill の場合は description が常時 context に載る（Claude が「relevant」判定するため）、本体は invoke 時にロード。
`paths` を指定すると、マッチするファイルを扱っている時だけ自動起動の対象になる。
`disable-model-invocation: true` で description も含めて非表示にできる（手動 invoke のみ）。

## @import 構文

```text
See @README.md for project overview.
@./docs/git-instructions.md
@~/.claude/my-prefs.md
```

- 最大ネスト深度 4
- 循環参照は自動検出
- 存在しないファイルは silently 無視
- コードブロック内の `@path` は無視
- import されたファイルは結局 起動時にロードされる（context 節約にはならない、組織化のため）

context を節約したいなら `paths:` rule の方を使う。

## AGENTS.md との共存

Claude Code は `CLAUDE.md` を読み、`AGENTS.md` は読まない。
他のエージェント向けに `AGENTS.md` を持っているリポジトリでは、`CLAUDE.md` から import して二重管理を避ける。

```markdown
@AGENTS.md

## Claude Code

（Claude Code 固有の指示をここに足す）
```

symlink でも代用できるが、Claude 固有の追記ができなくなる。
Windows では symlink 作成に管理者権限か開発者モードが要るので、import の方が無難。

## 注入メカニズム

CLAUDE.md は **System Prompt の一部ではない**。
`<system-reminder>` タグで囲まれた User Message として、セッション最初に注入される。

```xml
<system-reminder>
As you answer the user's questions, you can use the following context:
# claudeMd
[CLAUDE.md の内容]
IMPORTANT: These instructions OVERRIDE any default behavior and you MUST follow them exactly as written.
</system-reminder>
```

user message として入るので強制力はなく、遵守は指示の具体性と一貫性に依存する。
曖昧な指示や、複数の CLAUDE.md にまたがって矛盾する指示は守られにくい。
広く流布している「会話が伸びるほど遵守率が落ちる」という説明は現行モデルには当てはめない（[[Lost-in-the-Middle]]「測定されたものと外挿されたもの」セクション）。

`/compact` 実行時はキャッシュクリア → ディスクから再読込 → 新しい位置に再注入される（project root の CLAUDE.md は compact 後も自動で再注入される）。
ネストされたサブディレクトリの CLAUDE.md は compact 後に自動再注入されない。
次にそのディレクトリのファイルを Read した時に再読み込みされる。

## `--append-system-prompt` との違い

CLI フラグでも instructions を渡せるが、挙動が CLAUDE.md と異なる。

| 項目        | CLAUDE.md                  | `--append-system-prompt`      |
| ----------- | -------------------------- | ----------------------------- |
| 注入先      | User Message               | System Prompt 末尾            |
| ラッパー    | `<system-reminder>` タグ   | なし                          |
| /compact 時 | ディスクから再読み込み     | 静的（再読み込みなし）        |
| 記述場所    | ファイル                   | CLI フラグ                    |
| 永続化      | ファイルとして自然に永続化 | エイリアス / スクリプトに保存 |

スクリプト / 自動化向けに固定 instructions を入れたいなら `--append-system-prompt`、ファイル運用なら CLAUDE.md。

## `<!-- HTML コメント -->` の扱い

CLAUDE.md / rules ファイル内の block-level HTML コメントは **context 注入時に削除される**。
人間メンテナンス向けメモを書ける（token は消費されない）。
ただしコードブロック内のコメントは保持される。

## サブエージェント / Teammate への注入

サブエージェント（fork 以外）には親セッションの auto memory は注入されない。
CLAUDE.md 階層は全レベル（`~/.claude/CLAUDE.md`、プロジェクトルール、`CLAUDE.local.md`、managed policy files）が注入される。
Explore / Plan エージェントは例外で CLAUDE.md をスキップする。
fork は親の会話とシステムプロンプトを継承する。
サブエージェント固有の persistent memory を持たせるには `memory` フィールドを設定する（同じ 200 行 / 25KB 制限が適用）。

Teammate（Agent Teams）は spawn 時に通常セッションと同じプロジェクトコンテキスト（CLAUDE.md、MCP servers、skills）を自動ロードする。
リードの会話履歴は引き継がない。

## トラブルシューティング

- Claude が CLAUDE.md に従わない: `/memory` でロードされているか確認、指示を具体化（"format code properly" でなく "use 2-space indentation"）、矛盾する指示がないかチェック
- 必須実行のものは hook に: 「コミット前に必ず X」のような確実性が要るものは hook で実装、CLAUDE.md は context であり enforcement ではない
- `InstructionsLoaded` hook でどの instruction file がいつ・なぜロードされたか診断できる

## 執筆原則

### サイズ規律

| 種類                                   | 推奨上限                                                      |
| -------------------------------------- | ------------------------------------------------------------- |
| CLAUDE.md                              | 200 行未満（公式目安）                                        |
| Skill `SKILL.md`                       | 500 行未満（公式 Tip）、詳細は supporting files へ            |
| MEMORY.md（auto memory）               | 200 行 / 25KB（超えた分は topic file へ切り出す）             |
| Skill description + `when_to_use` 合算 | 1,536 char cap（`skillListingMaxDescChars` で変更可）         |
| Skill listing 全体の文字予算           | context window の 1%（`skillListingBudgetFraction` で変更可） |

> Longer files consume more context and reduce adherence.
> — 公式 memory docs

行数が増えるほど context を圧迫し、Claude の遵守率が下がる。
普遍的に適用可能な指示のみに絞り、path 限定で済むものは rules に移す。

`/doctor` が checked-in の CLAUDE.md に対してトリム案を出す（v2.1.206 以降）。
コードベースから導ける内容（ディレクトリ構成・依存一覧・アーキテクチャ概要）を削り、落とし穴・理由・ツール既定と異なる規約を残す方向で提案する。
次の「具体値・列挙を書かない」と同じ判断基準になっている。

### 具体値・列挙を書かない

ディレクトリ構成やコマンド説明に、ファイル名の列挙・件数・サイズ等の具体値を書くと、実装が変わるたびに CLAUDE.md の更新が必要になり、更新されないまま記述が実物と食い違う。
ディレクトリツリーは役割（何のためのディレクトリか）だけを書き、中身の列挙は `ls` に任せる。
コマンド説明も同様に、対象件数や具体的な内容ではなく意図（何のためのコマンドか）を書く。

### Boris Cherny 方式（ミスドリブン）

Boris Cherny 方式は、CLAUDE.md を最初から完璧に書くものではなく、Claude のミスを蓄積して育てる複利的資産として扱う運用。
詳細・引用・実践手順は Boris-Cherny を参照。

### コードスタイルは書かない

linter / formatter に任せる。
どうしても自動化が必要なら `hooks` で実装する（例: `PostToolUse` matcher: `Write|Edit` で prettier 起動）。
CLAUDE.md に書くと毎セッション context を消費するうえに、Claude が従わないリスクが残る。
enforcement が必要なら hook。

## llm-wiki での適用

llm-wiki における具体配置（CLAUDE.md / rules / skills / auto memory それぞれに何を置くか）は [[lw-kit-詳細設計-CLAUDE.md]] を参照。

## 関連

- [[lw-kit-詳細設計-CLAUDE.md]]: llm-wiki 固有の設計判断
- [[lw-kit-詳細設計-rules]]: llm-wiki の rules 構成（wiki schema / wiki スタイル規約 等）
