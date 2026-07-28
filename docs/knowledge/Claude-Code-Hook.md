---
type: entity
tags: [claude-code, hook, feature, deterministic]
sources:
  - https://code.claude.com/docs/en/hooks
created: 2026-05-17
updated: 2026-05-21
---

# Claude-Code-Hook

LLM を介さず、決定論的な処理を特定のタイミングで実行する仕組み。
[[ReAct]] ループの特定タイミングにユーザー定義のシェルコマンドを差し込める。
`settings.json` の `hooks` フィールドで定義する。

## 全 27 種（リーク source code より）

2026 年 3 月 31 日時点の `entrypoints/sdk/coreTypes.ts` から確認された 27 種類。
主要なもの:

| Hook                             | タイミング                         |
| -------------------------------- | ---------------------------------- |
| `SessionStart`                   | セッション開始時                   |
| `SessionEnd`                     | セッション終了時                   |
| `UserPromptSubmit`               | ユーザーがプロンプトを送信したとき |
| `Stop`                           | エージェントの応答完了時           |
| `PreToolUse`                     | ツール実行前                       |
| `PostToolUse`                    | ツール実行後（成功時）             |
| `PostToolUseFailure`             | ツール実行後（失敗時）             |
| `SubagentStart` / `SubagentStop` | Sub Agent 起動 / 終了時            |
| `PreCompact` / `PostCompact`     | Context Compactor 動作前 / 後      |
| `Notification`                   | 通知発生時                         |

他: `Setup` / `StopFailure` / `PermissionRequest` / `PermissionDenied` / `TaskCreated` / `TaskCompleted` / `Elicitation` / `ElicitationResult` / `ConfigChange` / `WorktreeCreate` / `WorktreeRemove` / `InstructionsLoaded` / `CwdChanged` / `FileChanged` / `TeammateIdle`。

## 動作の特徴

- LLM を介さない決定論的処理（ルールベース実装）
- ツール実行前後にカスタム処理を挟める（lint / format / 通知 / バリデーション等）
- `Stop` フックは応答完了後に発火、応答テキストの差し止め・修正はできない（続行阻止やサマリー追加のみ）
- `UserPromptSubmit` がブロックされた場合は `Stop` も発火しない
- `SessionStart` / `SessionEnd` は `/clear` / `/compact` 実行時にも再発火

## 用途例

- 編集前の自動 lint チェック（`PreToolUse` matcher: `Write|Edit`）
- 編集後の自動 formatter 実行（`PostToolUse` matcher: `Write|Edit`）
- セッション開始時の context 注入（`SessionStart`）
- compact 直前のキャッシュクリア（`PreCompact`）
- ターン終了前リマインダー注入（`Stop`）

## CLAUDE.md との使い分け

CLAUDE.md は文章による指示なので Claude が従わないリスクが残る。
**enforcement が必要なら Hook**。決定論的に実行されるので、確実性が要る場面（コミット前チェック / 必須 lint / 出力差し止め）に向く。

詳細は [[Claude-Codeのメモリ階層]]「トラブルシューティング」セクション参照。

## 関連

- [[Claude-Code内部実装]] — Hook の発火タイミングとアーキ全体での位置付け
- [[Claude-Codeのメモリ階層]] — CLAUDE.md / rules / skills と並ぶ Claude Code の拡張ポイント
- [[Sub-Agent]] — `SubagentStart` / `SubagentStop` イベント
- [[Claude-Codeのコマンド実行多層防御]] — PreToolUse hook が実行前検査層として効く文脈
- [[Claude-Code-Agent-Teams]] — `TeammateIdle` / `TaskCreated` / `TaskCompleted` フックの発火元
