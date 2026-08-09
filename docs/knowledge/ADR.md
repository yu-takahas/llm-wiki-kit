---
type: entity
tags: [設計, ドキュメント, architecture-decision-record]
sources:
  - web 調査
created: 2026-07-23
updated: 2026-07-23
---

# ADR

Architecture Decision Record。
設計判断を記録するための軽量フォーマット。
Michael Nygard が 2011 年に提唱した。

## 構造

1 つの ADR は 3 要素で構成される:

- Context(文脈): 判断を迫られた状況、制約、背景
- Decision(決定): 選んだ方針と理由
- Consequences(結果): 決定がもたらす影響(良い面・悪い面の両方)

## ステータス遷移

Proposed → Accepted → Deprecated / Superseded。
決定が変わったときは元の ADR を編集せず、新しい ADR を作成して元を Superseded にする。

## 運用原則

append-only: 受理済みの記録は編集しない。
変更は新規記録で上書きし、前後をリンクで繋ぐ。

## llm-wiki-kit との対応

llm-wiki-kit の個別スキル設計書(`docs/lw-kit/40_スキル設計/`)は ADR に近い構造を既に持っている。
各設計書が「なぜこの設計か」(Context + Decision)と「却下した代替案」(Consequences の一部)を記述する形式は、ADR のバリエーションとして機能している。

違いは、llm-wiki-kit の設計書は ADR の append-only 原則を採用していない点。
設計が変わったら設計書自体を更新し、経緯は issue の経緯セクションに記録する。

## 関連

- [[ソフトウェア設計ドキュメント体系]] — 設計ドキュメントの体系全体の中での位置づけ
