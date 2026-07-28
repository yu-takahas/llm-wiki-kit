---
type: synthesis
tags: [llm-wiki-kit, render, skill-design, synthesis]
sources:
  - "[[LLM-Wiki-ingest-skillのパターン]]"
  - "[[Claude-Code-Skillの書き方]]"
  - "[[lw-kit-詳細設計-log-index]]"
  - "[[プロンプト設計原則]]"
  - "[[lw-kit-詳細設計-issue]]"
  - conversation
created: 2026-05-16
updated: 2026-07-26
---

# llm-wiki-kit の render skill 設計

llm-wiki-kit の `/lw-render` skill（raw → wiki に render する動作を自動化）の設計書。
横断パターンは [[LLM-Wiki-ingest-skillのパターン]]、SKILL.md 一般論は [[Claude-Code-Skillの書き方]] を参照。
本ページは「12 要件の llm-wiki-kit 具体化 / 数値閾値の確定 / よくあるミスと言い訳対戦表の確定文言 / SKILL.md スケルトン」を集約する。

各設計判断の上位原則は [[プロンプト設計原則]] にまとめてあり、本ページの各節では該当する原則への `[[link]]` で根拠を示す。

## データフロー

```mermaid
graph LR
    raw[("10_raw/&lt;file&gt;.md")] -->|"読み込み"| skill(["/lw-render"])
    index[("index.md")] -->|"既存確認"| skill
    wiki[("30_wiki/<br/>40_project/")] -->|"既存ページ確認"| skill
    skill -->|"作成・更新"| wiki
```

## skill 名

`/lw-render` 採用。llm-wiki-kit の世界観（雨 / 水 / イラストレーター制作工程）に揃える観点で、wiki で絵を完成させる比喩が最もフィット。

検討した他の候補:

| 候補       | 意味                      | 不採用理由                                       |
| ---------- | ------------------------- | ------------------------------------------------ |
| `/ingest`  | 取り込み（Karpathy 用語） | 技術寄り、llm-wiki-kit の世界観に合わない        |
| `/pour`    | 注ぐ                      | 動作は直感的だが「絵を完成させる」感が弱い       |
| `/distill` | 蒸留                      | 動作のニュアンスが「絞り出す」寄りで写経感が薄い |

skill 名だけでなく動作概念としても「render」を使う（`/lw-render` skill が render 動作を実行する、という関係）。

## skill 配置

全 skill は project-local（`.claude/skills/` 配下）。

- 実体: SKILL.md（`.claude/skills/lw-render/SKILL.md`）
- 設計書: 本ページ（`docs/lw-kit/40_スキル設計/`）
- ディレクトリ名 `lw-render` と frontmatter `name: lw-render` を揃える

## 呼び出し制御

`disable-model-invocation: true` を frontmatter に付け、Claude の自動起動を禁止する（`/lw-render <path>` のユーザー明示起動のみ）。

根拠:

- render は 1 回で 5-10 ページを書き換える副作用の大きい操作で、議論ステップ / 矛盾保持 / バックリンク走査すべてが lead 判断を前提にしている
- raw ファイルを開いただけで自発起動すると、言い訳対戦表で抑止しているはずの「とりあえず render」が逆方向から発生する
- 副次効果として description（~200 char 前後）が常時 context に積まれなくなる
- - 対比: 同様の「特定タイミングで必ず実行」要件は [[Claude-Code-Hook]] で扱う（LLM を介さない決定論的処理）。render は「対話 + lead 判断」が必須なので Hook ではなく手動起動が筋

## 許可ツールの最小化

Read / Write / Edit / Glob / Grep + `Bash(wc:*)`。
最小権限の原則([[Claude-Code-Skillの書き方]]「allowed-tools」セクション)に従い、Process 9 ステップで実際に必要なものに絞っている。
汎用 `Bash` は使わない(`rm` / `mv` / `git` 等まで暗黙に許可されてしまう)。
`Bash(wc:*)` だけ入れた理由: 本文長 / 行数は Read 後の文字列計測でも代替可だが、`wc` の方が確定的で実装が短い。
具体的な用途は SKILL.md を参照。

## 12 要件の llm-wiki-kit 具体化

[[LLM-Wiki-ingest-skillのパターン]] の 12 要件を llm-wiki-kit の具体的な記述に落とす。

### 1. SKILL.md 冒頭の `description` フィールド

[[CO-STAR]] の Response（出力形式）+ Audience（受け手）設計の skill 版。Audience は「raw を render しようとしている lead」、Response は **third person の action description**（起動判断情報を含む、Anthropic 公式 best practice の "Always write in third person" に準拠）。

description 文案（起動判断情報に絞る、命令は本文側に書く）:

```yaml
description: Renders a raw source (`10_raw/<file>.md`) into the llm-wiki-kit wiki (`30_wiki/` 汎用 or `40_project/<案件>/` 案件固有). Triggers when the lead adds a new raw and needs it propagated as 5-10 wiki pages across entity / concept / synthesis categories.
```

言い訳対戦表（resist-table）の SKILL.md 内配置は セクション 10 を参照。

### 2. 事前条件

[[赤ずきんの原則]] の「停止条件を明示する」を skill 化したもの。条件を満たさなければ Process に入らない。

- rules の wiki / wiki / project 規約（[[lw-kit-詳細設計-rules]]）が auto load されていることを前提
- `10_raw/<file>.md` が存在することを確認、なければ即停止
- 同名 page が `30_wiki/` または `40_project/<案件>/` 配下に既存なら lead に「上書き / 別タイトル」確認、勝手に上書きしない
- case-insensitive 衝突（`React.md` vs 既存 `ReAct.md` 等、macOS / Windows ファイルシステム）も同名衝突として扱う。対処は SKILL.md「事前条件」セクションの注釈 3 を参照（A: ファイル名識別子明示 / B: 既存リネーム / C: 別名 + title、lead 判断）

### 3. 議論ステップ

raw を読み終わったら以下の定型句で lead に提示。
4 つの判断項目を議論で確定する（定型句の「提案：」ブロックに対応）:

- 出力先: 汎用知識 → `30_wiki/<title>.md` / 案件固有 → `40_project/<案件>/<title>.md`
- type: 5 種いずれも候補（project / entity / concept / source / synthesis、判定の境界は rules の wiki schema、[[lw-kit-詳細設計-rules]]）
- title:
  - case root はサブディレクトリ名と同名（`40_project/` 配下）/ 派生 page は `<案件名>-<派生 title>` 形式、段を切った案件では `<案件名>-<段名>-<派生 title>`（F2 規約、rules の project 規約、[[lw-kit-詳細設計-rules]]）
  - ファイル名の文字種規約は rules の wiki schema（[[lw-kit-詳細設計-rules]]）を参照（半角 space 禁止 / `_` 禁止 / 英境界 `-` / 日本語境界連結）
  - source title の命名では raw title をそのまま使わず、raw 表記（「生ログ」「メモ」「対談ログ」等）を wiki に持ち込まない、役割名・行為名で命名する（事例: 「Gemini対談の生ログ」 → 「方針ブレスト」）
- 関連 entity 置き場: 横断で使い回せそう → 汎用 / 案件文脈のみ → 案件固有（rules の置き場判断規約、[[lw-kit-詳細設計-rules]]）

提示項目（4 判断項目とは別、定型句に含まれる lead 確認材料）:

- 導入される entity / concept、既存 entity / synthesis への update、同時生成する synthesis、raw 外の関連概念、矛盾候補、波及範囲見込み（詳細は 「議論ステップの定型句」セクション）
- raw 外の関連概念: raw に明示されていない上位概念や横断知識を entity 化したい時は議論ステップで lead に提示し、採否判断を仰ぐ。採用 → 公式ドキュメント等で内容調査必須、推測のみで本文を書かない（Process 4 で書く前に調査）。不採用 → 本 render スコープ外、次回再提案 OK。例: raw が `LocalBusiness JSON-LD` だけを書いていても、上位概念の `Schema.org` を entity 化候補として提示できる

逃げ道: lead が `just render` と言えば議論を skip して書き始める。

参照: 「議論ステップの定型句」セクション

### 4. 書く前に読む + 既存に追加

[[赤ずきんの原則]] セクション 7 ガイドラインの「既知の形式を模倣する」を render プロセスに適用。既存 page の構造を読まずに上書きすると、訓練データの「道」から外れた形式になる。

- 新規 source page 作成: 確認なしで書く
- 既存 entity / concept page の編集: 必ず Read してから merge、上書きせず追加、時系列追記（`## YYYY-MM-DD 追記`）禁止

### 5. 矛盾の保持

既存 page と矛盾する記述を見つけても render 中に解決しない。
両方の page の frontmatter `contradictions:` フィールドに相手のタイトルを追記し、本文は両方残す。
解決は別タイミングの `/lw-lint` または lead 判断。

### 6. バックリンク走査

新出 entity / concept 名で `30_wiki/` と `40_project/` 全体を grep。
リンクなし箇所を lead に提示し、`[[link]]` を追加するかを per-file で確認。
省略不可の警告は Process 7（バックリンク走査）と よくあるミス の 2 箇所に書く。

[[Lost-in-the-Middle]] の context 中央劣化を補完する構造的検査ステップ。新出 entity を本文中央で言及した既存 page は LLM の注意から漏れやすいため、grep で機械的に拾う。

参照: 「数値閾値の確定値」セクション（走査必須行）

### 7. 影響範囲報告

render 完了時に「この page を引用している他 page」を `30_wiki/` と `40_project/` から grep で取得して出力。
形式: `- [[other-page-title]] — <該当行の前後 1 行>`

### 8. log / index は lead 自走、case root 「関連 raw」セクションのラベルも同タイミング

render 完了後、lead が CLAUDE.md `## log / index` のターン終了前セルフチェック準拠で log.md / index.md を自走更新する。
skill は log.md / index.md に触らない（下書き提示もしない）。

同タイミングで case root（`40_project/<案件>/<案件>.md`）の「関連 raw」セクションの行を「（未 render）→（render 済み、[[<page-title>]]）」に更新する。
render 開始時に raw を `[[link]]` 候補として書いた場合は、完了後に状態ラベルを切り替える運用。

参照:「入出力 / 副作用 / エラー時の振る舞い」セクション

### 9. よくあるミスのセクション

SKILL.md 内に必須セクション。

参照:「よくあるミスの確定 8 項目」セクション

### 10. 言い訳対戦表

[[Self-Refine]] のメタトリガー設計の起動前版。Process に入る前に「skip したい誘惑」を自己抑止させる。
SKILL.md 冒頭の `description` フィールド直後に配置（セクション 1 と隣接）。
確定文言は「言い訳対戦表の確定 6 項目」セクションを転記。

### 11. 引用は frontmatter sources で完結

raw 引用は frontmatter `sources:` の path 列挙だけで出典追跡を完結させる。
本文中に `(raw L<行番号>)` や `(raw「<セクション>」セクション)` のような行・セクション参照は書かない。
脚注形式（`[^1]: ...`）も使わない。

理由:

- raw は基本的に永続的（path は不変、ファイル削除も基本なし）が、行数 / セクション名は raw 編集で変動しうる
- 本文中の細かい行・セクション引用は wiki page が「源泉に依存して読む」形になり、wiki 自立性を損なう
- frontmatter `sources:` の path 参照だけで「どの raw から来たか」は追える、これで十分という関係性で運用する
- どうしても本文中に出典明示が必要な場合は code span（例: `` `10_raw/<file>.md` ``）に留め、行数まで書かない

### 12. 数値閾値の明文化

4 個確定。

参照: 「数値閾値の確定値」セクション

## 数値閾値の設計根拠

具体的な閾値は SKILL.md を参照。
設計根拠:

- 本文長下限(1500 byte): [[karpathy-wiki]] の `chat-only` floor 準拠
- ページ分割(200 行超): [[karpathy-wiki]] 準拠 + [[Progressive-Disclosure]]
- 波及範囲(5-10 ページ): llm-wiki-kit はフラット運用なので [[claude-obsidian]] の 10-15 より少なめ。render で新規作成 / 編集される wiki page の合計(backlink 化は含めない)
- backlink 走査前 grep: 必須。「省略可」の選択肢を作らない

## entity「<ワークスペース名> での参照」セクションの粒度ガイド

entity page の「<ワークスペース名> での参照」セクション（例: `my-wiki` ワークスペースなら「my-wiki での参照」）は不変な事実のみ書く。
案件側変更で wiki 追従が要求される情報は書かない。

| 書く（不変）                  | 書かない（流動）                                   |
| ----------------------------- | -------------------------------------------------- |
| `[[project-a]] で利用`        | `[[project-a]] でテストケース 11 件 + 11 件で利用` |
| `Resend でフォーム送信に採用` | `Resend で API key を月 X 回再発行`                |

書かない理由:

- テストケース数 / version / phase 番号 / 時系列ステータスは案件側で変動する
- case page を変えるたびに entity wiki 追従が要求され、保守負荷が雪だるま式になる
- entity は wiki グラフのハブで、case 数 × 流動属性数の倍数で更新負荷が増える

判定: 「半年後に同じ記述で正しいか?」を問う。
否なら案件側にだけ書く。

## WebSearch 補完時の優先順位

raw 外の関連概念を entity 化する際、内容調査が必要な場合の優先順位:

1. raw 内容 / lead 直接情報 — 最新情報、必ず優先
2. 公式ドキュメント / 一次情報 — 検証可能、信頼性高い
3. WebSearch 結果 — 補完情報、ただし古い可能性あり

WebSearch 結果と raw / lead 情報が矛盾する場合は raw / lead 優先。
事例: とある企業の本社住所、WebSearch = 旧本社、raw = 新本社、user 訂正で raw 採用。

WebSearch を引いた場合は entity の frontmatter `sources:` に URL を含めて出典追跡可能にしておく（古い情報と分かれば後で削除しやすい）。

## よくあるミス / 言い訳対戦表

具体的な項目リスト(よくあるミス 12 項目、言い訳対戦表 6 項目)は SKILL.md を参照。
設計書は各項目が存在する理由の上位原則を記録する:

- 「書く前に読む」「既存に追加(時系列追記しない)」は [[赤ずきんの原則]] セクション 7「既知の形式を模倣する」の render 適用
- 「矛盾保持(解消しない)」は両方残して別タイミングの解決に委ねる方針
- 「バックリンク走査必須」は [[Lost-in-the-Middle]] の context 中央劣化を補完する構造的検査
- 「言い訳対戦表」は [[Self-Refine]] のメタトリガー設計の起動前版(Process に入る前に skip したい誘惑を自己抑止)

## 議論ステップの設計

定型句のテンプレート全文は SKILL.md Process 3 を参照。
4 判断項目(出力先 / type / title / 関連 entity 置き場)を書き始める前に確定するのが目的。
escape hatch として `just render` で議論を skip できる。

## エラーハンドリング

具体的なケース表は SKILL.md を参照。
方針: リトライ / 自動回復は持たない(lead 投げで十分)。
skill は log.md / index.md / raw 元ファイルに触らない(lead 自走更新)。

## SKILL.md の構造設計

SKILL.md のセクション順序の根拠:
言い訳対戦表(skip 抑止) → 事前条件(停止判定) → Process(実行) → よくあるミス / 数値閾値(事後参照)の認知順序。
[[Lost-in-the-Middle]] のサンドイッチ戦略(先頭と末尾に重要情報、本文中央に手順) + [[Chain-of-Thought]] のスキャフォールディング(9 ステップへの分解)に基づく。

### Step 5 の synthesis 生成パス + 複数 page 分解パターン

raw が「複数 entity / concept を横断する素材」の場合、source page と並んで synthesis page も同時生成できる。
さらに大型 raw（特に対談ログ・自己分析 + 戦略 + エピソード混在の raw 素材）は **A entity 汎用 / B synthesis 案件固有 / C source 圧縮版** の 3 ファイル分解パターンも採用可。

判断基準:

- raw 単体素材で完結 → source + entity / concept のみ（波及 1-6 ページ）
- raw が llm-wiki-kit 内 decision に逆流させる価値ある横断分析を含む → source + entity + synthesis 同時生成（波及 6-12 ページ）
- 大型 raw（切り口混在、使い回しやすさのため複数 page に分けたい） → A entity（汎用 wiki、横断知識）+ B synthesis（案件 project、戦略・ビジョン）+ C source（案件 project、対談形式 + エピソードに圧縮）の 3 ファイル分解
- 波及が 10 ページを超える見込み → synthesis は別 render に分割を lead 確認

3 ファイル分解時の本文配分:

- A entity（汎用 wiki）: 自己分析・特性プロファイル等、横断知識
- B synthesis（案件 project）: 案件固有の戦略・ビジョン、A entity を心理的根拠として参照
- C source（案件 project）: 対談形式・エピソード集等、A / B に分離した本文以外を圧縮保持

事例: 51KB の対談 raw を、テーマの異なる 3 ファイルに分解（ワークスペース側の実例）。

synthesis 同時生成 / 3 ファイル分解時は議論ステップ定型句にも候補を載せる（「議論ステップの定型句」セクション参照）。

### case root の生成タイミング

案件 render で case root（`40_project/<案件>/<案件>.md`、type=project）を最初に書くか最後に書くかは、既存 raw の構造で判断する。

| 状況                                                          | 推奨順序                                                  |
| ------------------------------------------------------------- | --------------------------------------------------------- |
| 明示的な方針 raw が存在（例: `20260426_プロジェクト方針.md`） | 方針 raw → case root → 派生 page                          |
| 明示的方針なし、対談ログや断片的な raw のみ                   | 派生 page を順次 render → 最後に case root を書く（俯瞰） |

事例（ワークスペース側の実例、案件名は伏せる）:

- プロジェクト方針 raw 先行 → case root を 1 番目に起こしたケース
- 受験経緯まとめ raw → case root に集約したケース
- 明示的方針なし、前半で派生 source 5 件先行 → 最後に case root で俯瞰したケース

判断軸: 案件の方針が断片的にしか語られていない場合、render 過程で素材が集まる → 集まった素材を俯瞰する形で case root を書く方が無駄が少ない。

## 採用しなかった機能

新 entity 群（[[Dynamic-Context-Injection]] / [[context-fork]] / [[Sub-Agent]] / [[Claude-Code-Hook]]）について、render skill では採用しなかった理由を記録する。

| 機能                          | 不採用理由                                                                                                                                               |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [[Dynamic-Context-Injection]] | raw は path 引数で指定、起動時の動的シェル実行は不要。`!`ls 10_raw/`` 等のメニュー化案も考えられるが、議論ステップで lead が明示指定する設計なので冗長   |
| [[context-fork]]              | 議論ステップで lead 対話が必須、fork すると親会話履歴を失って対話が成立しない。inline 実行が前提                                                         |
| [[Sub-Agent]]                 | 矛盾保持判断 / バックリンク per-file 確認は lead 自身が担う、Sub Agent に委譲すると判断ループが分断される。空 context Sub Agent も会話履歴を失うので不可 |
| [[Claude-Code-Hook]]          | enforcement が必要なら検討余地あり（`PostToolUse` で log.md 自動追記 / `Stop` で影響範囲レポート差し込み等）、現状は手動 lead 確認に集中。将来の拡張候補 |

## 保守規律

- ミスドリブン更新(Boris-Cherny 方式): 試運転で見つかった失敗は SKILL.md のよくあるミス / 言い訳対戦表に追記し、設計書には上位原則のみ反映する
- 本設計書と SKILL.md の同期: 具体値(数値閾値 / よくあるミス / 言い訳対戦表 / 議論ステップ定型句)の正本は SKILL.md。設計書は why のみ。具体値のみの変更なら設計書は触らない

## 関連

- [[LLM-Wiki-ingest-skillのパターン]] — 4 実装横断のパターン、本ページの 12 要件の元
- [[Claude-Code-Skillの書き方]] — SKILL.md 一般論
- [[lw-kit-詳細設計-log-index]] — log / index 更新トリガー
- [[lw-kit-詳細設計-issue]] — issue から永続知識を wiki へ移す動線の出発点
- [[プロンプト設計原則]] — 本設計書の各判断の上位原則
- [[赤ずきんの原則]] / [[Lost-in-the-Middle]] / [[Chain-of-Thought]] / [[Self-Refine]] / [[CO-STAR]] / Boris-Cherny / [[Progressive-Disclosure]] — 設計判断の根拠（個別 entity）
- [[Claude-Code-Hook]] / [[Sub-Agent]] / [[context-fork]] / [[Dynamic-Context-Injection]] — 採用しなかった機能（「採用しなかった機能」セクション参照）
- [[lw-kit-詳細設計-rules]] — rules の構成（wiki / wiki / project / issue / skeleton-confirm の設計・運用・改訂の起点）
- [[lw-kit-アーキテクチャ設計]] — skill 群全体での位置づけ（wiki render ファミリー）
