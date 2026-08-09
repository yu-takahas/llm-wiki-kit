---
type: entity
tags: [AI, LLM, Anthropic]
sources:
  - https://platform.claude.com/docs/ja/about-claude/models/overview
  - https://platform.claude.com/docs/ja/about-claude/models/whats-new-opus-5
created: 2026-07-07
updated: 2026-08-09
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
- Claude 4.6 世代: 適応的思考を導入し、拡張思考の手動バジェット（`budget_tokens`）を非推奨化
- Claude Opus 4.7: 新しいトークナイザを導入（同じテキストで従来より約 30% 多いトークンになる）。API パラメータの Temperature と `budget_tokens` を廃止
- Claude Fable 5 / Mythos 5（2026 年 6 月 9 日）: Opus の上位に位置する Mythos クラス。Mythos 5 は Project Glasswing の招待制で一般提供されない
- Claude Opus 5 / Sonnet 5: 思考が既定で有効。Opus 5 は 1M コンテキストが既定かつ最大で、より小さいバリアントを持たない

## 現行ラインナップ

Fable 5 / Opus 5 / Sonnet 5 / Haiku 4.5。
Opus 4.8 以前はレガシー扱いで、引き続き利用できる。

| モデル    | コンテキスト | 最大出力 | 思考                   |
| --------- | ------------ | -------- | ---------------------- |
| Fable 5   | 1M           | 128k     | 適応的思考、常にオン   |
| Opus 5    | 1M           | 128k     | 適応的思考、既定でオン |
| Sonnet 5  | 1M           | 128k     | 適応的思考、既定でオン |
| Haiku 4.5 | 200k         | 64k      | 拡張思考のみ           |

## 主な特徴

- [[Constitutional-AI]] による原則ベースのアライメント訓練
- 最大 1M トークンの長コンテキスト。Opus 5 ではウィンドウ全体を通して指示の遵守・ツール呼び出し・推論の一貫性を保つ
- エージェント的コーディングと長期タスク（複数ファイルにまたがる機能や大規模リファクタリングを、スタブを残さず完了まで持っていく）
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
