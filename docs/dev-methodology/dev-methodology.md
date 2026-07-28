---
type: project
tags: [開発手法, TDD, AI駆動開発, ワークフロー, ガードレール]
sources:
  - conversation
created: 2026-07-13
updated: 2026-07-28
---

# dev-methodology

案件横断の開発手法プロジェクト。
TDD ベースのワークフロー、AI 駆動開発のガードレール設計、テスト戦略を体系化し、各案件の CLAUDE.md / rules / hooks に binding として落とし込む。

## スコープ

コーディング開発手法を扱う。

- TDD の実践（Red-Green-Refactor サイクル、TODO リスト駆動）
- AI 駆動開発のワークフロー（explore-plan-code-commit、context engineering、検証ループ）
- ガードレールの層設計（advisory / deterministic / permission）
- テスト戦略（テストピラミッド / トロフィー、CDD / Visual TDD）
- エスカレーション経路（rules → hook → skill → フレームワーク）

## 境界

| プロジェクト                 | 扱うもの                                                        | 扱わないもの       |
| ---------------------------- | --------------------------------------------------------------- | ------------------ |
| dev-methodology              | コーディング開発手法の原則と why                                | 案件固有の binding |
| ワークスペース（my-wiki 等） | ワークスペース運用（skill 設計、レビューサイクル、wiki 規約）   | 開発手法の原則     |
| 他の業務手法プロジェクト     | PdM 業務手法（UX リサーチ、PRD、ロードマップ）等                | コーディングの話   |
| 各案件                       | 案件固有の binding（テストランナー、hooks 具体、settings 具体） | 原則の定義         |

dev-methodology が原則と why を持ち、各案件の設計書が binding（how）を持つ。
ワークスペース側の source page（[[テスト駆動開発の実践]] / [[AI駆動開発のワークフロー]] / [[Claude-Code開発ワークフロー系エコシステム]]）は外部知識の要約で、本プロジェクトの設計書はそれらを自分の方針として判断・取捨選択したもの。

## 方針

- 調査 → 設計 → 各案件へ binding の流れで進める
- 設計書は決定事項のみ書く（検討経緯は issue に置く）
- 各案件の rules / hooks / settings は案件側の設計書が担う
- 導入はエスカレーション経路に従い、advisory（rules）から始めて必要に応じて deterministic（hooks / skill）に昇格する

## 派生 page

- [[dev-methodology-ワークフロー基本設計]] — 二重ループ構造、ガードレール配置層、テスト戦略
- [[dev-methodology-CLAUDE.md設計]] — 助言層の配備先としての案件 CLAUDE.md
- [[dev-methodology-settings.json設計]] — permission 層としての案件 settings.json
- [[lw-kit-スキル設計-lw-tdd]] — TDD skill（ワークスペース側に配置）
- [[lw-kit-ガイド設計-dev-guide]] — 開発 issue の TODO メニュー（ワークスペース運用側に配置）

## 関連 wiki page

汎用知識（`30_wiki/`）:

- [[テスト駆動開発の実践]] — TDD の基本手法
- [[AI駆動開発のワークフロー]] — AI コーディング時代の開発手法
- [[Claude-Code開発ワークフロー系エコシステム]] — Claude Code の skill/plugin/hooks

関連プロジェクト:

- [[lw-kit]] — ワークスペース運用（skill 設計、レビューサイクル）
