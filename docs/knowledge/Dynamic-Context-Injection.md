---
type: entity
tags: [claude-code, skill, SKILL.md, feature]
sources:
  - https://code.claude.com/docs/en/skills
created: 2026-05-17
updated: 2026-05-17
---

# Dynamic Context Injection

Claude Code Skill の SKILL.md 本文に書ける機能。
`` !`command` `` の形式でシェルコマンドを記述すると、skill 起動前にシェルで実行され、出力が SKILL.md 本文の該当箇所に注入される。
Claude が実行するのではなく、skill 起動前の前処理として行われる。

## 例

```yaml
---
name: pr-summary
description: Summarize a pull request
context: fork
agent: Explore
allowed-tools: ["Bash(gh:*)"]
---

## PR 情報

- Diff: !`gh pr diff`
- コメント: !`gh pr view --comments`

## タスク

このPRを要約してください。
```

`gh pr diff` と `gh pr view --comments` が起動時に実行され、出力が本文に埋め込まれた状態で Claude に渡る。
動的に最新の情報を skill に渡したいときに便利。

## 制限

- MCP server 経由で配信された skill では無効化される
- ローカル skill（project / personal）のみで機能する

## 関連

- [[Claude-Code-Skillの書き方]] — Skill の書き方一般、本機能の位置付け
- [[context-fork]] — `context: fork` 内で Dynamic Context Injection を使うパターンが多い
- [[Claude-Code内部実装]] — skill の本文オンデマンドロードと組み合わせる Just-in-Time context 構築
