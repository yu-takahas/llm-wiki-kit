---
type: entity
tags: [claude-code, skill, design-principle, context-management]
sources:
  - https://code.claude.com/docs/en/skills
created: 2026-05-17
updated: 2026-08-10
---

# Progressive Disclosure

Anthropic 公式の skill 設計原則。
SKILL.md を最小限に保ち、詳細は別ファイル（reference.md / examples.md など）に分離して必要時のみ読み込ませる構造。
Just-in-Time コンテキスト管理の発想。

## ファイル構成

```text
my-skill/
├── SKILL.md           # メイン（概要 + 参照先）
├── reference.md       # 詳細リファレンス（必要時のみ load）
├── examples.md        # 使用例
└── scripts/
    └── helper.py      # 実行スクリプト、context に入らない
```

## 制約

参照は **1 段階まで**（SKILL.md → reference.md）。
ネストすると（SKILL.md → a.md → b.md）Claude が途中で止まる可能性がある。

## なぜ重要か

SKILL.md は起動時に全文が context に積まれる。
詳細を全部 SKILL.md に書くと毎回のロードコストが高くなり、消費した分だけ遵守率が下がる。
公式は SKILL.md を 500 行未満に保ち、詳細なリファレンスは別ファイルに移すことを勧めている。

reference.md に逃がせば必要時のみ読み込まれるので、長いリファレンスを持っていても使うまでコストはほぼかからない。
根拠は context の量であって、情報が context のどこに置かれるかではない。

CLAUDE.md と Skill の使い分け（[[Claude-Codeのメモリ階層]]）と同じ思想で、context への load を「常時 / 条件付き / オンデマンド」の 3 段階で設計するのが基本。

## 関連

- [[Claude-Code-Skillの書き方]] — SKILL.md のベストプラクティス一般、サイズ規律と description の文字数上限
- [[Claude-Codeのメモリ階層]] — CLAUDE.md / rules / skills の階層全体での適用
- [[チェーホフの銃の誤謬]] — 不要情報を入れない、Progressive Disclosure と同根の発想
