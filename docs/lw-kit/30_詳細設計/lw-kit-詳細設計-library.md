---
type: synthesis
tags: [llm-wiki-kit, library, synthesis]
sources:
  - conversation
created: 2026-06-01
updated: 2026-07-28
---

# llm-wiki-kit の library 設計

`20_library/` の蔵書管理設計。
PDF 蔵書の目次 wiki + 目録の構造と運用。

## ディレクトリ構成

```
20_library/
  library.md          目録（全蔵書の一覧、primary tag でカテゴリ分類）
  <タイトル>.md        各書籍の目次 wiki
  books/               PDF 置き場（gitignore、リポジトリに入れない）
    <タイトル>.pdf
```

`.md` ファイル名と `books/` 内の PDF ファイル名は拡張子を除いて一致させる。

## 目次 wiki のスキーマ

### frontmatter

```yaml
---
authors: [著者1, 著者2]
translators: [訳者1]
supervisor: 監修者
publisher: 出版社
pages: ページ数
source: ファイル名.pdf
format: 自炊 | 電子書籍
page_offset: 数値
tags: [primaryタグ, タグ2, タグ3]
---
```

- `authors`: 配列（1 人でも配列）
- `translators`: 翻訳書のみ。日本語オリジナルは省略
- `supervisor`: 監修者がいる場合のみ
- `source`: `20_library/books/` 配下の PDF ファイル名（パスは不要）
- `format`: `自炊`（スキャナ + OCR で自作した PDF）または `電子書籍`
- `page_offset`: 自炊 PDF の物理ページと本文ページのずれ。`PDF物理ページ = 本文ページ + offset`。head（序盤の本文ページ番号）と tail（末尾の奥付・裏表紙）の両方で検証する
- `tags`: 先頭が primary tag（目録のカテゴリ分類に使う）

フィールド順: authors → translators → supervisor → publisher → pages → source → format → page_offset → tags

### 本文

- `# <書籍タイトル>`
- 概要 1-2 行（各章の内容が分かる粒度で）
- ページ番号の読み方ノート: `page_offset` の検証結果を明記
- 章立て: `## 第N章 タイトル（p.本文/PDF）` 等
- 節リスト: `- セクション名 ... p.本文/PDF`
- ページ番号は `p.本文ページ/PDF物理ページ` の併記（PDF ビューアで直接ジャンプできるようにする）
- サブセクションはインデントで階層化

本文に「著者 / 出版社」行や `PDF:` 行は書かない（frontmatter で完結）。

## 命名規約

- `.md` ファイル名と PDF ファイル名は一致させる（拡張子のみ異なる）
- 半角スペース禁止、`-` で置換
- `_00` 等のサフィックスやサブタイトルは除去し、短い通称に揃える

## tags 体系

先頭が primary tag、残りは副次タグ。2-4 個。
primary tag は `library.md` のカテゴリ分類に使う。
具体的な tag 一覧は各書籍の frontmatter と `library.md` のカテゴリ見出しを参照。

## PDF の扱い

- `20_library/books/` は `.gitignore` に追加済み（PDF はリポジトリに入れない）
- OCR を通した自炊 PDF は透明テキストレイヤーが埋まっている
- Claude の Read ツールは画像レイヤーを見るため context を大量消費する
- `pypdf` でテキスト抽出してテキストとして渡す方が圧倒的に軽い
- 目録の凡例で `📖 = 電子書籍 / 📄 = 自炊` と区別

## 書籍追加の手順

1. PDF を `20_library/books/<タイトル>.pdf` に配置
2. Read ツールで PDF の目次ページを読み取り（画像として表示される）
3. `page_offset` を検証: head（序盤の本文ページ番号が見えるページ）と tail（末尾数ページ）の両方を読んで `PDF物理ページ - 本文ページ` を確認
4. `20_library/<タイトル>.md` に目次 wiki を作成（frontmatter + `page_offset` + 章・節リスト with `p.本文/PDF` 併記）
5. [[library]] の該当カテゴリに 1 行追記

## 関連

- [[library]] — 蔵書目録
- 初回整備の作業ログはワークスペース側の issue に残る（kit には含まれない）
