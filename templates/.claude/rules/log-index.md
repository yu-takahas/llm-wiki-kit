---
paths:
  - "log.md"
  - "index.md"
  - "0_icebox.md"
  - "1_issues.md"
  - "2_done.md"
---

# log-index

`log.md`（操作履歴）の記入規約と、`index.md`（wiki カタログ）・issue インデックス 3 本（`0_icebox.md` / `1_issues.md` / `2_done.md`）の更新トリガー。
記入時の具体（フォーマット / type / トリガー）は本ファイルが正本。

## log.md フォーマット

```text
- [YYYY-MM-DD] <type> | <対象パス> | <説明>
```

3 カラム、リスト項目（`-`）記法。

対象パスの書き方:

- ファイル単体: 具体パス
- ディレクトリ全体: 末尾スラッシュ
- 複数ファイル: brace 記法 `{a, b, c}.md` または代表 1 つ + 説明
- ワークスペース全体: `.`

## type 一覧

標準: `init` / `render` / `query` / `update` / `lint` / `audit`

独自:

| type        | 意味                                           |
| ----------- | ---------------------------------------------- |
| research    | 調査・読解（外部記事・内部リポジトリ精読等）   |
| design      | 設計判断・方針決定                             |
| restructure | 構造変更・移動・統合・rename                   |
| setup       | ディレクトリ作成・初期化系・素材保存           |
| checkpoint  | issue 切り出し・中断点保存                     |
| drop        | issue の廃棄・merge 完了                       |
| delete      | ファイル削除（restructure に伴わない単独削除） |
| refactor    | 既存 page の構造的整理                         |
| fix         | 誤った変更の訂正・復元                         |
| create      | 新規ファイル作成                               |

## 更新トリガー

| 操作                           | log.md エントリ          | インデックス更新                      |
| ------------------------------ | ------------------------ | ------------------------------------- |
| `30_wiki/` に新 page 追加      | `render` または `update` | `index.md` の該当セクションに追加     |
| `30_wiki/` 既存 page の改訂    | `update`                 | 不要                                  |
| `30_wiki/` から page 削除      | `delete`                 | `index.md` の該当セクションから削除   |
| `30_wiki/` page の rename      | `restructure`            | `index.md` の `[[link]]` 更新         |
| `40_project/` に新 page 追加   | `create` または `update` | `index.md` の該当セクションに追加     |
| `40_project/` 既存 page の改訂 | `update`                 | 不要                                  |
| `40_project/` から page 削除   | `delete`                 | `index.md` の該当セクションから削除   |
| `40_project/` page の rename   | `restructure`            | `index.md` の `[[link]]` 更新         |
| `00_issues/` 切り出し          | `checkpoint`             | `1_issues.md` の該当カテゴリに追加    |
| `00_issues/` 廃棄              | `drop`                   | `1_issues.md` から `2_done.md` に移動 |
| `10_raw/` への素材保存         | `setup`                  | 不要                                  |
| 設計判断・方針決定             | `design`                 | 不要                                  |
| 調査・読解                     | `research`               | 不要                                  |
| 健全性チェック / 引用検証      | `lint` / `audit`         | 不要                                  |

issue の内容改訂（💧/🌂/☔ の更新）は `log.md` に書かない。
改訂の記録は issue 自身の 🪣 経緯が持つので二重になり、`log.md` が issue の更新履歴で埋まる。
`log.md` に残すのは起票（`checkpoint`）と完了・廃棄（`drop`）だけで、これは「いつ始めていつ閉じたか」を他のどのファイルも持たないため。

issue は `index.md` の対象外（`index.md` は wiki page のカタログ）。
issue のインデックスは `1_issues.md` / `0_icebox.md` / `2_done.md` が担う。

## index.md の記入

`30_wiki/` と `40_project/` 配下の全 page を type 別カテゴリで列挙する MOC。

セクション構成:

- `## concept` / `## entity` / `## source` / `## synthesis` / `## project`: 各 type の page を `- [[title]] — 一行説明` で列挙
- `## メタ`: `[[log]]` / `00_issues/` / `.claude/rules/` / `0_icebox.md` / `1_issues.md` / `2_done.md`

各 type 内はテーマ別に隣接配置する（サブ見出しを作らず flat な list のまま、同テーマの page が連続することで構造を表現する）。
新規 page は既存の隣接グループに合うか判断し、合わなければ末尾に追加する。

ルート `index.md` / `log.md` はメタファイルで、wiki page の frontmatter schema は適用しない。
`type` を持たず `title` / `tags` / `sources` / `created` / `updated` の 5 fields で運用する。

## append-only

`log.md` は append-only な歴史記録。
過去エントリは触らない。
ファイル移動・rename・削除は新エントリで記録する。
冒頭のヘッダ説明文は対象外で、最新化してよい。

append する前に `tail -1 log.md` で実際の末尾を確認する。
自分が直近追加したエントリを末尾と仮定しない（後続の編集で末尾が変わっていると、中間位置に挿入してしまう）。

## リポジトリ境界

`log.md` に書くのはこのワークスペース内のファイル変更のみ。
add-dir で参照している他リポジトリ内の変更は対象外（そちらのリポジトリが自分の記録を持つ）。
