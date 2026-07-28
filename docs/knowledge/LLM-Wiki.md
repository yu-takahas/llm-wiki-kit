---
type: concept
tags: [llm-wiki, karpathy, rag]
sources:
  - https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
  - github/llm-wiki-gist/
created: 2026-05-14
updated: 2026-05-14
---

# LLM Wiki

Andrej-Karpathy が提唱するパーソナル知識ベースのパターン。

## 中心アイデア

RAG（質問のたびに raw から再導出する）を捨て、LLM がソースを **一度コンパイルして wiki を作る**。
以降はその wiki を直接読む。
ナレッジは累積し、cross-reference は LLM が自動で貼り、矛盾は flag される。

> The knowledge is compiled once and then _kept current_, not re-derived on every query.

ナレッジは一度コンパイルされ、以降は **最新に保たれる** — クエリのたびに再導出するのではない。

## 3 層アーキテクチャ

- **raw**: 不変の元ソース。LLM は読むが書き換えない。llm-wiki では `10_raw/` に対応。
- **wiki**: LLM 生成・管理の markdown 群。llm-wiki では `30_wiki/` に対応。
- **schema**: agent 用の設定。Claude Code なら `CLAUDE.md`、Codex なら `AGENTS.md`。

## 主要オペレーション

- **ingest**: 新ソース投入時の取り込み。1 ソースで 10〜15 ページに波及することもある。
- **query**: wiki への質問。良い回答は新ページとして書き戻す。
- **lint**: 矛盾 / 孤立 / cross-ref 欠落 / 古い記述の検出。

## 従来との対比

|            | 従来（1 点もの方式）       | LLM Wiki 方式                                 |
| ---------- | -------------------------- | --------------------------------------------- |
| 単位       | 1 テーマ = 1 ファイル      | 1 概念 / 1 エンティティ / 1 ソース = 1 ページ |
| 編集者     | 人間                       | LLM                                           |
| 完成       | 完成稿がある               | 完成がない、常に育つ                          |
| 関連性     | 人間が `[[link]]` を手書き | LLM が cross-ref を自動補完                   |
| 更新の波及 | そのファイル単体           | 1 投入で 5〜15 ページに波及                   |

## なぜ動くのか

> The tedious part of maintaining a knowledge base is not the reading or the thinking — it's the bookkeeping.

ナレッジベースのメンテで面倒なのは、読むことでも考えることでもない — 管理作業だ。
LLM は飽きず、cross-reference を忘れず、1 pass で 15 ファイルに手を入れられる。

## llm-wiki での発展

- 旧 `20_canvas/` ディレクトリは廃止。代わりに `/lw-render` イベントで扱う。
- [[wiki-skills]] をベース実装に採用。

## 思想的源流

memex (Vannevar Bush, 1945) の精神的後継。
Bush が解けなかった「誰がメンテするか」を LLM が担う。

## 参考

- [Karpathy gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
