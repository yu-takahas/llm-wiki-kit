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

説明カラムの書き方は次節。

## 説明カラム

説明は正本を指すだけにする。
他のファイルが持つ内容を写さない。

残すのは 3 つ。

- 何をしたか
- なぜしたか — 1 句まで。発端や経緯の叙述は issue が正本
- どこに登録したか — インデックス名と位置まで。新設の経緯やカテゴリの説明は書かない（インデックスを更新した回だけ現れる）

列挙は入口で、判別は次の 1 文が受ける。
その事実を知る手段が再実行・再測定しかないなら残す。
他の正本から復元できるなら参照に落とす。

詳細は別の正本が持つ。
判断の経緯は issue、規約と理由は設計書、変更の中身は `git log` と実物。

参照の書き方:

- issue はパスでなく `[[link]]` で指す（FIXED / FADED になると `00_issues/.90_fixed/` 等へ移り、append-only の `log.md` に書いたパスは解決しなくなる）
- 開いている issue はファイル単位まで。セクション名や 🪣 経緯のエントリ日付は指さない（相手も改訂される）
- 揮発する先（`/tmp/` 配下等）は参照でなく結論そのものを 1-2 行書く
- 参照に落としたら、その場で実在を確認する（`[[link]]` は `find`、セクション名は `grep`）

`log.md` は append-only で過去エントリを触らないため、写した内容は訂正の機会がないまま正本より先に古くなる。

```text
写している: E2E を別テーブルに分ける issue を起票した。テスト設計が規定するテーブル初期化に実装が無く、E2E が用意したデータが開発アプリに残り続けることが分かったのが発端。見積もりの根拠になる実測 3 件と、着手前に決める点（初期化を「各テスト前」から「実行ごとに 1 回」に書き換えるか）は…、`1_issues.md` の tweetodo WIP に「3. テスト基盤」を新設して登録
指している: E2E を別テーブルに分ける issue を [[tweetodo-isolate-e2e-table]] に起票した。発端は E2E のデータが開発アプリに残ること。実測と着手前に決める点は issue が持つ。`1_issues.md` の tweetodo WIP「テスト基盤」に登録
```

issue の 🪣 経緯にも同じ主張がある（`.claude/rules/issue.md`「二重記帳をやめる」）。

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
