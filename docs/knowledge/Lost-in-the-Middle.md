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

論文は 2023 年時点のモデル（GPT-3.5 等）を対象に、複数ドキュメント QA と key-value 検索で測定した。
答えの位置を動かすと U 字型の性能曲線を示し、中央に置いた場合は先頭・末尾に置いた場合より最大で 30% 程度劣化した。
1 リクエストの入力の中で情報をどこに置くかが正解率に効く、というのが測定の内容。

## 測定されたものと外挿されたもの

この論文を根拠にした主張は 2 つに分かれる。
片方は現在も有効で、もう片方は現行モデルに当てはめない。

測定されたもの（1 リクエスト内の入力配置）は現在も有効。
公式のプロンプティング指針も同じ軸に立っており、長い入力ではクエリを末尾に置くと複数ドキュメント入力で応答品質が最大 30% 向上する、としている。
論文の 30% 劣化と公式の 30% 向上は同じ軸の裏表で、具体的な配置の指針は「対策」セクションが持つ。

外挿されたもの（会話が伸びるにつれ指示の遵守が落ちる）は論文が測っていない。
1 リクエスト内の位置効果を、会話の長さによる劣化に読み替えた応用。
Anthropic は Opus 5 について、1M トークンのコンテキストウィンドウをデフォルトかつ最大値として持ち、指示の遵守・ツール呼び出し・推論はウィンドウ全体を通して一貫性を保つ、と説明している。
この外挿はその説明と衝突する。

CLAUDE.md や SKILL.md のサイズ規律の根拠にも使わない。
公式の根拠は量の側にあり（`Longer files consume more context and reduce adherence`）、位置ではない。

## 構造的な利用

context 先頭は「最も参照されやすい位置」なので、各社のチャット AI は最上位の隠しプロンプト（Anthropic の core system prompt、OpenAI の Root / System 層）をここに配置している。
これは訓練による命令階層学習（[The Instruction Hierarchy](https://arxiv.org/abs/2404.13208), ICLR 2025）に加えて、Lost in the Middle に対する **構造的な対策** でもある。

## CLAUDE.md と Lost in the Middle

[[Claude-Codeのメモリ階層]] 「注入メカニズム」セクションで扱う通り、CLAUDE.md は session 最初に `<system-reminder>` でユーザーメッセージ列の先頭近くに注入される。

会話が長くなると中央に埋もれて遵守率が落ちる、という説明は現行モデルには当てはめない（「測定されたものと外挿されたもの」セクション）。

## 対策

1 リクエスト内で長い入力を扱う時の配置。

- 長文データはクエリ・指示・例より先に置く
- 重要情報は先頭または末尾に置く（サンドイッチ戦略、[[効果的なプロンプト設計の方法論]] 「3 層整理」セクションの「層 1」）
- 長いドキュメントのタスクでは、答える前に関連部分を引用させる

## 関連

- [[Claude-Codeのメモリ階層]] 「注入メカニズム」セクション — CLAUDE.md の注入位置と再注入の仕組み
- [[効果的なプロンプト設計の方法論]] — サンドイッチ戦略 / [[赤ずきんの原則]] / [[チェーホフの銃の誤謬]] と並ぶ層 1 の原則
