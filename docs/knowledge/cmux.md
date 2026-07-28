---
type: entity
tags: [cmux, multi-agent, terminal, claude-code, tool]
sources:
  - https://github.com/manaflow-ai/cmux
  - https://cmux.com/docs/agent-integrations/claude-code-teams
created: 2026-05-29
updated: 2026-07-15
---

# cmux

manaflow-ai 製の macOS ネイティブターミナルアプリ（Ghostty ベース）。
vertical tab sidebar、split pane、embedded browser、socket API を持ち、複数の AI エージェントを並列実行する用途に特化している。
Homebrew でインストール: `brew tap manaflow-ai/cmux && brew install --cask cmux`（macOS 14.0+）。

## Claude Code Agent Teams との統合

- `cmux claude-teams` で [[Claude-Code-Agent-Teams]] を cmux のネイティブペインとして起動する（既存セッション内からではなく別セッションとして立ち上げ、そのセッションが lead になる）
- teammate がペイン分割として自動スタックされる（垂直右カラム）、spawn / exit に応じて自動リサイズ。各ペインは sidebar にメタデータ付きで表示され、通知リングで注意が必要な pane が分かる
- このコマンドは内部で `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` を設定し、tmux の PATH を cmux の tmux-compat レイヤーで shim する。具体的には tmux shim を `~/.cmuxterm/claude-teams-bin/tmux` に置いて `cmux __tmux-compat` にリダイレクトし、`claude --teammate-mode auto` を exec する。Claude は tmux 上で動いていると認識しつつ、`split-window` / `send-keys` / `capture-pane` 等が cmux の native split API に翻訳される
- `claude-teams` の後の引数は全て Claude Code に forward される（`cmux claude-teams [--continue] [--model sonnet]` 等）
- `--dangerously-skip-permissions` で権限確認をスキップできる（要注意）
- `teammateMode` のネイティブバックエンドとする要望が出ている（anthropics/claude-code#36926）。現状は tmux shim 経由で動作しており、Claude Code 側のネイティブ統合は未実装
- SSH relay daemon 経由でリモート環境でも動作する（`cmux ssh user@remote` でリモートワークスペースを作成）

## 対応エージェント

Claude Code 以外にも Codex / OpenCode / Gemini CLI / Kiro / Aider / Goose / Amp / Cline / Cursor Agent 等、ターミナルで起動できるエージェントに対応する。

## 関連

- [[Claude-Code-Agent-Teams]] — cmux ペインで動かす対象の協調機構
- [[Agent-Teams運用パターン]] — cmux + Agent Teams を回すときの成功 / 失敗 / Tips
