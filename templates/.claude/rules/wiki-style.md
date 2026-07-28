---
paths:
  - "30_wiki/**/*.md"
---

# wiki-style

`30_wiki/` 配下 wiki page のスタイル規約。
schema 規約は `wiki.md` 参照。

この file は 2 層からなる。(a) page 執筆時に常時守る規約（太字禁止 / 英単語 / issue 参照禁止 / Edit 規律）と、(b) page を整理し直す時だけ見る「リファクタ観点」。(b) を通常編集時に過剰適用しない。

## issue 参照禁止

wiki page に `00_issues/` のファイル名 / Phase 番号 / 「未生成」「次に作る」等の状態言及を書かない。
issue はあとで消えるので、wiki page は issue がなくなっても自立して読めるべき。
issue という概念そのものを説明する page への wiki link は OK（概念自体は永続的）。

## リスト項目に太字を入れない

リスト項目を `**太字**` で強調しない、フラット表記で書く。
重要度は順序・章立て・チェック状態で表現する。
表のセル内も同様に太字で強調しない（「リファクタ観点」の表の中身参照）。

## 中途半端な英単語混じりを避ける

日本語化できる英単語は日本語にする。

- 日本語化: 日常語に対応する単語（user / takeaway / emphasis / draft / threshold / fan-out / impact surface / Pre-condition 等）
- 残す: 技術用語（embedding / hook / SKILL.md / frontmatter 等）、固有名詞、原文 quote、llm-wiki 内 type 名（synthesis / raw / wiki / source 等）
- 初出のみ併記: 馴染み薄い概念は「原文（日本語訳）」、例「resist-table（言い訳対戦表）」

## リファクタ観点

`30_wiki/` の page を整理し直す時に見る観点。

構造の一貫性:

- リスト / 段落を同一セクション内で交互に切り替えない
- セクション順は高レベル（採用判断 / 概要）→ 詳細（設定根拠 / 落とし穴 / 関連）
- 見出しは H2 / H3 で構造化、H4 以下は必要最小限

冗長削減:

- 同じ情報を 2 箇所以上に書かない（表と段落で重複させない）
- ファイル名参照で済むものを本文に展開しない

表の中身:

- セル内の太字強調は構造化で代替（カラムを分ける / 別行にする / セクション化）
- カラム順は 識別子 → 内容 → 補足

リンク・参照の整合性:

- `[[link]]` 先 page が存在するか（broken link がないか）
- frontmatter `sources` と「関連」リンクが最新の参照を反映しているか

## Edit する時の規律

日本語文書を Edit する時、`old_string` を context 記憶からスクラッチで書かない（半角／全角の括弧やハイフンが滑る）。
直前に Read してその出力をそのまま `old_string` にコピペする。
Edit が `String to replace not found` で失敗したら、同型の `old_string` でリトライせず、まず Read で実物を再取得して typo を特定する。
`old_string` は unique が確保できる最小範囲だけ切る（長くすると typo 余地が増える）。

根拠は `$KIT/docs/knowledge/プロンプト設計原則.md`「Edit の差分ミスマッチ対策」セクション。
