---
name: lw-research-doc
description: Researches a URL or keywords and generates a markdown document. Use when fetching a webpage or searching a topic to document it.
disable-model-invocation: true
allowed-tools: WebFetch, WebSearch, Write, Read
argument-hint: "<URL or キーワード>"
---

# lw-research-doc - Web調査ドキュメント生成スキル

対象: `$ARGUMENTS`

## 入力判定

- `http` で始まる → **URLモード**: WebFetch で直接取得
- それ以外 → **キーワードモード**: WebSearch → 上位3〜5件を WebFetch

キーワードモードでは信頼性の高いソース（公式ドキュメント・学術論文・技術ブログ）を優先する。

## 実行フロー

1. **入力判定**: `$ARGUMENTS` が `http` で始まるか判断
2. **情報取得**: URLモードは WebFetch、キーワードモードは WebSearch → WebFetch
3. **ドキュメント生成**: 内容を整理してマークダウンを作成
4. **保存**: Write で指定先に保存

## 保存ルール

**保存先**:

- デフォルト: `10_raw/`
- 会話中に別の保存先が指定されていればそちらに従う

**ファイル名**: `YYYYMMDD_<タイトル>.md`（日付は今日、タイトルは内容から自動生成）

**frontmatter**:

```yaml
---
type: source
tags: [内容に応じたタグ]
sources:
  - <使用した URL またはキーワード>
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

## ドキュメント構成

1. 概要（3〜5行の要約）
2. 本文（内容を整理してセクション分け）
3. 参考（情報源URLのリスト。WebFetch で実際に開いたページだけを情報源にする。検索結果スニペットから本文を書かない）

## エラーハンドリング

- **`$ARGUMENTS` 未指定**: URL またはキーワードの入力を案内して停止
- **URL が読み込めない**: その旨を伝え、キーワード検索への切り替えを提案
- **検索結果がない**: その旨を伝え、別キーワードを提案
- **保存先ディレクトリが不在**: Write ツールが自動作成するため問題なし

## 使用例

```
/lw-research-doc https://platform.openai.com/docs/guides/embeddings
/lw-research-doc tiktoken tokenizer 選び方
/lw-research-doc RAG 評価指標
```
