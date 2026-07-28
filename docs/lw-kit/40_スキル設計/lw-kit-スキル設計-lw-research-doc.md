---
type: synthesis
tags: [llm-wiki-kit, lw-research-doc, skill-design, Web調査, synthesis]
sources:
  - conversation
created: 2026-03-23
updated: 2026-07-25
---

# llm-wiki-kit の lw-research-doc skill 設計

Web上の情報を調査してマークダウンドキュメントを生成する `/lw-research-doc` スキルの設計。

## データフロー

```mermaid
graph LR
    web[("Web")] -->|"調査"| skill(["/lw-research-doc"])
    skill -->|"保存"| raw[("10_raw/&lt;file&gt;.md")]
```

## skill 名

`/lw-research-doc` 採用。
`lw-` prefix + `research-doc` で Web 調査によるドキュメント生成であることが名前で分かる。

## skill 配置

全 skill は project-local(`.claude/skills/` 配下)。
保存先(`10_raw/`)のディレクトリ構造や frontmatter スキーマが llm-wiki-kit 固有の規約に依存するため global 化しない。

## 呼び出し制御

`disable-model-invocation: true`。
Web 調査は lead が意図的に起動する操作。
外部 API(WebFetch / WebSearch)を呼ぶため自動起動は不適切。

## 許可ツール

WebFetch / WebSearch / Write / Read の 4 つ。
Bash は不要(ファイル操作は Write / Read で完結)。
具体的な用途は SKILL.md を参照。

## 要件

**概要**: URL またはキーワードを受け取り、Web上の情報を調査してマークダウンファイルを生成する。

**ユーザー要件**:

1. URL入力: WebFetch で直接読み込んでまとめる
2. キーワード入力: WebSearch で検索 → 上位ページを WebFetch → まとめる
3. 入力判定: ユーザーが意識しなくていい（`http` で始まるかどうかで自動判断）
4. frontmatter 自動付与: プロジェクト標準テンプレートを付与
5. デフォルト保存先: `10_raw/`

## 設計決定

入力判定をユーザーに意識させない方針(`http` で始まるかどうかで自動判断)。
キーワード検索では信頼性の高いソース(公式ドキュメント・学術論文)を優先する。
具体的な処理フロー・保存先・ファイル名規則・frontmatter テンプレート・エラーケースは SKILL.md を参照。

## 保守規律

- 本設計書と SKILL.md の同期: SKILL.md を変更したら本設計書の `updated:` も揃える
- frontmatter スキーマ変更時の追従: `10_raw/` の frontmatter 規約が変わったら SKILL.md の出力テンプレートを追従

## 関連

- [[lw-kit-スキル設計-lw-render]] — research-doc の出力(`10_raw/`)を wiki に変換する後続 skill
- [[lw-kit-アーキテクチャ設計]] — skill 群全体での位置づけ(ナレッジ蓄積ワークフロー)
