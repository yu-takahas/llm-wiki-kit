---
type: entity
tags: [LLM, context-window, paper, phenomenon, attention]
sources:
  - https://arxiv.org/abs/2307.03172
created: 2026-05-17
updated: 2026-05-17
---

# Lost in the Middle

LLM が長コンテキストを処理する際、先頭と末尾の情報を優先的に参照し、中央の情報は劣化する現象。
論文「Lost in the Middle: How Language Models Use Long Contexts」(Liu et al., 2023, [arxiv:2307.03172](https://arxiv.org/abs/2307.03172)) で提唱・実証された。

## 現象

LLM はコンテキストの先頭・末尾の情報を優先し、中央の情報は **30% 以上劣化する U 字型性能曲線** を示す。
長いコンテキストでドキュメント検索や Q&A を行うと、答えが中央付近にあるほど正解率が下がる。

## 構造的な利用

context 先頭は「最も参照されやすい位置」なので、各社のチャット AI は最上位の隠しプロンプト（Anthropic の core system prompt、OpenAI の Root / System 層）をここに配置している。
これは訓練による命令階層学習（[The Instruction Hierarchy](https://arxiv.org/abs/2404.13208), ICLR 2025）に加えて、Lost in the Middle に対する **構造的な対策** でもある。

## CLAUDE.md と Lost in the Middle

[[Claude-Codeのメモリ階層]] 「注入メカニズム」セクションで扱う通り、CLAUDE.md は session 最初に `<system-reminder>` でユーザーメッセージ列の先頭近くに注入される。
session 開始直後は context 先頭にあるため強く効くが、会話が長くなるにつれ中央に埋もれて遵守率が落ちる。
`/compact` 実行時はキャッシュクリア → ディスクから再読込 → 新しい位置に再注入されることで回復する。

## 対策

- 重要情報は context の先頭または末尾に置く（サンドイッチ戦略、[[効果的なプロンプト設計の方法論]] 「3 層整理」セクションの「層 1」）
- 長 session では `/compact` を活用して再注入する
- 頻度ベースのルール（「○○のたびに××する」）は session 後半で薄れるので、メタトリガー（「ユーザー報告を返す前」）を併用する（[[プロンプト設計原則]] 「long session の作業漏れ対策」セクション）

## 関連

- [[Claude-Codeのメモリ階層]] 「注入メカニズム」セクション — CLAUDE.md の注入位置と効力の変化
- [[効果的なプロンプト設計の方法論]] — サンドイッチ戦略 / [[赤ずきんの原則]] / [[チェーホフの銃の誤謬]] と並ぶ層 1 の原則
- [[プロンプト設計原則]] 「long session の作業漏れ対策」セクション — メタトリガーで構造的に補完する設計
