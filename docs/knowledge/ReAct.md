---
type: entity
tags: [prompt-engineering, reasoning, agentic, technique]
sources:
  - Yao et al., 2022. ReAct. Synergizing Reasoning and Acting in Language Models
created: 2026-05-17
updated: 2026-05-17
---

# ReAct

Reasoning（思考）と Acting（外部ツール呼び出し）を交互に行わせる手法。

## 提唱

Yao et al., 2022. ReAct: Synergizing Reasoning and Acting in Language Models.

## 構造

```text
思考: ユーザーは Y を求めている、X を呼ぶべき
行動: tool_call X
観察: X の結果
思考: 結果から Y を構築できる
回答: Y
```

API 呼び出し・Web 検索・ファイル読み書きを内包する agentic workflow の基礎技術。

## 関連実装

Claude Code の Agent ツールや tool use loop は ReAct の派生。
lw-cmux-teams 経由の lead / teammate 構造も「lead が思考・判断、teammate が行動」という ReAct 的分業。

## 関連

- [[Chain-of-Thought]] — 推論のみ
- [[Tree-of-Thoughts]] — 推論枝の探索
- [[Self-Refine]] — 行動結果の自己評価
- [[効果的なプロンプト設計の方法論]] — 3 層整理の層 3
- [[プロンプト設計原則]] — Agent ツール / lw-cmux-teams の lead-teammate 構造の根拠
