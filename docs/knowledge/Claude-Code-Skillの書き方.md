---
type: concept
tags: [claude-code, skill, SKILL.md, best-practice]
sources:
  - https://code.claude.com/docs/en/skills
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
  - "[[探索・活用ジレンマ]]"
  - https://platform.claude.com/docs/ja/build-with-claude/prompt-engineering/prompting-claude-opus-5
  - https://platform.claude.com/docs/ja/build-with-claude/prompt-engineering/claude-prompting-best-practices
created: 2026-02-11
updated: 2026-08-10
---

# Claude Code Skill の書き方

Claude Code のカスタム skill（SKILL.md）作成のベストプラクティス。
skill のロードタイミングや CLAUDE.md / rules との使い分けは [[Claude-Codeのメモリ階層]]、本ページは skill の責務設計と SKILL.md 内部の書き方を扱う。

## 責務分割は探索 vs 活用で判定する

[[探索・活用ジレンマ]]:

LLM はデフォルトで greedy（活用）に倒れる非対称性が、skill の責務設計の判定基準として効く。
1 skill に探索の所作（棚卸し / 候補列挙 / 既存一巡走査 / リファクタ要否判断）と活用の所作（決め打ちで畳む / 実行）を同居させると、活用側の慣性で探索が空振りする（exploration collapse と同型）。

判定: 1 skill の責務に探索と活用が両方入っていたら分割する。

- 新規 skill 設計時のトリガー: 「やること多すぎ」と感じたら、探索フェーズと活用フェーズが両方含まれていないかを問い、含まれていれば分割を lead に提案する
- 既存 skill のリファクタ時も同じ基準で「分けたほうがよくないか」と提案する
- 事例: `/lw-commit`（活用）に「ちゃんと反映やりきったか」「リファクタ要否」（探索）を同居させ「該当なし」空振り → `/lw-retro` を別 skill に剥がして解消
- 例外: 探索 → 活用が必ず連続発火し結果を直接消費するケース（review → fix の [[Self-Refine]] 型）は、1 skill 内で見出し分離（`## 探索` / `## 活用`）+ 引数 flag による mode 切替（`--fix` 等）で代替可

## 自由度を task に合わせる

指示の具体度は、対象の壊れやすさとばらつきで決める。

| 自由度 | 書き方                               | 使う場面                                            |
| ------ | ------------------------------------ | --------------------------------------------------- |
| 高     | 文章での指示                         | 複数のやり方が成立する / 判断が文脈に依存する       |
| 中     | 疑似コードやパラメータ付きスクリプト | 推奨パターンがある / ある程度のばらつきは許容できる |
| 低     | 具体的なスクリプト、パラメータは最小 | 操作が壊れやすい / 一貫性が要る / 手順が固定        |

公式の比喩は「崖に挟まれた細い橋」と「障害物のない野原」。
橋なら安全な道は 1 つしかないので、具体的なガードレールと正確な手順を与える（順序が決まっている DB マイグレーションのようなもの）。
野原なら多くの道が成功に通じるので、方向だけ示してモデルに任せる（文脈が最適解を決めるコードレビューのようなもの）。

kit の skill もこの軸で分かれる。
`lw-commit` の Process は低自由度（実行するコマンドをリテラルで書く）、`lw-doc-review` の観点は高自由度（何を見るかだけ示す）。
新しい skill を設計する時に、どちらへ寄せるかを先に決める。

## 基本構造

skill 名はディレクトリ名で決まる。
ディレクトリ内に SKILL.md を配置する。
単体の .md ファイルは認識されない。

```text
my-skill/
├── SKILL.md           # メイン
├── reference.md       # 詳細（必要時のみ load）
├── examples.md
└── scripts/
    └── helper.py      # 実行スクリプト、context に入らない
```

参照は 1 段階まで（SKILL.md → reference.md）。
ネストすると、Claude が `head -100` のようなコマンドで部分的にプレビューして全文を読まないことがあり、情報が欠ける。
この設計原則の詳細は [[Progressive-Disclosure]]。

100 行を超える reference ファイルには冒頭に目次を置く。
部分読みされた場合でも、何が書いてあるかの全体像は見える。

## 命名

`name` の制約は 64 文字以内、小文字英数とハイフンのみ、XML タグ不可、予約語（`anthropic` / `claude`）不可。

公式が勧めるのは動名詞形（`processing-pdfs` / `analyzing-spreadsheets`）で、その skill が何をする活動なのかが名前で分かる。
名詞句（`pdf-processing`）や動詞形（`process-pdfs`）も許容される。
避けるのは曖昧な名前（`helper` / `utils` / `tools`）と広すぎる名前（`documents` / `data` / `files`）。

kit は `lw-` prefix + 動詞形（`lw-render` / `lw-commit`）で統一している。
prefix は bundled skill との衝突回避も兼ねる（「配置場所」セクション参照）。

## frontmatter

全フィールドが optional だが `description` は推奨。

```yaml
---
name: my-skill                 # 表示名（省略時はディレクトリ名）
description: ...               # 推奨、Claude が自動起動を判断
when_to_use: ...               # 起動条件を補足、description に付加される

disable-model-invocation: true # Claude の自動呼び出しを禁止（手動のみ）
user-invocable: false          # ユーザーの /name 起動を禁止

allowed-tools: [Read, Edit]    # 最小権限
context: fork                  # fork | inline、fork で独立 context
agent: Explore                 # context: fork 時の subagent タイプ
model: sonnet                  # haiku | sonnet | opus | inherit
effort: high                   # low | medium | high | max | 数値
shell: bash                    # bash | powershell

argument-hint: "[filename]"    # autocomplete ヒント
arguments: [arg1, arg2]        # 名前付き引数

paths: "src/**, tests/**"      # glob、該当ファイル編集時のみ自動起動候補
hooks: ...                     # skill 固有 hook
---
```

## description のコツ

- **third person で書く**（公式用語、`I can help...` / `You can use...` は NG）
  - action-oriented 三単現動詞で始める：`Explains` / `Renders` / `Validates`
  - `Use when ...` 単体は命令形で third person 視点を満たさないため、action description と組み合わせる
- `description` 単体は 1,024 char 以内。frontmatter のバリデーション上限で、超えると通らない
- `description` + `when_to_use` の合算は skill listing で 1,536 char に切り詰められる（`skillListingMaxDescChars` で変更可）。上限が 2 種類あるので混同しない
- 英語で書く（context 効率）
- ユーザーが言いそうなフレーズを含める

### third person の根拠

公式 [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) は明示的に "Always write in third person" を要求している。

> The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems.

description は system prompt に injection されるため、視点ブレが Claude の自動起動判断（discovery）を壊す。
1 文目で「何をするか」（action description）、2 文目で「いつ起動するか」（trigger 情報）を分離するのが安定パターン。

### 良い例

```yaml
description: Explains code with visual diagrams and analogies. Use when explaining how code works, teaching about a codebase, or when the user asks "how does this work?"
description: Renders a raw source into the llm-wiki wiki. Triggers when the lead adds a new raw source and needs it propagated as 5-10 wiki pages.
```

### 悪い例

- `description: Code helper tool` — 何をするか不明
- `description: I can help you with X` — 一人称
- `description: You can use this to X` — 二人称
- `description: Use when adding X` — 命令形のみ、action description と組み合わせるべき

### コンテキスト消費

description は毎回 system prompt に積まれる。

```text
全 skill 合計の予算 = context window × 4 char/token × 1%
                     （200k token なら ~8,000 char）
1 skill の表示上限 = 1,536 char（description + when_to_use 合算、skillListingMaxDescChars で変更可）
最小表示長         = 20 char
```

予算超過時は skill 名のみにフォールバックする。
bundled skill（組み込み）は切り詰め対象外。

## 本文の書き方

### 簡潔さ

SKILL.md にハードなサイズ制限はないが、起動時に全文が context に積まれる。
各情報に問いかける: 「Claude はこれを知っているか？」「このトークンコストに見合うか？」

良い例（~50 token）:

```markdown
## PDF テキスト抽出
pdfplumber を使用:
\`\`\`python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
\`\`\`
```

悪い例（~150 token）: 「PDF とは Portable Document Format の略で...」← Claude は知っている。

### 時間依存の情報を書かない

「2025 年 8 月より前なら旧 API を使う」のような書き方をしない。
時間が経つと誤りになり、しかも誤りだと気づかれにくい。

現行の手順だけを本文に書き、過去の方式が要るなら「旧方式」の節に隔離する。
折りたたみ（`<details>`）に入れれば、履歴を残しつつ本文は現行だけになる。

### 選択肢を並べすぎない

複数のやり方を並べるとモデルが迷う。
既定を 1 つ示し、必要なら例外だけ添える。

```text
NG: pypdf でも pdfplumber でも PyMuPDF でも pdf2image でもよい
OK: テキスト抽出には pdfplumber を使う。スキャン PDF で OCR が要る場合だけ pdf2image + pytesseract に切り替える
```

### 言語選択

| 部分        | 推奨言語  | 理由                                      |
| ----------- | --------- | ----------------------------------------- |
| frontmatter | 英語      | Token 効率                                |
| 本体        | 日本語 OK | `language: japanese` 設定があれば問題なし |

### 命令は断定的に

```text
NG: You might want to consider using the Read tool...
OK: Use the Read tool to read files. Do NOT use cat or head.
```

### 肯定形を既定にする

スタイルや挙動の誘導は肯定形で書く。
資料は「してはいけないことではなく、すべきことを伝える」「望むスタイルの肯定的な例は、何をしないかについての指示より効果的」としている。

否定形を使うのは、例外なしの禁止事項（破壊的操作・安全にかかわるもの）に限る。
その場合も理由を添えると効く。

```text
NEVER skip hooks (--no-verify) unless the user explicitly requests it.
Do not create documentation files unless explicitly requested.
```

資料の対比例は「省略記号を使うな」より「読み上げエンジンが発音できないので使わない」の方が効く、という形。
禁止の字面だけ書くより、なぜそうしてほしいかを添える方が他の場面にも一般化する。

### 制約は具体的な操作を列挙

抽象的な「変更しないで」より具体的な操作を並べる:

```text
IMPORTANT: This skill is read-only. Do not:
- Create new files
- Modify existing files
- Delete files
- Use redirect operators (>, >>, |)
```

列挙する形はそのままでよい。
装飾バナー（`=== CRITICAL: ===`）と `STRICTLY PROHIBITED` のような強語調は落とす。

### 出力量を制御する

SKILL.md は下限側（省略させない）の指示に偏りやすく、上限側の規定を置き忘れる。
Opus 5 は既定の応答が以前のモデルより長く、作業中のナレーションも増える。
effort を下げても目に見える応答は確実には短くならないので、量はプロンプトで明示的に指示する。

書く対象は 3 種類。

- 応答の簡潔さ — 主要な回答に分量を割き、前置きと留保を短くする
- 作業中のナレーション — 重要な発見と方向転換のときだけ更新する
- 成果物ドキュメントの長さ — 実質に見合う分量にし、詰め物をしない

長い指示文では、末尾近くに短いリマインダーを置いて本文の指示と対にする。

出力を減らすことと、探索や走査を省略させないことは別の軸で扱う。
「該当なしでも報告する」のような報告義務は走査を駆動する装置なので、量を減らすときは報告そのものを消さず、個別報告を集約報告に畳む。

### 完了時の出力形式を指定する

出力の形式と粒度を明示すると結果が安定する:

```text
When you complete the task, respond with a concise report covering
what was done and any key findings — the caller will relay this to
the user, so it only needs the essentials.
```

Plan Agent の例では末尾に必ず `### Critical Files for Implementation` + ファイルリストを出力させている。

### ツールの使い分けを明示する

使うツールを先に書き、置き換え対象を `instead of` で添える:

```text
- To read files use Read instead of cat, head, tail, or sed
- To edit files use Edit instead of sed or awk
- To search for files use Glob instead of find or ls
```

### 例外条件を `unless` で

禁止ルールだけだとモデルが過度に保守的になる。
指示に文字通り従うので、逃げ道を書いておかないと必要な場面でも実行しない。

```text
Do not skip hooks unless the user explicitly requests it.
```

### 強調マーカー

既定は普通の書き方にする。
`CRITICAL: You MUST use this tool when...` のような強い語調はツールや skill の過剰トリガーを引き起こすので、`Use this tool when...` に落とす（この指摘の出典は主語が Opus 4.5 / 4.6）。

強マーカーを使うのは例外なしの制約に限る。
公式のサンプルプロンプトも `NEVER output a series of overly short bullet points` のように使い続けているので、禁止されているわけではない。
効き目の源泉は稀少性で、全部を `CRITICAL` にすると何も `CRITICAL` でなくなる。1 ファイルに数箇所まで。

| マーカー           | 使う場面                                           |
| ------------------ | -------------------------------------------------- |
| `IMPORTANT:`       | 読み飛ばされると困る指示                           |
| `NEVER` / `ALWAYS` | 例外なしのルール（破壊的操作・安全にかかわるもの） |
| `Do NOT` / `MUST`  | 強い禁止・義務                                     |
| `<example>`        | few-shot 例（強調ではなく構造化）                  |

トリガー条件と頻度指示には使わない。
「迷ったら使う」「デフォルトで使う」の型は過剰トリガーを招くと資料が名指ししている。
装飾バナー（`=== CRITICAL: ===`）も使わない。

## 手順省略を仕組みで防ぐ

LLM は「この状況なら不要」と推論してステップを省く。禁止指示 1 行では止まらないため、設計段階で解釈の余地を減らす。

- 自然言語指示をコマンドリテラルに置き換える。範囲・対象を語で指定すると解釈で狭まる（「直下 + サブディレクトリ」→ 一部が漏れる）。実行するコマンドそのものを書けば解釈の余地がなくなる
- resist-table（言い訳対戦表）で省略の推論を先回りする。「〜だから省略してよい」という浮かびがちな言い訳と、それへの現実を表で対置する。省略が起きやすいのはモード分岐（quick 等）で「このモードなら不要」と推論する地点
- 省略されて困る動作は 1 箇所でなく複数箇所（全体像 / 言い訳対戦表 / 必須動作）に置く。1 箇所の指示は文脈次第で読み飛ばされる
- 層を分ける。SKILL.md のチェックリストは advisory（順番を忘れないための指針）。誠実性の担保が必要な制約は deterministic 層（hooks / settings / allowed-tools）で締める

## 評価を先に作る

公式の推奨は、詳しい手順を書く前に評価を作ること。
順序は「skill 無しで代表タスクを実行して失敗を記録する → その失敗を突く評価を 3 つ作る → 基準値を測る → 評価を通る最小限の指示を書く → 反復する」。

想像した要件ではなく実際に起きた失敗から書き始めるので、使われない記述が減る。

kit のミスドリブン更新（試運転で見つかった失敗を言い訳対戦表に追記する）は近い役割を持つが、こちらは skill を書いた後の改善サイクル。
書く前の段階に評価を置くと、最初から短く書ける。

## リンクを腐らせない

SKILL.md / rule 本文に他 rule / Skill / wiki page への path 列挙や 「関連」セクションを並べると、参照先の rename / split / merge で腐る。
Claude は `paths` 条件付きロード / 常時ロード / wiki link 解決で他 rule や wiki page を別途取得できる前提で、本体は zero-shot で書ける指示に絞る。

具体的な書き方:

- 「関連」セクションは最小化（根拠 / 反証ケースの 1-2 件のみ、対象範囲を示すための網羅リストは載せない）
- 対象ファイル種別ごとの参照リストを書かない（rules 構成が変わるたびに直す必要が出る）
- 必要な詳細フォーマット（frontmatter / セクション構成 / 命名規約）は「対象ファイルの規約に従う」と抽象的に書き、列挙しない

SKILL.md だけでなく rules / CLAUDE.md にも同じく適用される。

## 呼び出し制御

| 設定                             | Claude 自動 | ユーザー `/name` | description が context に入る |
| -------------------------------- | ----------- | ---------------- | ----------------------------- |
| デフォルト                       | Yes         | Yes              | Yes                           |
| `disable-model-invocation: true` | No          | Yes              | No（軽量化）                  |
| `user-invocable: false`          | Yes         | No               | Yes                           |

`disable-model-invocation: true` は deploy / commit 等タイミングを自分で制御したい操作に使う。
副次効果で description も context に入らなくなり軽量化される。
context に積まれない以上、description を英語化する実利もない。日本語記述で十分。

## allowed-tools

最小権限の原則で必要なツールのみ:

```yaml
allowed-tools: [Read, Grep, Glob]                    # 読み取り専用
allowed-tools: [WebFetch, WebSearch, Write, Read]    # Web 調査
allowed-tools: ["Bash(gh:*)"]                        # GitHub CLI のみ
```

Bash はパターンで制限可能: `Bash(npm:*)` / `Bash(git commit:*)`。

## 文字列置換

skill 本文中で使える変数（`utils/argumentSubstitution.ts` の順序）:

```text
1. $arg_name           ← arguments: [arg_name] で定義した名前
2. $ARGUMENTS[0]       ← 0 ベース index
3. $0 / $1             ← $ARGUMENTS[N] のショート
4. $ARGUMENTS          ← 全引数文字列
5. ${CLAUDE_SKILL_DIR} ← skill のディレクトリパス
   ${CLAUDE_SESSION_ID}
6. !`command`          ← Dynamic Context Injection（後述）
```

名前付き引数は純粋な数字を名前にできない（`$0` 等のショートと衝突）。

### 本文に `$N` を含むスクリプトを直書きしない

置換は skill 本文全体に無条件で走るため、awk / bash のコード例に `$0` / `$2` 等が含まれると、引数なし起動時に空文字へ置換されてスクリプトが壊れた状態で本文が展開される（`line = $0` → `line =`）。
`$NF` / `$(command)` / `$'\t'` は数字ショートに一致しないため無事で、壊れるのは `$0`-`$9` のみ。
対策: スクリプトは `scripts/` 配下の補助ファイルに置き、本文からは `bash ${CLAUDE_SKILL_DIR}/scripts/<name>.sh` で参照する（補助ファイルは置換対象外）。

## Dynamic Context Injection

SKILL.md 本文中の `` !`command` `` を skill 起動前にシェル実行し、出力を本文に注入する機能。
Claude が実行するのではなく前処理。
MCP server 経由の skill では無効化される（local skill のみ機能）。
構文・例・使い分けは [[Dynamic-Context-Injection]] 参照。

## context: fork

`context: fork` で会話履歴にアクセスしない独立 context で skill を実行する。
fork は ToolUse 扱いで [[ReAct]] ループが 1 回余計に回る。
設定・Fork モード（フィーチャーフラグ）・Sub Agent との関係は [[context-fork]] 参照。

## 配置場所

| 場所       | path                               | 適用範囲         |
| ---------- | ---------------------------------- | ---------------- |
| Enterprise | managed settings                   | 組織全体         |
| Personal   | `~/.claude/skills/<name>/SKILL.md` | 全プロジェクト   |
| Project    | `.claude/skills/<name>/SKILL.md`   | そのプロジェクト |
| Plugin     | `<plugin>/skills/<name>/SKILL.md`  | プラグイン有効時 |

同名衝突の解決順は enterprise > personal > project。
どのレベルに置いた skill も、同名の bundled skill を上書きする（project の `.claude/skills/code-review/` は bundled の `/code-review` を置き換える）。
plugin skill は `plugin-name:skill-name` の名前空間を持つので他のレベルとは衝突しない。
`.claude/commands/` のファイルも同じ扱いで、skill と command が同名なら skill が優先される。

Claude Code は `/doctor` / `/code-review` / `/debug` / `/loop` / `/batch` 等を bundled skill として配布している。
`disableBundledSkills` で一括無効にできる（`/doctor` だけは残る）。

2026-06-25 の実測では逆の結果が出ていた（`~/.claude/skills/code-review/` に自作版を置いても built-in のフローが走り、skill 一覧にも built-in の description が出た）。
現行仕様では自作側が勝つ。

どちらにせよ prefix を付けておけば衝突自体が起きない（llm-wiki では `lw-` prefix を採用）。

## Permissions

```text
Skill                  # 全 skill 無効
Skill(commit)          # 特定 skill のみ許可
Skill(review-pr *)     # プレフィックスマッチ
Skill(deploy *)        # 特定 skill を deny
```

## 本文の推奨構造

```markdown
# Skill Title

## Inputs
- `$arg_name`: 入力の説明

## Goal
明確な目的の記述

## Steps

### 1. ステップ名
やること。

Success criteria: このステップ完了の基準
Rules: 守るべきルール
```

## 関連

- [[Claude-Codeのメモリ階層]]: CLAUDE.md / rules / skills の使い分け、ロードタイミング
