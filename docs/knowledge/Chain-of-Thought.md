---
type: entity
tags: [prompt-engineering, reasoning, CoT, technique]
sources:
  - Wei et al., 2022. Chain-of-Thought Prompting Elicits Reasoning in Large Language Models
created: 2026-05-17
updated: 2026-05-17
---

# Chain of Thought

CoT。LLM に推論を段階的に説明させて複雑タスクの精度を上げる手法。
「Let's think step by step.」または「推論を段階的に説明して」と指示するだけで、複雑な推論タスクの精度が大きく向上する。

## 提唱

Wei et al., 2022. Chain-of-Thought Prompting Elicits Reasoning in Large Language Models.

## モデル種別と使い分け

| モデル                                        | 推奨                                  |
| --------------------------------------------- | ------------------------------------- |
| 通常モデル（GPT-4o / Claude Sonnet 等）       | 明示的に CoT 指示 + Few-shot 例を併用 |
| 推論モデル（GPT-5 / Claude Opus 4.7 / o1 系） | 暗黙に CoT 有効化、zero-shot 優位     |

推論モデルに対して過剰な Few-shot を入れると逆効果（[[赤ずきんの原則]] 違反、訓練データの zero-shot 路線から逸れる）。

## 関連手法

- [[Tree-of-Thoughts]] — CoT の推論枝を探索的に評価
- [[ReAct]] — CoT に外部ツール呼び出しを交互に挟む
- [[Self-Refine]] — CoT の結果を自己評価して改善

## 関連

- [[効果的なプロンプト設計の方法論]] — 3 層整理の層 3
- [[プロンプト設計原則]] — skill の Process 設計（タスクをステップに分解する設計手法）の根拠
