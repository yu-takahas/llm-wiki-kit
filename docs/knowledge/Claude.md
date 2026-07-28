---
type: entity
tags: [AI, LLM, Anthropic]
sources: []
created: 2026-07-07
updated: 2026-07-07
---

# Claude

Anthropic が開発する LLM ファミリーおよび AI アシスタント。
AI の安全性研究と能力開発を両立する設計思想のもと、[[Constitutional-AI]] で訓練されている。

## モデル系列の変遷

- Claude 1（2023 年 3 月）: 初の一般公開、API 提供開始。軽量版 Claude Instant を併設
- Claude 2（2023 年 7 月）: 100K トークンコンテキストウィンドウを導入
- Claude 3（2024 年 3 月）: 三層構成を導入 — Haiku（高速軽量）/ Sonnet（均衡）/ Opus（最高性能）。全層でビジョン入力対応
- Claude 3.5 Sonnet（2024 年）: Computer Use をパブリックベータとして提供開始
- Claude 3.7 Sonnet（2025 年 2 月）: 拡張思考（extended thinking）を導入、ハイブリッド推論
- Claude 4.x（2025 年 5 月〜）: 1M トークンコンテキスト（ベータ）、effort パラメータによる速度・能力のトレードオフ
- Claude Fable 5（2026 年 6 月）: Opus の上位に位置する Mythos クラス。Sonnet 5 が同月末に続く

## 現行ラインナップ（2026 年 7 月）

Fable 5 / Opus 4.8 / Sonnet 5 / Haiku 4.5。

## 主な特徴

- [[Constitutional-AI]] による原則ベースのアライメント訓練
- 最大 1M トークンの長コンテキスト
- コーディング能力（Opus 4.8 で SWE-bench Verified 80.8%）
- 安全性重視の設計（Amanda-Askell が主導する性格・価値観チーム）

## インターフェース

- claude.ai（Web / モバイル）
- Claude API（Python / TypeScript / Go / Java 等の SDK）
- Claude Code（CLI / VS Code / JetBrains 拡張 / デスクトップアプリ / claude.ai/code）
- Agent Teams（2026 年 3 月〜、並列マルチエージェントワークフロー）

## 関連

- Anthropic — 開発元
- [[Constitutional-AI]] — 訓練手法
- Amanda-Askell — 性格・価値観設計の主導者
- RLHF — Constitutional AI の比較対象
