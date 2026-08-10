---
type: entity
tags: [prompt-engineering, reasoning, CoT, technique]
sources:
  - Wei et al., 2022. Chain-of-Thought Prompting Elicits Reasoning in Large Language Models
  - https://platform.claude.com/docs/ja/build-with-claude/prompt-engineering/claude-prompting-best-practices
created: 2026-05-17
updated: 2026-08-10
---

# Chain of Thought

CoT。LLM に推論を段階的に説明させて複雑タスクの精度を上げる手法。
Wei et al. (2022) が示したのは、思考が既定で有効でないモデルに「Let's think step by step.」のような指示を足すと、複雑な推論タスクの精度が大きく向上するという効果。
思考が既定で有効なモデルでは事情が変わる（後述）。

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
| Haiku 4.5                  | 拡張思考のみ。指定しなければオフ |

思考が有効なら CoT は暗黙に働くので、「段階的に説明して」の明示指示は要らない。
Opus 5 では思考の無効化が effort `high` 以下に限られ、`xhigh` / `max` で無効化すると 400 エラーになる。

手動の CoT プロンプティングはフォールバックの位置づけになる。
第一選択は低い effort で思考を有効に保つことで、思考をオフに固定した統合でだけ `<thinking>` / `<answer>` のような構造化タグで推論と最終出力を分離する。

Opus 5 で思考を無効にすると 2 つのアーティファクトが出る。
内部 XML タグが可視の応答に漏れること、ツール呼び出しが構造化ブロックでなくテキストとして出力されて実行されないこと。
後者はエラーが出ないまま呼び出しが失われ、その文字列が会話履歴に残って後続のターンに影響するので、ツールを多用するワークロードで問題になりやすい。

思考が有効なモデルでも、過剰な Few-shot は逆効果になる。
例が多すぎると、モデルが例の長さや構造に引きずられて本来の出力から外れる（[[赤ずきんの原則]] 違反）。

## 関連手法

- [[Tree-of-Thoughts]] — CoT の推論枝を探索的に評価
- [[ReAct]] — CoT に外部ツール呼び出しを交互に挟む
- [[Self-Refine]] — CoT の結果を自己評価して改善

## 関連

- [[効果的なプロンプト設計の方法論]] — 3 層整理の層 3
- [[プロンプト設計原則]] — skill の Process 設計（タスクをステップに分解する設計手法）の根拠
