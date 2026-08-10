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
Just-in-Time context 管理の発想。

## 何を分離するか

分離の線は「起動のたびに要るか」で引く。

SKILL.md に残すもの:

- 起動条件と、この skill が何をするかの判断材料
- 既定の手順（大半の実行で通る道筋）
- 守らせたい制約

別ファイルへ逃がすもの:

- 網羅的なリファレンス（全 API・全オプション・全パターン）
- 低頻度の分岐や例外ケースの手順
- 長い実例・サンプル集

判断に迷ったら「この情報は毎回の起動で読まれる価値があるか」を問う。
答えが「特定の状況でだけ要る」なら別ファイル側。

実際のファイル構成の例は [[Claude-Code-Skillの書き方]]「基本構造」セクション。

## 制約

参照は **1 段階まで**（SKILL.md → reference.md）。
ネストすると（SKILL.md → a.md → b.md）、部分プレビュー（`head -100` 等）で止まり全文を読み切らないため情報が欠ける可能性がある。

## なぜ重要か

SKILL.md は起動時に全文が context に積まれる。
詳細を全部 SKILL.md に書くと毎回のロードコストが高くなり、消費した分だけモデルの指示遵守率が下がる。
公式は SKILL.md を 500 行未満に保ち、詳細なリファレンスは別ファイルに移すことを勧めている。

reference.md に逃がせば必要時のみ読み込まれるので、長いリファレンスを持っていても使うまでコストはほぼかからない。
根拠は context の量であって、情報が context のどこに置かれるかではない（位置による劣化は現行モデルには当てはまらない、[[Lost-in-the-Middle]]「測定されたものと外挿されたもの」セクション）。

CLAUDE.md と Skill の使い分け（[[Claude-Codeのメモリ階層]]）と同じ思想で、context への load を「常時 / 条件付き / オンデマンド」の 3 段階で設計するのが基本（auto memory による自動蓄積は別軸なので含めない）。

## 関連

- [[Claude-Code-Skillの書き方]] — SKILL.md のベストプラクティス一般、description の文字数上限
- [[Claude-Codeのメモリ階層]] — CLAUDE.md / rules / skills の階層全体での適用、サイズ規律（500 行 / 200 行）の数値
- [[チェーホフの銃の誤謬]] — 不要情報を入れない、Progressive Disclosure と同根の発想
- [[Lost-in-the-Middle]] — context 内の位置による劣化現象、Progressive Disclosure の根拠（量）とは別軸
