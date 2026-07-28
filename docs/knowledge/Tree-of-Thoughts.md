---
type: entity
tags: [prompt-engineering, reasoning, ToT, technique]
sources:
  - Yao et al., 2023. Tree of Thoughts. Deliberate Problem Solving with Large Language Models
created: 2026-05-17
updated: 2026-05-17
---

# Tree of Thoughts

ToT。複数の推論枝を生成 → 評価 → 選択を再帰する手法。[[Chain-of-Thought]] の発展形。

## 提唱

Yao et al., 2023. Tree of Thoughts: Deliberate Problem Solving with Large Language Models.

## 効果

Game of 24 のような探索的問題で精度が 4% → 74% に改善。
ただしコスト（呼び出し回数）は高い。

## 適合タスク

- 戦略立案
- ゲーム AI
- 複数案を出して trade-off 評価する設計判断

## 関連

- [[Chain-of-Thought]] — 単一経路の推論
- [[ReAct]] — 推論 + 外部ツール
- [[効果的なプロンプト設計の方法論]] — 3 層整理の層 3
- [[プロンプト設計原則]] — 複数案を出して trade-off 評価する設計判断（CLAUDE.md 改訂の案 A/B/C、render skill 名選定の 3 候補比較等）のメタファー
