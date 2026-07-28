---
paths:
  - "40_project/**/*.md"
---

# project

`40_project/<案件>/` 配下の案件固有 wiki page の規約。
schema は `wiki.md` と共通、本ファイルは案件固有の命名と置き場判断に絞る。

## サブディレクトリ運用

- `40_project/<案件>/` 単位で案件を切る、wiki page (`.md`) はフラット配置を原則とする
- 日付プレフィックス禁止（`YYYYMMDD_` は raw のみ、wiki page はタイトルそのまま）

### 更にディレクトリを切る場合

page が増えてフラットでは所在が追えなくなったら、1 段だけ切る。

- まとまり別（`40_project/study/fp3/` / `40_project/blog/articles/`）
- 工程別（`10_要件定義/` / `20_基本設計/`、番号は 10 刻み）

切ったらファイル名の prefix に段名を足す（`<案件名>-<段名>-<派生 title>.md`）。
`[[link]]` はファイル名で解決するので、段が違っても衝突させない。

### 非 wiki リソース（assets / codes 等）

PDF / 画像 / 実装コード等の非 wiki page リソースは `<案件>/<purpose>/` サブディレクトリに配置可。

- `assets/` — PDF / 画像 / その他資料（例: `40_project/my-project/assets/`）
- `codes/` — 実装コード（例: `40_project/my-project/codes/`）

`assets/` 配下はフラット配置を推奨。
カテゴリ別保持が必要な場合のみ `assets/<category>/` の 2 段サブディレクトリ許容（事例: `40_project/my-project/assets/契約書類/` + `assets/申請資料/`、PDF ファイル名からカテゴリ判別困難なため）。

## case root と派生 page

案件固有 wiki は 1 つの case root（案件全体の俯瞰）と、複数の派生 page（個別トピックの深掘り）で構成する。

case root page（案件全体の俯瞰）：

- type=project、title はサブディレクトリ名と同名（例：`40_project/acme-corp/acme-corp.md` → `[[acme-corp]]`）
- 1 案件 1 case root、ロードマップ・現状・方針を集約
- Obsidian の wiki link 解決と相性が良い（短く書ける）

派生 page：

- case root から派生する個別 page（個別 phase のアーキ設計、DNS 切替 synthesis 等）
- title は `<案件名>-<派生 title>` 形式（例：`acme-corp-アーキテクチャ設計-phase1.md` / `acme-corp-DNS切替依頼設計.md` / `acme-corp-フォーム実装レビュー.md`）
- prefix を `<案件名>-` で揃える理由: 案件横断で title 衝突を回避（`Phase 1` のような汎用語が別案件で同じ title になりうる、Obsidian wiki link はファイル名ベースで複数マッチ時の挙動が不定）
- 案件固有 entity（`OldCMS.md` / `example.com.md` 等の固有名詞）は対象外（prefix なし、自然な名前のまま）
- 文字種規約（半角 space 禁止 / `_` 禁止 / 英境界 `-` / 日本語境界連結）は `wiki.md`「ファイル名」「文字種規約」セクションを参照

## 案件固有での type の典型例

判定の境界は `wiki.md`「type 一覧」セクションを参照。
ここでは案件文脈で各 type がどう現れるかの典型例だけ示す：

- project：案件本体ページ（case root）
- entity：案件固有の固有名詞（客先会社 / 案件固有ドメイン / 案件固有組織・人物）
- concept：案件特有の概念（汎用化されることが多く稀）
- source：案件 raw を要約した page
- synthesis：案件内の複数 source / entity を統合した page（例：DNS 切替 vs apex リダイレクト比較）

## 関連 entity の置き場判断

`40_project/<案件>/` から張る `[[link]]` 先の置き場は per-entity で判断：

- 他案件 / llm-wiki 横断で使い回せそう → 汎用（`30_wiki/`）
- 案件文脈にしか出ない → 案件固有（`40_project/<案件>/`）

判断順:

1. まず「他案件で使う見込みがあるか?」を per-entity で問う
   - 汎用プロダクト / SaaS / ライブラリ（`Resend` / `Vercel` / `zod` 等）→ 他案件でも使う見込みあり → 汎用
   - 案件固有の旧 CMS / 旧ドメイン / 客先固有プロダクト（`OldCMS` / `example.com` 等）→ 他案件で使わない → 案件固有
2. 判断つかなければ汎用側に倒す（後で案件固有に下ろすより、最初から汎用にしておく方が後で拾いやすい）。

この置き場判断は entity に限らず concept など派生 page 全般に効く。
横断利用される汎用概念は `30_wiki/`、llm-wiki 自身の設計概念（`issue` / `render` 等）は meta-project として `40_project/llm-wiki/` に置く。
prefix の付かない汎用語 concept でも判断軸は同じ（汎用横断か llm-wiki 自身か）。

## render 方向

raw が素材、`/lw-render` で wiki 化：

```text
10_raw/<案件>/<file>.md
  └─→ /lw-render（議論ステップで出力先を判断）
        ├─→ 30_wiki/<title>.md              （汎用知識のとき）
        └─→ 40_project/<案件>/<title>.md   （案件固有のとき）
```

詳細は llm-wiki-kit リポジトリの設計書（`docs/lw-kit/30_詳細設計/lw-kit-詳細設計-rules.md` / `docs/lw-kit/40_スキル設計/lw-kit-スキル設計-lw-render.md`）を参照。
