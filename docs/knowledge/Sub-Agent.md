---
type: entity
tags: [claude-code, agent, feature, isolation]
sources: []
created: 2026-05-17
updated: 2026-05-30
---

# Sub Agent

親 Claude とは独立した空の context で動作するエージェント。
Tool Executor 経由で spawn され、完了時に結果（最終出力テキスト + メタデータ）だけを親に返す。

## 特徴

- 親の会話履歴は引き継がれない（別タブで新規チャットを開くイメージ）
- 完了時に最終出力 + メタデータ（トークン数 / ツール使用回数 / 所要時間）を親に返す
- 親の context がどれだけ膨らんでも Sub Agent には影響しない（逆も同様）

## モード

| モード           | 動作                       |
| ---------------- | -------------------------- |
| フォアグラウンド | 親をブロック、対話的に実行 |
| バックグラウンド | 並列実行可能、親は作業継続 |

## ツール権限

- Explore / Plan などのビルトインエージェントタイプは **読み取り専用ツールのみ** アクセス可能（安全設計）
- 汎用 Sub Agent（`general-purpose`）は書き込みツール（FileEditTool / BashTool 等）も使用可能

## 実装名の変遷（リバエン）

時期によって内部名が変わっている:

- `AgentTool`（Reid Barber）
- `dispatch_agent`（Kir Shatrov）
- `Task`（ShareAI Lab、最新）

公開 docs では `Agent` tool として参照される。

## Fork モード（フィーチャーフラグ）

リーク source code に存在する、親 context を引き継ぐモード。
プロンプトキャッシュを親子で共有し、並列リサーチや実装分割のコストを下げる設計。
通常の Sub Agent（空 context）とは別物（[[context-fork]] とは別の機能）。

## 関連

- [[Claude-Code内部実装]] — Sub-Agent Spawner / 隔離方式（V8 isolate, seccomp）/ システムプロンプトの詳細
- [[Claude-Code-Skillの書き方]] — Skill と Sub Agent の使い分け
- [[context-fork]] — 同じく独立 context で動作する Skill / Agent モード
- [[ReAct]] — Sub Agent spawn は ToolUse 扱いで 1 ループ余分
- [[Claude-Code-Hook]] — `SubagentStart` / `SubagentStop` イベントあり
- [[Claude-Code-Agent-Teams]] — teammate との違い（独立フル instance + mailbox 協調 vs 空 context で結果返却のみ）
- [[Claude-Code並列セッション運用]] — frontmatter `isolation: worktree` で subagent ごとに一時 worktree を切る隔離方式
