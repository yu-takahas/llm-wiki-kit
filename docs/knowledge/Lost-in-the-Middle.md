---
type: entity
tags: [LLM, context-window, paper, phenomenon, attention]
sources:
  - https://arxiv.org/abs/2307.03172
  - https://platform.claude.com/docs/ja/build-with-claude/prompt-engineering/claude-prompting-best-practices
  - https://code.claude.com/docs/en/memory
created: 2026-05-17
updated: 2026-08-10
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
`/compact` 実行時はキャッシュクリア → ディスクから再読込 → 新しい位置に再注入される。

会話が長くなると中央に埋もれて遵守率が落ちる、という説明は現行モデルには当てはめない（次のセクション）。

## 現行モデルでの適用範囲

論文は 2023 年時点のモデルの測定で、現行の Claude にそのまま当てはまらない。
Opus 5 は「1M トークンのウィンドウ全体を通して指示の遵守・ツール呼び出し・推論が一貫性を保つ」とされており、会話が伸びるほど指示の遵守が落ちるという形の主張はこれと衝突する。

一方で 1 リクエスト内の配置による効果は現役で、公式のプロンプティング指針が次を挙げている。

- 長いドキュメントや入力を、クエリ・指示・例よりも上に置く
- クエリを末尾に置くと、複数ドキュメント入力で応答品質が最大 30 パーセント向上する

同じ 30% でも軸が違う。
残っているのは 1 リクエスト内での入力データの配置の話で、打ち消されたのは会話が伸びるにつれ指示の遵守が落ちるという話。
サンドイッチ戦略は前者に属するので有効。

CLAUDE.md や SKILL.md のサイズ規律の根拠には使わない。
公式の根拠は量の側にあり（`Longer files consume more context and reduce adherence`）、位置ではない。

## 対策

1 リクエスト内で長い入力を扱う時の配置。

- 長文データはクエリ・指示・例より先に置く
- 重要情報は先頭または末尾に置く（サンドイッチ戦略、[[効果的なプロンプト設計の方法論]] 「3 層整理」セクションの「層 1」）
- 長いドキュメントのタスクでは、答える前に関連部分を引用させる

## 関連

- [[Claude-Codeのメモリ階層]] 「注入メカニズム」セクション — CLAUDE.md の注入位置と再注入の仕組み
- [[効果的なプロンプト設計の方法論]] — サンドイッチ戦略 / [[赤ずきんの原則]] / [[チェーホフの銃の誤謬]] と並ぶ層 1 の原則
