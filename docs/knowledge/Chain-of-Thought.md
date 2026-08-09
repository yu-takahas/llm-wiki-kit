---
type: entity
tags: [prompt-engineering, reasoning, CoT, technique]
sources:
  - Wei et al., 2022. Chain-of-Thought Prompting Elicits Reasoning in Large Language Models
  - https://platform.claude.com/docs/ja/build-with-claude/prompt-engineering/claude-prompting-best-practices
created: 2026-05-17
updated: 2026-08-09
---

# Chain of Thought

CoT。LLM に推論を段階的に説明させて複雑タスクの精度を上げる手法。
「Let's think step by step.」または「推論を段階的に説明して」と指示するだけで、複雑な推論タスクの精度が大きく向上する。

## 提唱

Wei et al., 2022. Chain-of-Thought Prompting Elicits Reasoning in Large Language Models.

## 思考が既定のモデルでの扱い

CoT を明示指示するかは、モデルの思考が既定で有効かどうかで決まる。
現行の Claude では設定がモデルごとに違う。

| モデル                     | 思考の既定                       |
| -------------------------- | -------------------------------- |
| Fable 5 / Mythos 5         | 常にオン、設定で切れない         |
| Opus 5 / Sonnet 5          | `thinking` を省略するとオン      |
| Opus 4.6〜4.8 / Sonnet 4.6 | `thinking` を省略するとオフ      |
| Haiku 4.5                  | 拡張思考のみ、適応的思考は非対応 |

思考が有効なら CoT は暗黙に働くので、「段階的に説明して」の明示指示は要らない。
Opus 5 では思考の無効化が effort `high` 以下に限られ、`xhigh` / `max` で無効化すると 400 エラーになる。

手動の CoT プロンプティングはフォールバックの位置づけで、思考をオフにして動かす統合でだけ使う。
その場合は `<thinking>` / `<answer>` のような構造化タグで推論と最終出力を分離する。
ただし Opus 5 で思考を無効にすると内部 XML タグが可視の応答に漏れることがあるため、低い effort で思考を有効にしたままにする方が推奨される。

過剰な Few-shot が逆効果になる点は変わらない（[[赤ずきんの原則]] 違反、訓練データの zero-shot 路線から逸れる）。

## 関連手法

- [[Tree-of-Thoughts]] — CoT の推論枝を探索的に評価
- [[ReAct]] — CoT に外部ツール呼び出しを交互に挟む
- [[Self-Refine]] — CoT の結果を自己評価して改善

## 関連

- [[効果的なプロンプト設計の方法論]] — 3 層整理の層 3
- [[プロンプト設計原則]] — skill の Process 設計（タスクをステップに分解する設計手法）の根拠
