---
type: source
tags: [prompt-engineering, LLM, system-prompt, ChatGPT, Claude, Gemini, instruction-hierarchy, context-engineering]
sources:
  - https://arxiv.org/abs/2404.13208
  - https://arxiv.org/html/2507.13334v1
  - https://model-spec.openai.com/2025-12-18.html
  - https://www.anthropic.com/constitution
created: 2026-07-06
updated: 2026-07-06
---

# Chat AI のプロンプト階層と用語体系

ChatGPT / Claude / Gemini の 3 大 Web 版 Chat AI が内部に持つプロンプト階層（不可視ベース層 → プラットフォーム設定 → ユーザー設定 → 会話）を横断比較し、各社でバラバラな用語を学術・業界標準に対応付ける。
完全な統一標準はまだないが、レイヤーごとに「最も普及している用語」は存在する。

## 階層構造の全体像

すべてのサービスに共通する 4 層構造:

| 層      | 名称                 | 説明                                                                             |
| ------- | -------------------- | -------------------------------------------------------------------------------- |
| Layer 0 | 不可視ベース層       | ユーザーに見えない最上位制約。現在日付・自己識別・安全制限・ツール利用条件を注入 |
| Layer 1 | プラットフォーム設定 | 各社が定義するサービスレベルの指示                                               |
| Layer 2 | ユーザー設定         | Custom Instructions / Projects / Memory 等、ユーザーが永続的に設定               |
| Layer 3 | 会話                 | Human turn 本文（都度入力）                                                      |

Layer 0 は OpenAI Model Spec では System level、Anthropic では Anthropic's instructions と呼ばれる。
「メタシステムプロンプト」は業界標準用語ではなくコミュニティ発の通称。

## 各サービスの層構成

### ChatGPT（OpenAI）

ベースシステムプロンプト（不可視、GPT-5 でも確認済み）/ カスタム指示（2 フィールド各 1,500 文字）/ メモリー（自動抽出 + 暗黙記憶の 2 層）/ プロジェクト（専用指示・ファイル・メモリー空間）/ MyGPT（完全なシステムプロンプト制御 + ツール設定）/ ユーザープロンプト。

Simon Willison の GPT-5 調査（2025-08）で、ユーザー指定とは別に OpenAI が注入する隠れシステムプロンプト（`oververbosity: 3` / `Juice: 64` 等の内部パラメータ含む）の存在を実験で確認。

### Claude（Anthropic）

Anthropic ベース仕様（訓練 + 固定プロンプト、最高優先度）/ claude.ai システムプロンプト（公式リリースノートで公開、透明性では最も積極的）/ プロジェクト（専用指示・知識・ファイル）/ メモリー（自動保存）/ ユーザープロンプト。

### Gemini（Google）

ベースシステムプロンプト（不可視）/ カスタム指示（全会話に適用）/ カスタム Gem（保存されたシステムプロンプト + 専用 UI、ファイル添付可）/ ユーザープロンプト。

## 用語の対応表

| 概念                 | ChatGPT             | Claude                  | Gemini              | 学術/標準用語                                      |
| -------------------- | ------------------- | ----------------------- | ------------------- | -------------------------------------------------- |
| 不可視最上位制約     | Base system prompt  | Anthropic 仕様          | Base system prompt  | Privileged instruction / `c_instr`（Layer 0）      |
| プラットフォーム設定 | --                  | claude.ai system prompt | --                  | System message                                     |
| ユーザー永続設定     | Custom Instructions | --                      | Custom Instructions | Persistent instruction / `c_instr`（user-defined） |
| 自動記憶             | Memory              | Memory                  | --                  | Persistent memory / `c_mem`                        |
| 専用 AI 設定         | MyGPT / Projects    | Projects                | Gems                | Operator-level instruction                         |
| ユーザー入力         | User prompt         | Human turn              | User prompt         | User message / `c_query`                           |

## API レベルの標準: ChatML

ChatML（Chat Markup Language）が事実上の標準。
OpenAI が策定し HuggingFace が採用・普及させた `system` / `user` / `assistant` の 3 ロール体系。
Anthropic / Google もこのロール体系に準拠しており、API 呼び出しレベルではこれが共通語。

## 理論的フレームワーク

### Instruction-Hierarchy（OpenAI, ICLR 2025）

プロンプトインジェクションの根本原因を「現行 LLM に命令階層がないこと」と特定し、階層的な命令優先度を訓練で学習させる研究。
優先度は 4 段階: Priority 0（system）→ 10（user）→ 20（画像/音声内）→ 30（ツール出力）。

2026 年 3 月に IH-Challenge（arxiv:2603.10521）を公開。
命令階層の強化とプロンプトインジェクション耐性を高める訓練データセット。
推論モデルでの階層破壊パターンも研究中（arxiv:2606.07808）。

### Principal Hierarchy（Anthropic）

3 層の信頼構造: Anthropic（訓練 + Model Spec、最高優先度）→ Operator（API 利用企業 / claude.ai 自身、System prompt で制御）→ User（エンドユーザー、Human turn）。
Operator は User に Operator 以上の権限を付与できない。Anthropic の制約は Operator でも上書き不可。

2026-01-22 に 80 ページの Claude's Constitution を公開。
「厳格な階層ではない」と明記され、ユーザーに認められる権利のうち Operator が上書きできないものがあると定義。

### OpenAI 5 層権限モデル（Model Spec 2025-12-18）

Root（誰も上書き不可）→ System（OpenAI が設定）→ Developer（API の operator 相当）→ User（エンドユーザー）→ Guideline（デフォルト、暗黙的に上書き可能）。

### Context Engineering（arxiv:2507.13334, 2025-07）

「プロンプトエンジニアリング」の上位概念として提唱。
LLM が見る環境全体を 6 要素で形式化:

| 記号      | 対応する概念                 | Web 版 Chat AI での例                     |
| --------- | ---------------------------- | ----------------------------------------- |
| `c_instr` | システム指示・ルール         | system prompt / Custom Instructions / Gem |
| `c_know`  | 外部知識（RAG 等）           | プロジェクトのファイル添付                |
| `c_tools` | 使用可能なツール定義         | Web 検索・コード実行ツール                |
| `c_mem`   | 過去のやり取りからの永続情報 | Memory                                    |
| `c_state` | ユーザー・世界の動的状態     | 現在日付の注入                            |
| `c_query` | ユーザーの即時リクエスト     | ユーザープロンプト                        |

2026 年時点で重心は「最適なプロンプトの詰め方」からエージェントシステムのランタイム状態管理（メモリ / ツール / 長期実行）へ移行。

## 用語選択の指針

- API・実装レベルで話すなら → `system` / `user` / `assistant`（ChatML）が最も通じる
- 権限・信頼の話なら → Instruction-Hierarchy（OpenAI 論文）または Principal Hierarchy（Anthropic）の用語
- 機能・役割の話なら → Context Engineering の `c_instr` / `c_mem` / `c_query` が最も体系的
- 「ユーザーに見えない層」を指すなら → Privileged instruction または base/hidden system prompt

## Leaked System Prompts

ユーザーに非公開のシステムプロンプトを収集した主要リポジトリ:

- jujumilk3/leaked-system-prompts（GitHub、スター 14.2k）: ChatGPT / Claude / Gemini 等
- elder-plinius/CL4R1T4S（GitHub）: ChatGPT / Gemini / Grok / Claude / Perplexity / Cursor 等

Anthropic は claude.ai のシステムプロンプトを公式リリースノートで公開しており、leaked に頼らず確認可能。

## 関連

- [[効果的なプロンプト設計の方法論]] — プロンプト設計の 3 層整理（本ページはその「階層構造」を深掘り）
- Instruction-Hierarchy — OpenAI の命令優先度階層論文
- Anthropic — Principal Hierarchy の策定元
