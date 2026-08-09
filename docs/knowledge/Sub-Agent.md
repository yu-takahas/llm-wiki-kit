---
type: entity
tags: [claude-code, agent, feature, isolation]
sources:
  - https://platform.claude.com/docs/ja/build-with-claude/prompt-engineering/prompting-claude-opus-5
  - https://platform.claude.com/docs/ja/build-with-claude/prompt-engineering/claude-prompting-best-practices
created: 2026-05-17
updated: 2026-08-10
---

# Sub Agent

親 Claude とは独立した空の context で動作するエージェント。
Tool Executor 経由で spawn され、完了時に結果（最終出力テキスト + メタデータ）だけを親に返す。

## 委任の判断基準

Opus 5 は以前のモデルより積極的に委任する。
委任が効くのは真に独立した規模の大きい作業で、小さなタスクに適用するとコストと時間が倍増する。
既定に任せると過剰になりやすいので、抑制する側の指示が要る。

委任する:

- 独立して並列に走らせられる規模の大きい作業（複数ファイルにまたがる調査など）
- 隔離した context が要る作業
- 状態を共有しない独立した作業の流れ

委任しない:

- 自分で数回のツール呼び出しで終わる作業
- 自分の作業の検証・再確認。Opus 5 は指示なしで検証するので二重になる
- ステップ間で context を保つ必要がある作業
- 単一ファイルの編集や、順次実行で足りる操作

1 つで足りるなら 1 つにし、spawn 数は低く保つ。
コストに敏感なワークロードでは、起動できるエージェント数に決定論的な上限を設ける方法もある。

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

出所は 2026-03-31 に公開された source map から復元されたもので、`@anthropic-ai/claude-code@2.1.88` 時点。
公式 docs にも CHANGELOG にも記載がなく、裏取りできていない。
以降のバージョンで変わっている可能性がある。

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
