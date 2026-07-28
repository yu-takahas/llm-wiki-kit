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
updated: 2026-07-21
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

MEMORY.md の 200 行 / 25KB 制限は MEMORY.md のみに適用される。
CLAUDE.md は長さに関係なく全文ロードされる（ただし短い方が遵守率は高い）。
v2.1.210 で制限超過時の警告機能、v2.1.211 で YAML frontmatter / HTML コメントの計測前除去が追加された。

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

| 軸       | auto memory                                                   | `.claude/rules/`                   |
| -------- | ------------------------------------------------------------- | ---------------------------------- |
| 場所     | `~/.claude/projects/<project>/memory/`                        | `<workspace>/.claude/rules/`       |
| ロード   | 全セッション常時                                              | paths 条件付き or 常時             |
| スコープ | プロジェクト個別だが他プロジェクト作業中も常時 context に乗る | workspace 内、paths で path 限定可 |
| 性格     | ユーザー個人の好み・知識・運用ルール                          | workspace 規約                     |
| 例       | commit type の好み / 中間ファイル片付け / lead の作業分担     | wiki / issue                       |

workspace 規約を auto memory に書くと、他プロジェクト作業中も常時 context に乗ってノイズになる。
workspace に閉じる規約は `.claude/rules/` + `paths:` 条件付きで該当時のみロードする方が筋。

## ファイル階層と優先度

ロード順（広い順 → 狭い順、後にロードされた方が context 内で新しい位置に来て効きやすい）：

1. Managed policy（IT/DevOps 管理、OS 別の system path）
2. User: `~/.claude/CLAUDE.md`
3. Project: `./CLAUDE.md` / `./.claude/CLAUDE.md`（cwd から root まで walk-up）
4. Local: `./CLAUDE.local.md`（gitignore 推奨）
5. Auto memory: `~/.claude/projects/<project>/memory/MEMORY.md`

サブディレクトリ内の `CLAUDE.md` はオンデマンド（そのサブディレクトリのファイル Read 時にロード）。
ancestor の `CLAUDE.md` は launch 時に全部ロードされて concatenate される。

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

- `paths` なし → CLAUDE.md と同じ launch 時ロード
- `paths` あり → Claude が matching file を Read した瞬間にロード、セッション中保持
- glob + brace expansion 対応
- symlinks 対応（複数 project で共有可能）
- user-level rules: `~/.claude/rules/` も同様（project rules より前にロード）

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
- import されたファイルは結局 launch 時にロードされる（context 節約にはならない、組織化のため）

context を節約したいなら `paths:` rule の方を使う。

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

会話が長くなると [[Lost-in-the-Middle]] で遵守率が落ちる（context 中央の情報は 30% 以上劣化する U 字型性能曲線）。

`/compact` 実行時はキャッシュクリア → ディスクから再読込 → 新しい位置に再注入される（project root の CLAUDE.md は compact 後も自動で再注入される）。
ネストされた subdirectory の CLAUDE.md は compact 後 自動再注入されない、次にそのディレクトリのファイル Read 時に reload される。

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
| MEMORY.md（auto memory）               | 200 行 / 25KB（超えた分は topic file に分割、自動的に）       |
| Skill description + `when_to_use` 合算 | 1,536 char cap（`skillListingMaxDescChars` で変更可）         |
| Skill listing 全体の文字予算           | context window の 1%（`skillListingBudgetFraction` で変更可） |

> Longer files consume more context and reduce adherence.
> — 公式 memory docs

行数が増えるほど context を圧迫し、Claude の遵守率が下がる。
普遍的に適用可能な指示のみに絞り、path 限定で済むものは rules に移す。

### 具体値・列挙を書かない

ディレクトリ構成やコマンド説明に、ファイル名の列挙・件数・サイズ等の具体値を書くと、実装が変わるたびに CLAUDE.md の更新が必要になり、更新をサボると腐る。
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

## 情報ソース

- [Claude Code 公式 memory docs](https://code.claude.com/docs/en/memory)
- [Claude Code 公式 skills docs](https://code.claude.com/docs/en/skills)
- [Best Practices for Claude Code](https://code.claude.com/docs/en/best-practices)
- [How Boris Uses Claude Code](https://howborisusesclaudecode.com/)
- [Writing a good CLAUDE.md (HumanLayer)](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [How to Write a Good CLAUDE.md File (Builder.io)](https://www.builder.io/blog/claude-md-guide)
- [CLAUDE.md と --append-system-prompt の違い (Zenn/CureApp)](https://zenn.dev/cureapp/articles/65b9a99d22ce2b)
- ソースコード: `@anthropic-ai/claude-code@2.1.88`（2026-03-31 source map leak、要 verify）

## 関連

- [[lw-kit-詳細設計-CLAUDE.md]]: llm-wiki 固有の設計判断
- [[lw-kit-詳細設計-rules]]: llm-wiki の rules 構成（wiki schema / wiki スタイル規約 等）
