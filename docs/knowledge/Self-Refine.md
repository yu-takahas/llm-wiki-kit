---
type: entity
tags: [prompt-engineering, self-improvement, technique]
sources:
  - 10_raw/20260517_効果的なプロンプト設計の方法論.md
  - Madaan et al., 2023. Self-Refine. Iterative Refinement with Self-Feedback
created: 2026-05-17
updated: 2026-05-17
---

# Self-Refine

LLM に「生成 → 自己批判 → 修正」のループを回させる手法。

## 提唱

Madaan et al., 2023. Self-Refine: Iterative Refinement with Self-Feedback.

## 効果

人間によるフィードバックなしで ~20% の品質改善。
プロンプト末尾に「上記の出力を 1 度読み直して、改善点を 3 つ挙げて修正してください」を追加するだけで効く。

## 構造

```text
1. 生成: モデルが Y を出力
2. 自己批判: モデルに「Y を読み直して、改善点を 3 つ挙げて」と指示
3. 修正: モデルが改善点を反映した Y' を出力
```

ループ停止条件は外部から与える（回数上限 / 品質スコア / 人間判断）。

## 関連

- [[Chain-of-Thought]] — 推論プロセス
- [[ReAct]] — 行動の評価
- [[効果的なプロンプト設計の方法論]] — 3 層整理の層 3
- [[プロンプト設計原則]] — レビュー → 修正フローの自動化（lw-doc-review → lw-fix-review）の根拠
