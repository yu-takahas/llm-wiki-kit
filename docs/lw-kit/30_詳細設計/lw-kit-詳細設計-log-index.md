---
type: synthesis
tags: [log, index, format, schema, design, llm-wiki-kit]
sources:
  - "[[wiki-skills]]"
  - "[[claude-obsidian]]"
  - "[[karpathy-wiki]]"
  - "[[llmwiki]]"
created: 2026-05-14
updated: 2026-08-22
---

# llm-wiki-kit log の運用

ルート `log.md`（操作履歴）と `index.md`（wiki カタログ）の運用設計。
記入時の具体（フォーマット / type 一覧 / 更新トリガーの表 / 対象パス表記）は `templates/.claude/rules/log-index.md` が正本で、本書は why と却下代替案を持つ。

## 記録の単位

エントリを編集回数でなく成果物の変化で数えるのは、書きすぎると本当に追いたい変更がログに埋もれ、履歴として機能しなくなるため。
`log.md` は後から履歴を追うための記録であり、作業の実況ではない。

issue の内容改訂は `log.md` に記録しない。
改訂の記録は issue 自身の 🪣 経緯が持っており、log 側は要約にすらならない 1 行を残すだけで二重になる。
加えて issue は状態遷移でパスが変わるため（`00_issues/` → `.90_fixed/`）、append-only の log に書いた対象パスは将来解決しなくなる。

当初は「`/lw-update-issue` の起動単位で 1 行にまとめる」という頻度の制限で対処していたが、記録し続ける限り比率は下がらなかった。
実測で全 2956 件中 822 件（28%）が issue 対象、うち 67% が内容の改訂という状態になり、後から履歴を追う用途を阻害していた。

起票（`checkpoint`）と完了・廃棄（`drop`）は残す。
「いつ始めていつ閉じたか」は issue 本体にも `1_issues.md` にも時刻付きでは残らず、log だけが持つため。

規則そのものは `.claude/rules/log-index.md` が持つ。

## 説明カラム

説明カラムに何を書くかを規定するのは、他の正本が持つ内容を写した行が訂正されないまま残るため。
`log.md` は append-only で過去エントリを触らないので、写しは正本が改訂された時点で古くなり、直す機会がない。
詳細の正本（issue の 🪣 経緯 / 設計書 / `git log` / 実物）は別に実在しており、log 側が抱える必要がない。
加えて log の用途は後から履歴を追うことなので、1 行が長いと一覧性が落ちて追う用途そのものを阻害する。

規定を置く必要があることは実測にも出ている。
説明カラムの長さは、全 2777 件時点で全体の中央値が 58 字であるのに対し、末尾 60 件では 304 字だった。

下限側の防御だけがあって上限側の規定が無いのは log に限らず kit 全体の構造で、[[lw-kit-詳細設計-CLAUDE.md]]「出力量の規約」がその分析を持つ。

### 宣言層に留める

同じ非対称を 🪣 経緯で解いた時は、宣言だけでは足りず手順と自己報告のスロットまで実装した（[[lw-kit-スキル設計-lw-update-issue]]「🪣 経緯の上限側の規定」）。
log 側は rule の規定と `CLAUDE.md` のセルフチェック 1 項目、つまり宣言層だけに留めている。

理由は宣言と実行の距離が違うこと。
🪣 の更新は長い session の途中で会話全体から候補を選別する工程を挟むため、宣言が実行から遠い。
`log.md` の追記は `paths` で rule がロードされた直後の Edit 1 回・出力 1 行で、宣言と実行の距離が最短になる。
加えて log には手順層を差し込む器がない。追記が必ず通る skill が存在せず、層を上げるには器から作ることになる。

再判定の条件を実測で持てる。
末尾 60 件を測り直して中央値が下がっていなければ、宣言層では足りないと判断して手順層に降ろす。

却下代替案: 文字数上限を設ける。
🪣 経緯の上限側で同じ案を検討して採らなかった。
削減率がエントリの性質で決まるため、単一の閾値が機能しない。
説明カラムも同じ性質を持つと見ている（説明カラム側で削減率のばらつきは測っていない）。

規則そのものは `.claude/rules/log-index.md` が持つ。

## rule への配置

記入時に参照する具体（フォーマット / type / トリガー）は `.claude/rules/log-index.md` に置き、`CLAUDE.md` には追記の判断基準とセルフチェックだけを残す。

`CLAUDE.md` は常時ロードで全セッションに課金されるのに対し、type 一覧や更新トリガーの表は `log.md` / `index.md` を実際に編集する時にしか要らない。
rule の `paths` でその 5 ファイルに絞れば、無関係なセッションでは読み込まれない。

ターン終了前セルフチェックだけは `CLAUDE.md` に残す。
「追記が必要だと気づく」こと自体が常時ロードに依存しており、rule に移すと `log.md` を開くまで発火しないため。

却下代替案: 全部 `CLAUDE.md` に置く。
実際にこの形で運用していたが、log / index の記述が `CLAUDE.md` 全体の約半分を占め、設計書との重複も生じていた（type 一覧が両者で食い違う状態になっていた）。

## index.md の運用

`index.md` は全 page を列挙する MOC。
記入時の具体（セクション構成 / 列挙形式 / 並び方針 / メタファイルの frontmatter）は `.claude/rules/log-index.md` が持つ。

`30_wiki/` / `40_project/` の page 増減は log.md エントリと対で必ず反映する（漏れると MOC として機能しない）。

issue を `index.md` の対象外にしているのは、issue が状態遷移で置き場所を変える一時的な存在で、wiki page のカタログとは寿命が違うため。

サブ見出しを作らず flat な list に保つのは、検索性（名前で「だいたいこの辺」と探せる）と関連性（隣の page が同じ文脈）のバランスを取るため。
サブ見出しで分類すると、分類自体が page の増加とともに陳腐化して保守負債になる。

ルート `index.md` / `log.md` に wiki page の frontmatter schema を適用しないのは、これらが wiki page ではなくメタファイルだから。

## append-only

`log.md` は append-only な歴史記録として扱う。
過去エントリを書き換えると「その時点で何がどう見えていたか」が失われ、後から履歴を追う用途に耐えなくなる。
移動・rename・削除も新エントリで記録する。

append 前に実際の末尾を確認する手順を rule 側に置いている。
context 内の「自分が直近追加したエントリ」を末尾と仮定して中間位置に挿入する失敗が実際に起きたため（記録はワークスペース側の失敗事例）。

## ターン終了前セルフチェック

long session でバッチ Edit が連続すると、追記そのものを終端で失念しやすい。
変化ベースの規律を [[Self-Refine]] 的なメタトリガー（ユーザー報告直前）で補完し、long session での [[Lost-in-the-Middle]] 対策とする。

チェック項目は `CLAUDE.md` が持つ。
rule でなく `CLAUDE.md` に置く理由は「rule への配置」セクション参照。

## 設計の根拠

- ベース: [[wiki-skills]] の `## [YYYY-MM-DD] <op> | <title>` 形式
- 拡張: 3 カラム化（対象パス追加）+ llm-wiki-kit 独自 type
- 不採用: [[karpathy-wiki]] の JSONL 並走（scaling pain が出るまで markdown のみで十分）
- index.md は [[karpathy-wiki]] 方式の小さな MOC（[[claude-obsidian]] の overview.md は 1 ヶ月停止する実証あり、避ける）

各実装の log 仕様詳細は [[wiki-skills]] / [[claude-obsidian]] / [[karpathy-wiki]] / [[llmwiki]] の各 entity page を参照。

## 関連

- [[LLM-Wiki]] — log.md / index.md の役割
- [[lw-kit-詳細設計-issue]] — checkpoint / drop type が issue 操作と対応
- [[lw-kit-詳細設計-CLAUDE.md]] — CLAUDE.md からの誘導と分担
- [[lw-kit-詳細設計-rules]] — rules の構成（wiki schema 等）
