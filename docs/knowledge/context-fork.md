---
type: entity
tags: [claude-code, skill, agent, feature, isolation]
sources: []
created: 2026-05-17
updated: 2026-05-17
---

# context fork

Skill / Agent を会話履歴にアクセスしない独立した context で実行するモード。
frontmatter に `context: fork` を書くと有効。
スキル本文が「親の文脈に汚染されない」ので、徹底的な調査や独立した処理に向く。

## 設定

```yaml
---
name: deep-research
description: Research a topic thoroughly in isolation
context: fork
agent: Explore   # Explore / Plan / general-purpose または custom
---

$ARGUMENTS を徹底的に調査してください。
```

- `agent` で subagent タイプを指定可能
- skill の `effort` フィールドは agent 定義にマージされる
- fork 実行は ToolUse 扱い、[[ReAct]] ループが 1 回余計に回る

## Fork モード（リーク source code より）

通常の `context: fork`（空 context）とは別に、**親の context をまるごと引き継ぐ Fork モード**（フィーチャーフラグ制御）も実装されている。
プロンプトキャッシュを親子で共有し、並列リサーチや実装分割のコストを下げる設計。

## 関連

- [[Sub-Agent]] — 独立 context で動作するエージェント、context fork と同根の発想
- [[Dynamic-Context-Injection]] — `context: fork` 内で前処理として併用するパターン
- [[ReAct]] — fork は ToolUse 扱いで 1 ループ余分
- [[Claude-Code-Skillの書き方]] — skill 起動制御の選択肢の一つ
