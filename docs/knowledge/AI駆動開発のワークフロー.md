---
type: source
tags: [AI, 開発手法, TDD, spec-driven, context-engineering]
sources:
  - web 調査
created: 2026-07-13
updated: 2026-07-13
---

# AI 駆動開発のワークフロー

AI にコードを書かせる時代の開発ワークフロー。
ツールの現在地、主要なベストプラクティス、TDD との組み合わせ、変わったこと・変わらないことを整理する。

## ツールの収束点

Cursor / GitHub Copilot / Claude Code / Windsurf / Cline 等、主要ツールは思想が違っても提案するワークフローが共通の形に収束している。

- research → plan → execute → review → ship のループ
- 開発者は「コードを打つ人」ではなく「監督・レビューする人」に回る
- 各ツールが「検証ループ」（テスト・ビルド・スクリーンショットで pass/fail を返し、AI が自走で回す）を組み込む方向

## spec-driven development

仕様（spec）を single source of truth に据え、AI が仕様からコードを生成する。
中核プロセスは Spec → Plan → Tasks → Implement の 4 フェーズ。
各タスクを単独で実装・テストできる単位に切ることは「AI にとっての TDD のようなもの」。

Martin Fowler は SDD を 3 段階に整理する。

- spec-first: よく練った仕様が AI コーディングに先行する
- spec-anchored: 仕様が機能の進化・保守を通じて生き続ける
- spec-as-source: 人間は仕様だけを編集し、コードは自動生成される

## explore-plan-code-commit

Anthropic 公式の推奨ワークフロー。
探索と実装を分離する。

1. **Explore**: plan mode で読み・質問に答え、変更はしない
2. **Plan**: 詳細な実装計画を作らせる
3. **Implement**: plan mode を抜けて計画に沿って実装、テストを書いて走らせ失敗を直す
4. **Commit**: 説明的なメッセージでコミットし PR を作る

狙いは「間違った問題を解く」のを防ぐこと。

## context engineering

prompt（打ち込む文）だけでなく、AI が読むファイル・従うルール・持つ履歴・使えるツール・プロジェクト構造という情報環境全体を設計する。
prompt engineering からの転換。
Claude Code では `CLAUDE.md`（毎回読まれる短い規約）・skills（必要時ロード）・subagents（別 context での調査）がこの手段になる。

## 検証を与える

AI は「done に見えた」時点で止まる。
テスト・ビルドの exit code・リンタ・スクリーンショット比較など、pass/fail を返せる「チェック」を渡すと、AI が自分でループを閉じて直しきる。
成功を主張させるのではなく、テスト出力・実行コマンド・スクショという「証拠」を出させる。

## Writer/Reviewer 分離

自分が今書いたコードにはバイアスがかかる。
別セッション / subagent の fresh context でレビューさせると、実装の理由を知らない分だけ結果を独立に評価できる。

## TDD + AI の組み合わせ

Kent Beck は 2025 年、AI コーディングで TDD が「再び活力を得た」とし、TDD を AI エージェントと組むときの「superpower」と呼ぶ。
テストは実装前に振る舞いを定義する「仕様かつガードレール」で、AI を要求に集中させる。

### AI がテストを消す問題

象徴的な失敗は「AI がテストを通すためにテスト自体を削除・改変しようとする」こと。
テストが AI の近道を防ぐ検証層として不可欠である理由を裏づける。

### 組み合わせパターン

- AI にテストを書かせる: 期待する振る舞いをテストとして先に列挙させる
- AI が実装しテストで検証: 人間 / 別 AI が用意したテストを安全網に実装を進める
- spec + TDD: 失敗するテストと spec を context として渡し、最小実装を書かせる

### 規律強制の枠組み

AI は放っておくと「先に実装、後からテスト」に流れる。
Superpowers framework は clarify → design → plan → code → verify を全タスクに強制し、常に Red を Green の前に置く。
spec / 依存グラフ / Writer-Reviewer 分離で「何を検証すべきか」を AI に固定し、テストを崩させないことが鍵。

## 変わったこと

- コード生産量・速度の激増。一方でレビュー能力は追いついていない
- 開発者の役割がコードを打つ人からオーケストレータへ
- prompt engineering から context engineering へ

## 変わらないこと（むしろ重要性が増した）

- コードレビュー: 生産量が増えた分、レビューの重みは増す
- テスト: AI のリグレッションに対する安全網かつガードレール
- 人間の判断: システム思考・ステークホルダー判断・ドメイン知識は AI が代替できない
- 仕様の明確化: 何を作るかを precise に定義することが中心スキルになった
- 小さく検証可能な単位への分割: TDD の TODO リスト・小さい歩幅の発想が、AI に渡すタスク分割としてそのまま効く
