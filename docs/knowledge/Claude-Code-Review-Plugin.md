---
type: entity
tags: [claude-code, plugin, review, code-review]
sources: []
created: 2026-07-09
updated: 2026-08-13
---

# Claude Code Review Plugin

Claude Code に組み込みの `/code-review` コマンド。Anthropic 公式。
`--comment` で PR にインラインコメント投稿、`--fix` で直接 Edit 反映。

GitHub: [anthropics/claude-code](https://github.com/anthropics/claude-code/blob/main/plugins/code-review/README.md)
Stars: 136,864 / 最終 push: 2026-07-08 / 30 日 commits: 36（非常に活発）

## 実装形態

全実装が `plugins/code-review/commands/code-review.md` という単一の Markdown ファイルに記述されている。
従来のプログラムコードは一切なく、プロンプトエンジニアリングだけで 4 並列エージェントの起動・集約・フィルタリングを実現している。

## アーキテクチャ: 9 ステップパイプライン

```
Step 1: [Haiku]  スキップ判定
Step 2: [Haiku]  CLAUDE.md パス収集
Step 3: [Sonnet] PR サマリー生成
Step 4: [並列 4 エージェント]
         ├── Agent 1 [Sonnet] CLAUDE.md 監査（前半）
         ├── Agent 2 [Sonnet] CLAUDE.md 監査（後半）
         ├── Agent 3 [Opus]   バグ検出（diff のみ）
         └── Agent 4 [Opus]   バグ検出（導入コード分析）
Step 5: [並列検証エージェント] 各 issue を個別検証
         ├── バグ/ロジック → [Opus]
         └── CLAUDE.md 違反 → [Sonnet]
Step 6: フィルタリング（検証不合格を除外）
Step 7: ターミナル出力
Step 8: (--comment 時) コメントリスト内部作成
Step 9: (--comment 時) GitHub インラインコメント投稿
```

3 層モデル使い分け: Haiku（コスト/速度重視の前処理）/ Sonnet（ルール照合）/ Opus（高度な推論が必要なバグ検出・検証）。

上記は `--comment` モード（PR レビュー用の `plugins/code-review/`）の構成。
ターミナルで直接 `/code-review` を叩く場合は effort level で構成が変わる（後述）。

## effort level 別の構成

effort level によって角度数・候補数・検証モード・findings 上限が変わる。
`plugins/code-review/` の README には effort の記述はなく、Claude Code 本体バイナリに実装されている。

| effort | 角度構成                                                             | 候補/角度 | 検証          | Sweep | findings 上限          |
| ------ | -------------------------------------------------------------------- | --------: | ------------- | ----- | ---------------------- |
| low    | サブエージェントなし（1 回の diff 読み）                             |         - | なし          | なし  | min(変更ファイル数, 4) |
| medium | 3 correctness + 3 cleanup + 1 altitude + 1 conventions = **8 角度**  |         6 | 1-vote        | なし  | 8                      |
| high   | 同上 **8 角度**                                                      |         6 | 1-vote recall | なし  | 10                     |
| xhigh  | 5 correctness + 3 cleanup + 1 altitude + 1 conventions = **10 角度** |         8 | 1-vote        | あり  | 15                     |
| max    | 同上 **10 角度**                                                     |         8 | 1-vote        | あり  | 15                     |
| ultra  | クラウド上でワークフロー実行                                         |         - | あり          | -     | -                      |

「3+5 angles」の表記は「3 correctness + 5 non-correctness（3 cleanup + 1 altitude + 1 conventions）」。

### 角度の種類

- **正確性（correctness）**: バグ・ロジックエラー発見（3 つ or 5 つ。5 つの場合は並行性の角度等が追加）
- **整理（cleanup）**: 再利用 / 簡略化 / 効率改善の 3 つ
- **抽象度（altitude）**: 設計レベルの問題（1 つ）
- **規約準拠（conventions）**: CLAUDE.md ルール違反チェック（1 つ）

### effort 間の主な差分

**low → medium**: サブエージェント 0 → 8 角度。検証ステップが追加。low はテストファイル（`test/` / `spec/` / `__tests__/` / `*.test.*` / `fixtures/` / `testdata/`）を対象から外し、medium 以上は含む。
**medium → high**: 角度数は同じだが検証が再現率寄り（recall-biased）に変わる。「推測的」「実行時状態に依存」だけでは棄却しない。怪しいものも残す。上限が 8 → 10。
**high → xhigh/max**: 正確性の角度が 3 → 5、候補数が 6 → 8、掃討フェーズ（新しい finder で漏れ探索）が追加。上限が 10 → 15。
**xhigh と max**: 同一構成。

### diff サイズに基づく動的スケーリング

high / xhigh / max では diff の行数に応じて finder サブエージェント数を動的調整:

```
Math.max(2, Math.min(8, Math.ceil(diffLines / 150)))
```

300 行の diff なら 2 サブエージェント、1200 行なら 8 サブエージェント（上限 8）。

### ワークフローモード

high / xhigh / max ではワークフローが有効な場合、5 フェーズでバックグラウンド実行:
スコープ確定 → 発見 → 検証 → 掃討（xhigh/max のみ）→ 統合（重複マージ・ランク付け・上限適用）。

## フラグ基準: 高確信の問題のみ

プロンプトに「CRITICAL: We only want HIGH SIGNAL issues」と明記されている。

報告すべき:

- コンパイル/パースに失敗するコード（構文エラー、型エラー、import 欠落）
- 入力に依らず確実に誤った結果を生むコード（明白なロジックエラー）
- CLAUDE.md の正確なルールを引用できる明確な違反

報告してはいけない:

- コードスタイルや品質の懸念
- 特定の入力や状態に依存する潜在的問題
- 主観的な提案や改善案
- リンターが検出する問題
- CLAUDE.md でコード内で明示的に抑制されているもの（lint ignore コメント等）

## CLAUDE.md コンプライアンスチェック

Step 2 で Haiku がファイルパスを収集する。変更ファイルの親ディレクトリチェーンに沿って関連する全ての CLAUDE.md を拾う。
Step 4 でファイルパスのスコープに基づいて適用: `src/components/Button.tsx` の変更には `src/components/CLAUDE.md` / `src/CLAUDE.md` / ルートの CLAUDE.md が適用されるが、`tests/CLAUDE.md` は適用されない。

## 信頼度スコアの判定基準

`code-review.md` 自体にはスコアの数値基準は明示されていない。同リポジトリの `pr-review-toolkit` プラグイン内 `code-reviewer.md` に詳細基準がある。

| スコア | 意味                                    |
| ------ | --------------------------------------- |
| 0-25   | おそらく誤検知、または既存の問題        |
| 26-50  | 軽微、CLAUDE.md に明記されていない      |
| 51-75  | 実際の問題だが影響が小さい              |
| 76-90  | 重要で対処が必要、二重確認済み          |
| 91-100 | 致命的バグまたは明示的な CLAUDE.md 違反 |

閾値は 80 以上。Code Review Plugin では数値スコアの代わりに多段階検証プロセス（Step 4 報告 → Step 5 検証 → Step 6 除外）で同等の品質保証を実現している。

## スキップ条件（Step 1）

Haiku が以下の 4 条件をチェックし、いずれか 1 つでも真なら即座に停止する:

- PR がクローズ済み
- PR がドラフト
- レビュー不要な PR（自動化された PR、明らかに正しい些末な変更）
- Claude が既にコメント済み

例外: Claude 自身が作成した PR はレビュー対象に含まれる。

## 出力

- デフォルト: ターミナルに指摘リスト or 「問題なし」
- `--comment`: MCP ツールで PR にインラインコメント投稿。小さな修正は提案ブロック付き、大きな修正（6 行以上・構造的変更）はテキスト記述のみ
- `--fix`: 指摘を出した後に直接 Edit 反映して完了

指摘の JSON 形式:

```json
[{"file": "path/to/file.ext", "line": 123, "summary": "...", "failure_scenario": "..."}]
```

## 知見の蓄積

CLAUDE.md の進化がレビュー精度を上げる循環を想定しているが、CLAUDE.md への書き戻しは自動ではなくチームの手動更新が前提。

## Skill ツールからの起動

`disable-model-invocation: true` が付いているが、Skill ツールから起動できる。
fork 実行（別コンテキスト）になり、最終応答テキストが呼び出し元の context に返る。

- 引数は `Review target:` として丸ごと渡る。自然言語で書けるので、別リポジトリの特定 commit も対象にできる
- fork 先の作業ディレクトリは呼び出し元を引き継ぐ
- 対象に diff が無ければ「レビュー対象なし」と 1 行で返って終わる

この性質により、結果を保存したり後処理を足したりするラッパー skill が成立する。

## 指摘の返り方

`ReportFindings` は fork された agent に渡らないため、指摘は inline のテキストで返る。
渡らない理由は effort で異なる。

| effort | `ReportFindings`   | 出力形式                                       | 重要度                         |
| ------ | ------------------ | ---------------------------------------------- | ------------------------------ |
| low    | 使用を明示的に禁止 | `path:line — 何が壊れるか` の 1 行 × 最大 4 件 | フィールドとして存在しない     |
| medium | ツール自体が不在   | 散文                                           | 3 段を自主的に付けることがある |

自主的に付く重要度はプロンプトが要求したものではないので、安定して供給されるとは限らない。
起動時の引数で段階と判定基準を指定すれば、そのとおりに返る。
見出しや項目構成といった出力フォーマットも同じ方法で指定でき、実際にレビューした対象範囲を冒頭に書かせることもできる。

## llm-wiki での利用

`/lw-code-review` が本 skill を Skill ツールから起動し、返ってきた指摘を `/tmp/lw-review/<issue-name>/` に保存する。
起動時の引数で重要度 4 段（必須 / 推奨 / 任意 / 確認）と出力フォーマットを指定し、`/lw-fix-review` のルーティング入力にそのまま渡す。
