---
type: concept
tags: [claude-code, internals, reverse-engineering, architecture]
sources:
  - https://reidbarber.com/blog/reverse-engineering-claude-code
  - https://kirshatrov.com/posts/claude-code-internals
  - https://www.blog.brightcoding.dev/2025/07/17/inside-claude-code-a-deep-dive-reverse-engineering-report/
  - https://kotrotsos.medium.com/claude-code-internals-part-1-high-level-architecture-9881c68c799f
  - https://www.sabrina.dev/p/reverse-engineering-claude-code-using
  - github/claude-code-leak/
created: 2026-03-16
updated: 2026-07-06
---

# Claude Code 内部実装

リバースエンジニアリング記事 5 本と `github/claude-code-leak/` リポジトリの解析から見えた Claude Code v1.x〜v2.1 の内部構造。
内部の難読化変数名（`nO` / `h2A` 等）は **推定**、Anthropic 公式名称ではない。
公式仕様は [[Claude-Codeのメモリ階層]] / [[Claude-Code-Skillの書き方]] を参照。

## アーキテクチャ全体

単一の LLM 呼び出しではなく **多段階 LLM パイプライン**（Kir Shatrov による mitmproxy 実測）。

3 層構造（Marco Kotrotsos）:

```text
[User Interaction Layer]
  Terminal CLI / VS Code / Web UI

[Agent Core Layer]
  Master Loop (nO) → Async Message Queue (h2A) → StreamGen (wu)
    ↕
  ToolEngine (MH1) & Scheduler (UH1) → 18+ tools

[Integration Layer]
  Anthropic API (HTTPS) / MCP Client
```

内部モジュール名（BrightCoding、難読化変数名から推定）:

| 内部名           | 役割                                                                                    |
| ---------------- | --------------------------------------------------------------------------------------- |
| `nO`             | Master Loop（Masterless マルチエージェント制御ループ）                                  |
| `h2A`            | Steering バス（ゼロレイテンシ・ロックフリー・デュアルバッファの非同期メッセージキュー） |
| `wu` / StreamGen | ストリーミング生成エンジン                                                              |
| `wU2`            | Context Compressor                                                                      |
| `MH1`            | Tool 実行エンジン                                                                       |
| `UH1`            | スケジューラ                                                                            |
| `I2A`            | サブタスクエージェント（V8 isolate 隔離）                                               |

## 多段階パイプライン

ユーザー入力 → 「新規トピック判定」LLM 呼び出し → 入力ルーティング → Tool 実行 ...

新規トピック判定（Kir Shatrov 観測）:

```text
"Analyze if this message indicates a new conversation topic"
→ { "isNewTopic": bool, "title": string }
```

単純なルーティングではなく LLM で入力を分類している。

### 入力ルーティング（Reid Barber）

| 入力種別                             | 処理先                 |
| ------------------------------------ | ---------------------- |
| Bash Command（`!` プレフィックス等） | BashTool               |
| Slash Command                        | Command Executor       |
| 通常プロンプト                       | モデルへのパッケージ化 |

## Tool 群

公開 docs での名称と、リバースエンジニアリングで観測された内部名は微妙に異なる。

### Reid Barber が確認した内部名

ファイル操作: `FileReadTool` / `FileWriteTool` / `FileEditTool` / `NotebookReadTool` / `NotebookEditTool` / `GlobTool` / `GrepTool` / `LSTool`

実行・エージェント: `BashTool` / `AgentTool` / `ArchitectTool`（読み取り専用、実装計画生成） / `ThinkTool`（[[ReAct]] の Reasoning フェーズを明示ツール化、tau-bench 着想）

外部連携: `MCPTool` / `MemoryReadTool` / `MemoryWriteTool` / `StickerRequestTool`（イースターエッグ）

### Kir Shatrov が観測した 13 ツール

`dispatch_agent` / `Bash` / `BatchTool` / `GlobTool` / `GrepTool` / `LS` / `View` / `Edit` / `Write` / `Replace` / `ReadNotebook` / `NotebookEditCell` / `WebFetchTool`

### ShareAI Lab が抽出した内部定数

```javascript
TASK_TOOL_NAME = "Task"          // サブエージェント起動ツール
WEB_FETCH_TOOL_NAME = "WebFetch"
todoListToolDescription
```

Sub-Agent Spawner の最新実装名は `Task`。公開 docs では `Agent` tool として参照される。

## Sub-Agent Spawner

Sub Agent の一般仕様（モード / ツール権限 / Fork モード）は [[Sub-Agent]] 参照。
ここではリバースエンジニアリングで観測された内部情報のみ記録する。

実装名の変遷: `AgentTool`（Reid Barber）→ `dispatch_agent`（Kir Shatrov）→ `Task`（ShareAI Lab）。
サブエージェントに付与されるツール（Kir Shatrov）: `View` / `GlobTool` / `GrepTool` / `LS` / `ReadNotebook` / `WebFetchTool`。
「最初の数回で正しいマッチが見つかると確信できない場合に使え」という指示が system prompt に組み込まれている。

### 隔離方式（BrightCoding）

| 種別           | 隔離            | 権限                   |
| -------------- | --------------- | ---------------------- |
| `I2A` Sub-task | V8 isolate      | FS・Net 制限           |
| Task Agent     | spawn + seccomp | syscall ホワイトリスト |
| MCP Bridge     | Docker / WASM   | プラグイン単位ポリシー |
| nO Master Loop | なし            | フル                   |

ShareAI Lab の設計思想:

> サブエージェントに操作されるな、あなたが操作する側であれ。

## Permission System

Reid Barber:

- `FileWriteTool` / `FileEditTool` / `BashTool` / `MCPTool` は権限チェック必須
- 読み取り専用ツールはプロジェクト外アクセス時のみ権限要求（非対称設計）
- 承認モードは「一時的」「永続的」2 種類
- `BashTool` には banned commands のセキュリティチェックあり

ツール実行サイクル:

```text
Permission Check → User Prompt（必要時）→ Tool Invocation → Tool Result
```

### 6 層セキュリティゲート（BrightCoding）

| 層                        | 役割                          | 例                           |
| ------------------------- | ----------------------------- | ---------------------------- |
| 1. UI                     | 表示レイヤーフィルタ          |                              |
| 2. Router                 | メッセージ型 ACL、`eval` 拒否 |                              |
| 3. ツールホワイトリスト   | 使用可ツール制限              | `grep` 許可、`rm -rf /` 拒否 |
| 4. パラメータスキーマ検証 | ツール引数型チェック          |                              |
| 5. 中間処理               |                               |                              |
| 6. Output                 | TEE・ポリシー・トークン赤字化 |                              |

### Bash の Pre-Guardrails（Kir Shatrov）

Bash 実行前に LLM 2 段階チェック:

1. コマンドプレフィックスを抽出 → `command_injection_detected` フラグ判定（Haiku）
2. 操作対象のファイルパスを抽出（別プロンプト）

`Policy Spec` という内部ドキュメントがコマンドインジェクション判定の根拠として参照されている。

## Context Compressor（wU2）

トークン使用率 > 92% でトリガー（BrightCoding）。
実測圧縮率 6.8 倍（意味損失 < 3%）。

手順:

1. メッセージごとに重要度スコア算出: `importance = f(length, recency, tool_calls)`
2. 貪欲法で上位 30% トークン保持
3. LLM 自己批判（self-critique）で残りをサマリー化

## Context Builder（Kir Shatrov）

system prompt に埋め込まれる要素:

- `env` — 実行環境情報
- `directoryStructure` — 会話開始時のファイルツリー（**会話中は更新されない**）
- `gitStatus` — ブランチ・直近コミット
- `CLAUDE.md` の内容

重要: `directoryStructure` は会話開始時点のスナップショット。会話中にファイル追加・変更しても反映されない。

### システムプロンプトのキャッシュ境界設計

`constants/prompts.ts`（約 900 行）の構成。変わらない部分を前方に、変わる部分を後方に配置し、API のプロンプトキャッシュを最大限活用する:

```text
[静的セクション - グローバルにキャッシュ可能]
  1. Intro（アイデンティティ）
  2. System（ツール、権限モデル）
  3. Doing Tasks（タスク実行ガイドライン）
  4. Actions（リスク評価）
  5. Using Your Tools（ツール使い分け）
  6. Tone and Style（スタイル）
  7. Output Efficiency（簡潔さ）

__SYSTEM_PROMPT_DYNAMIC_BOUNDARY__

[動的セクション - セッションごとに変わる]
  8. Memory（ユーザー/プロジェクトメモリ）
  9. Language（言語設定）
  10. 環境情報（OS, git status, モデル名）
  11. MCP/Skill一覧
  12. CLAUDE.md内容
```

CLAUDE.md は `utils/claudemd.ts` で注入時に「IMPORTANT: These instructions OVERRIDE any default behavior and you MUST follow them exactly as written.」というプレフィックスが付与される。
CLAUDE.md はシステムプロンプトのデフォルト動作をオーバーライドできる位置づけ。

### ビルトイン Agent 定義スキーマ

`tools/AgentTool/built-in/` で定義される Agent のスキーマ:

- description: 何をするか（短く）
- tools / disallowedTools: 使えるツール / 禁止ツール
- prompt: システムプロンプト
- model: モデル指定
- maxTurns: 最大ターン数

ロール文の共通パターン: `"You are a [専門性] for [製品名]"` → 制約 → ツール使用ガイド → 出力形式。
Explore Agent は `"You are a file search specialist for Claude Code"`、Plan Agent は `"You are a software architect and planning specialist for Claude Code"`。

## モデル選択（Kir Shatrov）

| 用途                        | モデル    |
| --------------------------- | --------- |
| 推論が必要な処理            | Sonnet 系 |
| 単純なパース（Bash 解析等） | Haiku 系  |

著者実測: プロジェクト説明だけで 40 秒・$0.11 消費。Bash コマンド解析は GPT-3.5-turbo の 10 倍コスト相当（$15 / 百万出力トークン）。

## Hooks イベント（Marco Kotrotsos）

リバースエンジニアリングで観測された Hook イベント（部分一覧）:

```text
PreToolUse / PostToolUse / PostToolUseFailure
Stop / SessionStart / SessionEnd / Notification
UserPromptSubmit / SubagentStart / SubagentStop
PreCompact / TaskCompleted
```

全 27 種の一覧と動作の詳細は [[Claude-Code-Hook]] 参照。

## 拡張機能のコンテキスト消費（Marco Kotrotsos）

| 拡張      | コンテキスト影響                                                          |
| --------- | ------------------------------------------------------------------------- |
| Skills    | オンデマンドロード。`disable-model-invocation: true` で呼ぶまで説明文のみ |
| MCP       | ツール定義が毎リクエストに追加されるため消費が大きい                      |
| Hooks     | ループ割り込み、コンテキスト消費なし                                      |
| Subagents | 独立コンテキスト、結果サマリーのみ返却                                    |

## WebFetch の制限

Kir Shatrov: ユーザーメッセージ / CLAUDE.md / プロジェクトファイルに記載されたホストの URL のみ取得可能（ホワイトリスト）。

ShareAI Lab のツール定義から:

- 15 分セルフクリーニングキャッシュ
- HTTP → HTTPS 自動アップグレード
- 引用は 125 文字以内
- MCP-provided web fetch があれば MCP 側を優先

## TODO ツール（ShareAI Lab）

状態: `pending` / `in_progress` / `completed`

- `in_progress` は同時に 1 タスク
- 使用条件: 3 ステップ以上かつ自明でないタスク
- 単純タスクには使用禁止

## PLAN MODE（ShareAI Lab）

`PLAN MODE System Reminders` という動作モード。通常モードとは system reminder が切り替わる設計。

## 推論深度キーワード（Marco Kotrotsos）

プロンプト内で渡すと推論の深さを制御:

- `megathink`
- `ultrathink`

## VCR（Visual Cassette Recorder、Reid Barber）

内部テスト基盤。API 呼び出しを初回に記録 → 以降はリプレイで本物の呼び出しを回避。外部非公開。

## サービス層（Reid Barber）

| サービス | 役割                             |
| -------- | -------------------------------- |
| Statsig  | フィーチャーフラグ・分析イベント |
| Sentry   | エラーレポート                   |
| OAuth    | Anthropic Console 認証           |
| Notifier | デスクトップ通知（iTerm2 対応）  |

## 依存ライブラリ（ShareAI Lab）

Sentry / Zod / Protobuf / Ink.js / React

## 雑学

- Claude Code 内部コードネーム: tengu（Marco Kotrotsos）
- コードの約 90% を Claude Code 自身が生成・保守（Marco Kotrotsos）
- 単一ファイル `cli.js` として配布、10.5MB（Marco Kotrotsos、v2.0.76 時点）

## 設計哲学（Reid Barber）

> シンプルなツールセットと強力なモデルの組み合わせが効果を生む。

複雑な仕組みを作らず、明確な役割のシンプルなツール群とモデルの能力に任せる。

## 検証用一次資料

`github/claude-code-leak/` に Claude Code v2.1.88 の source snapshot（2026-03-31 source map exposure 経由）を clone 済み。
学術・セキュリティ研究目的（`.gitignore` 済み、push しない）。
リバースエンジニアリング記事の主張を直接検証したい時の参照点。

## 信頼性の注意

内部名（`h2A` / `nO` / `wU2` 等）は **難読化変数名からの推定**、Anthropic 公式名称ではない。
記事 5 本のうち BrightCoding は AgentKode という再現実装を公開（Apache 2.0）、Marco Kotrotsos は Medium 有料記事のため一部関連情報からの再構成。
公開 docs の [[Claude-Codeのメモリ階層]] / [[Claude-Code-Skillの書き方]] の方が信頼性は高い。

## 関連

- [[Claude-Codeのメモリ階層]]: 公式 docs ベース、CLAUDE.md / rules / skills 仕様
- [[Claude-Code-Skillの書き方]]: SKILL.md のベストプラクティス
