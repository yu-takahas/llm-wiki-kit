---
type: concept
tags: [issue, workflow, design]
sources:
  - conversation
  - "[[claude-obsidian]]"
created: 2026-05-14
updated: 2026-08-03
---

# llm-wiki-kit の issue

llm-wiki-kit における進行中タスクの中断点メモの置き場。
ルート直下の `00_issues/` ディレクトリにタスク単位のファイルを置く。

## 動機

[[LLM-Wiki]] 方式は 1 render で 5〜15 ページに波及するので、中断時に「どこまでやったか」が見えづらくなる。
1 点もの方式時代は各ファイル末尾の `## TODO` セクションがその役だったが、wiki 方式では更新が分散して機能しなくなった。
そこで中断点メモを **タスク単位の独立ファイル** に切り出す。

## 設計: git ブランチ + issue tracker

タスク = ブランチ的に独立した作業単位。
任意のタイミングで切れて、複数並行で走らせて、完了 or 廃棄する。
GitHub Issues がない llm-wiki-kit では issue が issue tracker 代替を担う。
完了・廃棄した issue も「closed issue」として `.90_fixed/` / `.99_faded/` に保持する。

| git                   | issue                                        |
| --------------------- | -------------------------------------------- |
| `git checkout -b foo` | `touch 00_issues/foo.md`                     |
| `git checkout foo`    | `cat 00_issues/foo.md` で復帰                |
| `git status`          | `ls 00_issues/`                              |
| `git log`             | `1_issues.md`（タスクインデックス）          |
| `git merge foo`       | 内容を wiki に書き戻し → `.90_fixed/` に mv  |
| `git branch -D foo`   | `.99_faded/` に mv（採用判断記録として保持） |

## 5 状態とディレクトリ配置

状態をフォルダ位置で表すのは、状態変更を mv だけで完結させ、ファイル内容を触らずに済ませるため。
frontmatter に状態を持つと、遷移のたびに中身の編集が要り、フォルダとの二重管理になる。

```text
llm-wiki-kit/
├── 00_issues/                  # WIP（進行中）
│   ├── .00_icebox/             # ICEBOX（保留）
│   ├── .10_todo/               # TODO（次着手）
│   ├── .90_fixed/              # FIXED（確定）
│   ├── .99_faded/              # FADED（廃棄）
│   ├── llm-wiki-kit-issue-rework-ops.md
│   └── ...
├── 0_icebox.md                 # 🧊 ICEBOX
├── 1_issues.md                 # ☔ WIP / 🌂 TODO
├── 2_done.md                   # 🌈 FIXED / 🌫️ FADED
└── ...
```

ドット prefix は隠しディレクトリ扱い、active issue のファーストビューから外す意図。
番号体系は llm-wiki-kit の他ディレクトリ（`00_issues` / `10_raw` / `20_library` / `30_wiki` / `40_project` / `90_reports`）と整合。

### 状態遷移

```text
ICEBOX → TODO → WIP → FIXED
                  ↓
                FADED（任意の状態から）
```

FADED はどの状態からでも遷移できる。

## ファイル名規約

名前を 4 要素（プロジェクト / サブプロジェクト / 動詞 / 対象）に割る。

プロジェクトとサブプロジェクトを分けるのは、`1_issues.md` の一覧を 2 段のネストで出すため（下記「一覧の表示形式」）。
動詞を含めるのは、ファイル名だけで「何をする issue か」が読めるようにするため。
既存の語彙を優先するのは、同じ主題の issue がファイル名順で隣り合うようにするため。

どのプロジェクトにも属さない issue には `_` prefix を付ける。
「project なしが意図的」であることを明示するマーカーで、命名を後回しにした結果と区別できる。

各要素の決め方と確認手順は `.claude/rules/issue.md`「作成」が持つ。

### 一覧の表示形式

`1_issues.md` での issue 一覧は、project → subproject → entry のネストリストで表示する:

```markdown
- llm-wiki-kit
  - skill
    - [[lw-kit-skill-fix-cmux-teams]] — 説明
  - wiki
    - [[lw-kit-wiki-design-lint-skill]] — 説明
- project-b
  - [[project-b-track-tasks]] — 説明
```

案件 issue は subproject を持たないので project → entry の 2 段。

### カテゴリ

`1_issues.md` / `0_icebox.md` / `2_done.md` のエントリを分類するサブカテゴリ。
足りなければ追加してよい。
迷ったら「主目的」で 1 つに決める（飲み会 → 人に会うのが目的 → 📬、本を読む → 📚、読んだ内容を wiki 化 → 🎨）。

🔧 つくる（ものを作る・開発する）:

- 🌊 llm-wiki-kit 開発
- 🏗️ プロジェクト
- 📝 ブログ記事化

📚 まなぶ（知識を入れる・整理する）:

- 📚 学習・読書
- 🎨 知見の整理

💼 はたらく（キャリア・仕事・手続き）:

- 🎯 キャリア
- 💼 実務・手続き
- 💰 お金まわり

🤝 あそぶ（人と会う・出かける・楽しむ）:

- 🎪 イベント
- 📬 コミュニケーション・交流
- 🧳 旅・生活

🧠 みつめる（自分を知る）:

- 🧠 自己分析・メタ認知

✨ いつか:

- ✨ いつかやりたい

## frontmatter

```yaml
---
related: []          # 関連ファイル（形式は下記）
source: <出典・議論履歴・参照ファイルなど>
created: YYYY-MM-DD  # 起票日
tags: [issue, ...]    # issue は共通、ほかにブランチ固有のタグを追加
---
```

`source` / `tags` は llm-wiki-kit の他の frontmatter と一貫性を持たせるために含める。
`related` は issue 固有のフィールド。
`created` は起票日。鮮度チェックや棚卸しで「いつ切った issue か」を判断する材料。
状態は frontmatter に持たない（フォルダ位置が SSOT）。

### `related` field の中身

配列、要素は次のいずれか:

- `"[[page-title]]"` — issue / wiki page への wikilink（YAML で `[[` は配列開始と衝突するため引用符必須）。issue は状態ディレクトリ移動でパスが変わるため、issue 間参照は wikilink 必須
- `<path>` — 非 wiki ファイルへのパス（`.claude/rules/issue.md` / `README.md` / `lefthook.yml` 等、wikilink で解決できないもの）
- `<directory>/` — ディレクトリ参照（`10_raw/project-b/` / `90_reports/weekly/` 等、末尾 `/`）

wiki.md `sources` field と対比: `sources` は出典（raw パス / URL / `conversation`）、`related` は作業上の関連物（他の issue / 設計書 / 設定ファイル）。

## ファイル内部構造

4 セクション（💧 進行中 / 🌂 中断点 / ☔ TODO / 🪣 経緯）に割るのは、中断から戻る時に読む順序と、書き足す時の置き場を一致させるため。
いま考えていることと「いまどこ」を分けておくと、前者が長くなっても後者は 3 行で読める。

emoji は llm-wiki-kit の世界観（水・雨・傘・バケツ）に揃える。

guide（`00_issues/.guide/`）はタスク種別ごとに「毎回やること」を持つメニューで、該当行をコピーすれば issue 側は固有の作業だけを書けばよくなる（[[lw-kit-詳細設計-guide]]）。

短期 issue と長期 issue の差は TODO の粒度で表現する（軽量タスクなら 1〜3 行、重量タスクなら Phase 分けや並行進行マーク）。
セクション自体を省略しないのは、戻ってきた時に「TODO 無し = 完了」と誤読しないため。

### 進捗の台帳を 1 箇所に決める

テストシナリオを ☔ TODO の外に切り出した issue で台帳が分離した。
シナリオとも作業行とも読める項目が両方に載り、判断が揺れるたびに差分が広がった。

壊れるのは同じものを 2 つの軸で追うとき。
軸が違えば台帳が複数あっても衝突しないので、切り分けの基準は「数が 1 つか」でなく「追う対象が同じか」に置く。

### 🪣 経緯を append-only にしない

`log.md` は append-only だが、🪣 経緯は後から書き換えてよい。
log は操作の記録で、後から変えると事実が壊れる。
🪣 は「何が起きたか」の記述なので、表現を整理したり後で分かったことを補ったりする方が、次に読む時の価値が上がる。

## 多重数

実用上は 3〜5 並行が限界。
それ以上は「並行」じゃなく「保留」状態なので `.00_icebox/` に mv する。

| 段階      | 状態                    | 置き場                      |
| --------- | ----------------------- | --------------------------- |
| 1〜3 並行 | 全部頭に入る            | `00_issues/` 直下にフル詳細 |
| 4〜5 並行 | 切り替え時に issue 読む | `00_issues/` 直下に要点だけ |
| 6 以上    | 「保留」状態            | `.00_icebox/` に mv         |

## 派生作業の記録先

記録先の選び方は issue の総量に直接効く。
新規を作れば並行数が上記の限界に近づき、起票そのものにも手間がかかる。安い側から順に候補を並べているのはそのため。

ただし安さと可視性は逆方向に働く。
最も安い経路が最も見えにくいので、報告義務を対に置いて釣り合わせている。

候補の並びと報告義務は `.claude/rules/issue.md`「派生作業の記録先」が持つ。

## インデックス 3 ファイル

旧 `TODO.md` / `ICEBOX.md` の役割を 3 ファイルに分けて引き継ぐ。
各セクション内はカテゴリ（上記）でサブ分類する。

- `0_icebox.md` — 🧊 ICEBOX（保留中）
- `1_issues.md` — ☔ WIP（進行中）/ 🌂 TODO（次に着手するもの）
- `2_done.md` — 🌈 FIXED（完了）/ 🌫️ FADED（着手せず終わったもの）

## ライフサイクル

1. **起票**: 「これやろう」と思ったら `00_issues/<name>.md` を作り、`1_issues.md` に登録する
2. **作業中**: 中断時に「いまどこ」を書く
3. **完了**: 内容を仕分けてから状態遷移する
4. **廃棄**: 採用しなかった場合、`.99_faded/` に mv する

### 閉じた issue を残す理由

判断過程・選択肢比較は、wiki に書き戻すには文脈依存が強すぎるが、捨てるには価値がある中間ゾーンにある。
閉じた issue を「closed issue」として保持することで、この中間ゾーンの居場所を作る。

仕分けの手順は `.claude/rules/issue.md` が持つ。

## 関連

- [[LLM-Wiki]] — 中断耐性の弱さを補う
- [[lw-kit-詳細設計-guide]] — ☔ TODO に流し込むワークフローのメニュー
- 状態管理 + skill 化の設計経緯はワークスペース側の issue に残る（kit には含まれない）
