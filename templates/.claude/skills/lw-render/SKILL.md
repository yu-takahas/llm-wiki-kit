---
name: lw-render
description: Renders a raw source (`10_raw/<file>.md`) into the llm-wiki (`30_wiki/` 汎用 or `40_project/<案件>/` 案件固有). Triggers when the lead adds a new raw source and needs it propagated as 5-10 wiki pages across entity / concept / synthesis categories.
argument-hint: "<raw-file-path>"
allowed-tools: [Read, Write, Edit, Glob, Grep, "Bash(wc:*)"]
disable-model-invocation: true
---

# render

raw（`10_raw/<file>.md`）を llm-wiki（`30_wiki/` 汎用 / `40_project/<案件>/` 案件固有）に render する skill。

入力: `$ARGUMENTS` で `10_raw/<file>.md` のパスを 1 つ受け取る。
パス未指定なら次の文言で停止: `raw ファイルのパスを指定してください。例: /lw-render 10_raw/20260516_xxx.md`

## Process 概観

```text
事前 → 1. raw 完読 → 2. wiki / project index 読込
     → [3. 議論ステップ ← lead approval gate（4 判断項目: 出力先 / type / title / 関連 entity 置き場）]
     → 4. 議論で決まった type で page 作成 → 5. entity / concept / synthesis 生成 or update → 6. 矛盾保持
     → 7. backlink 走査 → 8. 影響範囲報告 → 9. lead 自走運用ガイド（log/index + case root の「関連 raw」セクション）
```

書く（4-6）／検査する（7-8）／引き継ぐ（9）の 3 フェーズ。
3 は書く前の最後の関門、7-8 は事後検査。

## 言い訳対戦表（起動前チェック）

raw を見たときに浮かびがちな skip 理由と、それに対する判断:

| 言い訳                                        | 現実                                                                                                        |
| --------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| この raw は issue で十分、render しなくていい | issue は中断点メモ、永続知識は wiki / project に上げる                                                      |
| この raw は本文長下限を満たさない             | 1500 byte 未満なら render 拒否は正しい挙動。lead に確認して raw 加筆を待つ                                  |
| あとで一括 render する                        | 一括 render 機能は別 skill。今ここで `/lw-render` が走っているなら今やる                                    |
| raw を言い換えれば source page になる         | 言い換えは wiki の価値を損なう。自分の synthesis を書く                                                     |
| 目次・章タイトル・記憶で内容は分かる          | 蔵書・外部ソースを引用する時は一次ソース（`20_library/books/` の PDF 本文等）の該当箇所を Read してから書く |
| source page を書けば render 完了              | source page は出典追跡の器。既存 wiki への知識反映（Process 5）を経て初めて render 完了                     |

## 事前条件

`.claude/rules/wiki.md` / `.claude/rules/wiki-style.md` / `.claude/rules/project.md`（出力先に応じて）が auto load されていることを前提とする。
ロードされていない場合は読み込んでから続行する。

停止条件（満たせなければ render を始めない）:

1. `$ARGUMENTS` で渡された raw path が存在するか Read で確認。なければ即停止して lead に再指定を依頼。
2. raw の本文長を確認。1500 byte 未満なら render 拒否して lead に raw 加筆を促す（無理に書き始めない）。
3. wiki / project 側の同名 / 類似タイトルの page を Glob で検索（`30_wiki/` と `40_project/<案件>/` 両方）。既存なら「上書き / 別タイトル / update」のどれにするか lead に確認。NEVER overwrite an existing page without confirming with lead first.
   case-insensitive 衝突（macOS / Windows ファイルシステム）にも注意。例: `React.md` vs 既存 `ReAct.md` のように大文字小文字違いで衝突する場合は、別 page 扱いだが同一ファイルとして上書きされる。対処パターン: A) ファイル名識別子明示（例: `react-library.md`、title は元のまま）/ B) 既存ファイルを別名にリネーム / C) 別名 + 新規 title。lead に確認して決める、勝手に上書きしない。
4. 案件固有出力の場合、`40_project/<案件>/` サブディレクトリが未存在なら lead に「mkdir or 既存案件選択」を確認。

提案条件（lead 確認の上で続行）:

1. 200 行を超える raw は 2 ページ分割を提案して lead 確認を取る。

## Process（9 ステップ）

### 1. raw を完読

raw ファイル全体を Read する。
要点・導入される entity / concept 候補・既存 wiki / project との矛盾候補を内部状態として持つ。

### 2. wiki / project index を読む

`index.md`（ルート）と、raw の内容が属する type カテゴリ（concept / entity / source / synthesis / project）の関連 page を Read する。
`30_wiki/`（汎用）と `40_project/<案件>/`（案件固有）の両方を対象にする。
重複チェック対象と矛盾チェック対象のリストを作る。

### 3. 議論ステップ（lead 提示）

書き始める前に lead に次の固定フォーマットで提示し、**4 判断項目（出力先 / type / title / 関連 entity 置き場）** を確定する。
各項目の判定根拠は `.claude/rules/wiki.md` の「type 一覧」セクション / `.claude/rules/project.md` の「case root と派生 page」セクション /「関連 entity の置き場判断」セクションを参照。

定型句には 4 判断項目に加え提示項目（lead 確認材料）も含む。
raw 外の関連概念（raw に未記載の上位概念や横断知識を entity 化したい場合、例: raw が `LocalBusiness JSON-LD` しか書いていなくても上位の `Schema.org` を提示できる）も提示してよい。
ただし lead 採否判断 → 採用なら Process 4 で書く前に公式ドキュメント等で内容調査必須（推測のみで本文を書かない）→ 不採用なら本 render スコープ外、次回再提案 OK。

`<...>` のプレースホルダは実際の値で埋めて出すこと。サンプルのまま提示しない。

```text
**Using /lw-render skill on `10_raw/<file>.md`.**

要点（3-5 bullets）:
- ...

提案：
- 出力先: `30_wiki/`（汎用）/ `40_project/<案件>/`（案件固有）
- type: <project | entity | concept | source | synthesis>
- title: `<title>.md`
- 関連 entity 置き場（新規作成する entity のみ列挙、なければ「該当なし」）:
  - [[<name>]] → `30_wiki/`（横断で使い回せる）
  - [[<name>]] → `40_project/<案件>/`（案件文脈のみ）

導入される entity / concept（新規作成、なければ「該当なし」）:
- [[<name>]]: <一行説明>

既存 entity / synthesis への update（per-page、なければ「該当なし」）:
- [[<page>]]: <update 内容>

raw 外の関連概念で entity 化候補（採否を lead 判断、なければ「該当なし」）:
- [[<concept>]]: <一行説明>（raw には未記載、横断知識として有用）

同時生成する synthesis（あれば、なければ「なし」）:
- [[<title>]] — <llm-wiki 内応用の方向性>

既存 wiki / project との矛盾候補:
- [[<page>]] と <topic> で食い違う / なし

波及範囲見込み: 約 N ページ（5-10 が目安、10 超なら synthesis を別 render 化を検討）

強調すべき点 / 削るべき点を教えてください（`just render` で議論を skip）。
```

逃げ道: lead が `just render` と返したら議論を skip して書き始める。
それ以外の返答は内容に反映してから書き始める。

### 4. 議論で決まった type で page を書く

議論ステップで確定した出力先と type で新規作成する（type は 5 種いずれもありうる、default は持たない）。

- 出力先: `30_wiki/<title>.md`（汎用）または `40_project/<案件>/<title>.md`（案件固有）
- frontmatter: 5 fields（`type` / `tags` / `sources` / `created` / `updated`、`.claude/rules/wiki.md` の「frontmatter」セクション準拠）

```yaml
---
type: <議論で決定>
tags: [<tag1>, <tag2>, ...]
sources:
  - 10_raw/<file>.md
# contradictions: ["[[<conflicting-page-title>]]"]  # Process 6 で必要なら追加
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

raw 引用は frontmatter `sources:` の path 列挙だけで出典追跡を完結させる。
本文中に `(raw L<行番号>)` や `(raw「<セクション>」セクション)` のような行・セクション参照は書かない（raw は基本永続だが行数 / セクション名は変動しうる、wiki 自立性のため）。
脚注形式（`[^1]`）も使わない。
raw を言い換えるだけの page を作らない。type が source / synthesis いずれであっても、自分の言葉で要約・再構成する（原文写経は source page でも禁止、出典ノートとしての価値しか生まない）。

### 5. 関連 entity / concept / synthesis を生成 or update

step 4 で書いた page から張られる `[[link]]` の先を順に処理する。
既存 page があるものは Edit で in-place merge、なければ Write で新規作成（type=entity か concept、5 fields frontmatter）。

新規 entity / concept の出力先は **Step 3 議論結果を再判断せず適用**する（per-entity で `30_wiki/` か `40_project/<案件>/` を決定済み）。

raw が llm-wiki 内 decision に逆流させる価値ある横断分析を含む場合は、synthesis page も同時生成する（議論ステップで lead と合意済みの場合のみ）。
synthesis の出力先（汎用 `30_wiki/` / 案件文脈に閉じるなら `40_project/<案件>/`）も Step 3 議論時に確定しておき、ここでは再判断しない。
synthesis のみ別 render にするか同時生成するかは波及範囲（数値閾値）と相談、目安は合計 10 ページ以内。

ルール:

- NEVER overwrite — 必ず Read してから Edit する
- 時系列追記（`## YYYY-MM-DD 追記` セクションを増やす）はしない
- 既存セクションの該当箇所に追記、新概念は新規セクションを追加

entity の「<ワークスペース名> での参照」セクションの粒度（例: `my-wiki` ワークスペースなら「my-wiki での参照」）:

- 不変な事実のみ書く（例: `[[acme-corp]] で利用`）
- 流動情報を書かない（例: `[[acme-corp]] でテストケース 11 件 + 11 件で利用`）
- 流動 = テストケース数 / version / phase 番号 / 時系列ステータス、案件側変更で wiki 追従が要求される情報
- 判定: 「半年後に同じ記述で正しいか?」を問う、否なら案件側にだけ書く
- 詳細は設計書の「entity『<ワークスペース名> での参照』セクションの粒度ガイド」

raw 外の概念を entity 化する場合:

- Process 3 議論ステップで lead 採否判断済みの場合のみ書く
- 採用判断後、公式ドキュメント等で内容調査必須、推測のみで本文を書かない
- lead 確認なしに勝手に entity 追加しない（hallucination）

### 6. 矛盾保持

既存 page と矛盾する記述を見つけても render 中に解決しない。
両方の page の frontmatter `contradictions:` フィールドに相手のタイトルを追記し、本文は両方残す。
解決は別 skill（`/lw-lint`）または lead 判断に委ねる。

```yaml
contradictions:
  - "[[<conflicting-page-title>]]"
```

---

ここから先（7-8）は書き終えた後の検査ステップ。render 対象 page の整合性を wiki / project 全体に対して走査する。

### 7. バックリンク走査

ALWAYS: 新出 entity / concept 名で `30_wiki/` と `40_project/` 両方を Grep する。
省略可の選択肢を作らない、必ず実行する。

Grep の結果でリンクなしの参照箇所が見つかったら lead に提示し、`[[link]]` 化するかを per-file で確認する。
勝手に書き換えない。

### 8. 影響範囲報告

render で作成または編集した page を引用している他 page を `30_wiki/` と `40_project/` 両方から Grep で取得して出力する。
期待値は 5-10 ページ。極端に少ない（0-1）または多い（20+）なら lead に報告。

形式:

```text
影響範囲:
- [[<other-page-title>]] — <該当行の前後 1 行>
```

### 9. render 完了後の lead 自走運用ガイド

skill は log.md / index.md / case root に触らない（下書き提示もしない）。
render 完了後、lead が CLAUDE.md `## log / index` のターン終了前セルフチェック準拠で次の 2 つを自走更新する:

1. log.md / index.md への追記（`.claude/rules/log-index.md` のフォーマット準拠）
2. case root（`40_project/<案件>/<案件>.md`）の「関連 raw」セクション行を「（未 render）→（render 済み、[[<page-title>]]）」に更新

render 開始時に raw を `[[link]]` 候補として書いた場合は、完了後にラベルを切り替える運用。

## よくあるミス（render 中 + 完了後チェック）

言い訳対戦表は起動前の skip 誘惑への対抗。こちらは render 実行中 + 完了後に起こる手順違反。

1. 既存 wiki / project page を読まずに上書きする（書く前に読む違反）
2. 時系列追記（`## YYYY-MM-DD 追記`）でセクションを増やす（既存に追加違反）
3. 矛盾を見つけて消す、または無視する（`contradictions:` frontmatter に残さない）
4. バックリンク走査を省略する
5. case root の「関連 raw」セクションのラベル（未 render / render 済み）を更新し忘れる（「Process 9」違反）
6. entity の「<ワークスペース名> での参照」セクションに流動情報（テストケース数 / version / 時系列ステータス）を書く（「Process 5」粒度ガイド違反）
7. raw 外の関連概念を lead 確認なしに entity 追加する（「Process 3」議論ステップ違反、推測 hallucination）
8. raw 引用を本文中に書く（`(raw L<行番号>)` / `(raw「<セクション>」セクション)`）。raw は基本永続だが行数 / セクション名は変動しうる、wiki 自立性のため frontmatter `sources:` で出典追跡を完結させる（「Process 4」違反）
9. WebSearch 結果と raw / lead 直接情報が矛盾するのに WebSearch 側を採用する（一次情報 = raw / lead 提示を優先、WebSearch は補完のみ）
10. source title に元ファイルの生表現（「生ログ」「メモ」「対談ログ」等）をそのまま使う（役割名・行為名で命名、「Process 3」議論ステップの「title」違反）
11. source page を作成しただけで Process 5（既存 entity / concept への update）を省略する（source page は出典追跡の器、既存 wiki への知識統合が render の主要な価値）
12. Write/Edit した page にパス参照（`30_wiki/Foo.md` 等）を混入する（CLAUDE.md「文書規約」の `[[link]]` 規約違反。パスは mv/rename で壊れる）

NEVER do these unless lead explicitly overrides.

## 数値閾値

| 項目             | 値          | 動作                                           |
| ---------------- | ----------- | ---------------------------------------------- |
| 本文長下限       | 1500 byte   | これ未満は render 拒否、lead に raw 加筆を促す |
| ページ分割       | 200 行超    | 2 ページ分割を提案、lead 確認                  |
| 波及範囲の期待値 | 5-10 ページ | 範囲外なら lead に報告                         |

波及範囲は「新規作成 / 編集される wiki / project page の合計数」を指す（既存 page への backlink 化は含めない）。
10 超になりそうな場合は synthesis を別 render に分割を lead に確認。詳細は設計書の「数値閾値の設計根拠」セクション参照。

## 必須動作

- バックリンク走査前の Grep は省略不可（Process 7）
- log.md / index.md / case root の「関連 raw」セクションは lead 自走更新、skill は触らない（Process 9）

`/lw-lint` 系の整合性チェックは本 skill の対象外。render は render のみに集中する。
