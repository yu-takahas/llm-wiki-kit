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
- 親の context を引き継がせたくない作業（空 context で始まる利点が効く場面）

委任しない:

- 自分で数回のツール呼び出しで終わる作業
- 自分の作業の検証・再確認。Opus 5 は指示なしで検証するので二重になる
- ステップ間で context を保つ必要がある作業
- 単一ファイルの編集や、順次実行で足りる操作

spawn 数は低く保つのが基本で、1 つで足りるなら 1 つに留まる。
ハーネスが起動数の制御を持つ場合は、プロンプトでの抑制に加えて設定側で決定論的な上限を掛けられる。

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

- Explore / Plan などのビルトインエージェントタイプは読み取り専用ツールのみアクセス可能（安全設計）
- 汎用 Sub Agent（`general-purpose`）は書き込みツール（FileEditTool / BashTool 等）も使用可能

## 非公式情報の出所

次の 2 節（「実装名の変遷」「Fork モード」）は公式 docs にも CHANGELOG にも記載がない。
出所はリバースエンジニアリング記事 3 本（Reid Barber / Kir Shatrov / ShareAI Lab）で、難読化されたコードからの推定を含む。
独立した 3 本の記述が一致しているので内容の確度は低くないが、ShareAI Lab の解析は v1.0.33 時点で、現行の 2.x で変わっている可能性がある。

## 実装名の変遷

時期によって内部名が変わっている。

- `AgentTool`（Reid Barber）
- `dispatch_agent`（Kir Shatrov）
- `Task`（ShareAI Lab、解析時点で最新）

公開 docs では `Agent` tool として参照される。

## Fork モード（フィーチャーフラグ）

通常の Sub Agent が空 context で始まるのに対し、親 context を引き継ぐモード。
プロンプトキャッシュを親子で共有し、並列リサーチや実装分割のコストを下げる設計。
名前が近い [[context-fork]] とは別の機能。

## 関連

- [[Claude-Code内部実装]] — Sub-Agent Spawner / 隔離方式（V8 isolate, seccomp）/ システムプロンプトの詳細
- [[Claude-Code-Skillの書き方]] — Skill と Sub Agent の使い分け
- [[context-fork]] — 同じく独立 context で動作する Skill / Agent モード
- [[ReAct]] — Sub Agent spawn は ToolUse 扱いで 1 ループ余分
- [[Claude-Code-Hook]] — `SubagentStart` / `SubagentStop` イベントあり
- [[Claude-Code-Agent-Teams]] — teammate との違い（独立フル instance + mailbox 協調 vs 空 context で結果返却のみ）
- [[Claude-Code並列セッション運用]] — frontmatter `isolation: worktree` で subagent ごとに一時 worktree を切る隔離方式
