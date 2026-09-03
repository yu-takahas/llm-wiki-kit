---
type: synthesis
tags: [llm-wiki-kit, library, synthesis]
sources:
  - conversation
created: 2026-06-01
updated: 2026-08-31
---

# llm-wiki-kit の library 設計

`20_library/` の蔵書管理設計。
PDF 蔵書の目次 wiki + 目録という構成にした理由を持つ。

**本ページは決定根拠のみを持つ。**
`20_library/` の書き方と手順は `templates/.claude/rules/library.md` が正本で、本ページに写さない。

## 目次 wiki を wiki schema の対象外にした理由

`20_library/` の目次 wiki は `wiki.md` の 5 fields schema に従わせず、書誌情報の独自 frontmatter を使う。
共有できるフィールドがほぼ無いため。
目次 wiki は `type` を持たず（entity / concept / synthesis のどれでもない）、`sources` の代わりに `source` で PDF 実体 1 つを指す。

`wiki.md` に相乗りさせると、リードが宣言している「`30_wiki/` と `40_project/` に共通するスキーマ」から外れた例外記述が増える。
規約の置き場は `paths` 単位で分けるのが rules 設計の基本（[[lw-kit-詳細設計-rules]]「粒度・分割・paths 設計」）。

## PDF を git に入れない理由

[[lw-kit-基本設計-ディレクトリ構成]]「ワークスペース用 `.gitignore` が PDF を除外する理由」が持つ。

## ページ番号の併記を任意にした理由

併記すると PDF ビューアから直接ジャンプできるが、`page_offset` の検証が必要になり 1 冊あたりの取り込みコストが上がる。
参照頻度の低い本まで必須にすると、蔵書を増やす手が止まる。

併記と `page_offset` をセットにしているのは、offset が無いまま併記すると、どの数字が物理ページか判別できなくなるため。

### 検証を両端で行う理由

目次 wiki は章・節ごとにページ番号を持つので、offset が 1 つずれると全エントリが使えなくなる。
片端だけで測ると、前付けの丁合いが途中で変わる本でずれを見逃す。

## 命名規約の根拠

ファイル名の文字種（半角スペースと `_` を使わない）は `wiki.md`「文字種規約」と同じ理由による。
terminal でクォートが必要になることと、prettier の Markdown formatter が単独 `_` を emphasis マーカーとして解釈することを避ける。

`.md` と PDF のファイル名を一致させる規約と、サブタイトルを落として短い通称に揃える規約は、決めた理由が記録に残っていない。
frontmatter `source:` が PDF 名を持つので対応付け自体は一致がなくても解決する（実際に不一致のまま機能している蔵書が 1 冊ある）。
再検討する場合は、一致させることで何が楽になるかを測るところから始める。

## 目録のカテゴリを primary tag に対応させる理由

目録側で独自のカテゴリを切ると、分類が書籍 page と目録の 2 箇所に分かれ、片方だけ変わる。
primary tag を正本にすると、目録は tag の集約結果として導ける。

## 関連

- [[library]] — 蔵書目録
- [[lw-kit-詳細設計-rules]] — rule の設計・運用の起点
- [[lw-kit-基本設計-ディレクトリ構成]] — `books/` を gitignore する理由
- 初回整備の作業ログはワークスペース側の issue に残る（kit には含まれない）
