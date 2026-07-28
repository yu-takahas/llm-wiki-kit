---
type: concept
tags: [issue, workflow, design]
sources:
  - conversation
  - "[[claude-obsidian]]"
created: 2026-05-14
updated: 2026-07-04
---

# llm-wiki-kit の issue

llm-wiki-kit における進行中タスクの中断点メモの置き場。
ルート直下の `00_issues/` ディレクトリにタスク単位のファイルを置く。
名前は llm-wiki-kit の世界観に沿った命名（雨の滴 = 進行中の小さなタスク）。

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

状態 = フォルダ位置。
状態変更 = ファイル mv で完結、frontmatter は不変。

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

| 状態           | フォルダ                |
| -------------- | ----------------------- |
| WIP（進行中）  | `00_issues/` 直下       |
| TODO（次着手） | `00_issues/.10_todo/`   |
| ICEBOX（保留） | `00_issues/.00_icebox/` |
| FIXED（確定）  | `00_issues/.90_fixed/`  |
| FADED（廃棄）  | `00_issues/.99_faded/`  |

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

`<プロジェクト>-<サブプロジェクト>-<動詞>-<対象>`

- プロジェクト: `llm-wiki-kit` / 案件名（`project-b` 等）。どちらにも当てはまらない場合は `_` prefix を付けた bare-name にする（例: `_setup-worktree-parallel-sessions.md` / `_research-thinking-style-profile.md`）。`_` は「project なしが意図的」であることを明示するマーカー
- サブプロジェクト: 既存 issue から使われている語彙を探し、合うものがあればそれを使う。なければ新しく作る
- 動詞: 同上。既存の用例を参考にしつつ、意味が合う動詞を選ぶ
- 対象: 具体物
- kebab-case、日付プレフィックスなし

命名時は `ls 00_issues/` と `find 00_issues/ -name "*.md"` で既存の名前パターンを確認してから決める。

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

4 セクションで構成する。

- 💧 進行中: いま考えていること、迷っていること、判断
- 🌂 中断点: 戻ってきた時の「いまどこ」
- ☔ TODO: タスク分解したチェックリスト（完了したら `[x]`）
- 🪣 経緯: 過去の 💧/🌂 と会話文脈を合わせた経過記録

💧/🌂 は常に最新状態を上書きする。
上書きする際、旧内容を 🪣 経緯に降ろしてから新しい状態で上書きする。

emoji は llm-wiki-kit の世界観（水・雨・傘・バケツ）に揃える。
複雑なタスクは追加セクション（背景・選択肢・着地イメージ等）を足してよい。

☔ TODO を書く時は、タスク種別に対応する guide（`00_issues/.guide/`）があれば該当する行をコピーして使う。
guide はタスク種別ごとに「毎回やること」を持つメニューで、issue 側は固有の作業だけを書けばよくなる（[[lw-kit-詳細設計-guide]]）。

短期 issue と長期 issue の差は TODO の粒度で表現する（軽量タスクなら 1〜3 行、重量タスクなら Phase 分けや並行進行マーク）。
💧/🌂/☔ セクション自体は省略しない（戻ってきた時に「TODO 無し = 完了」と誤読しないため）。
🪣 経緯は初回更新時に自動追加される（起票時点では無くてよい）。

### 🪣 経緯のフォーマット

- 位置: ☔ TODO の後、関連の前
- エントリ形式: `### YYYY/MM/DD (曜) HH:MM` + 空行 + 本文（複数行 OK）
- 空行必須: `###` 見出しの下に空行を入れる（markdownlint MD022 対策）
- 順序: 新しいエントリが上（新しい順。戻ってきた時に最新の経緯が最初に目に入る）
- 更新ポリシー: append 基調だが更新 OK（typo 直し・表現整理・補足追記は自由）。`log.md` の append-only とは別物
- 内容: 旧 💧/🌂 の内容だけでなく、会話で議論・決定・調査したことも含めて「このセッションで何が起きたか」を書く。書き方は LLM の裁量に任せる

## 多重数

実用上は 3〜5 並行が限界。
それ以上は「並行」じゃなく「保留」状態なので `.00_icebox/` に mv する。

| 段階      | 状態                    | 置き場                      |
| --------- | ----------------------- | --------------------------- |
| 1〜3 並行 | 全部頭に入る            | `00_issues/` 直下にフル詳細 |
| 4〜5 並行 | 切り替え時に issue 読む | `00_issues/` 直下に要点だけ |
| 6 以上    | 「保留」状態            | `.00_icebox/` に mv         |

## インデックス 3 ファイル

旧 `TODO.md` / `ICEBOX.md` の役割を 3 ファイルに分けて引き継ぐ。
各セクション内はカテゴリ（上記）でサブ分類する。

- `0_icebox.md` — 🧊 ICEBOX（いつか降らせたいもの）
- `1_issues.md` — ☔ WIP（いま滴っているもの）/ 🌂 TODO（次に降る予定のもの）
- `2_done.md` — 🌈 FIXED（光が差したもの）/ 🌫️ FADED（降らなかったもの）

## ライフサイクル

1. **起票**: 「これやろう」と思ったら `00_issues/<name>.md` を作り、`1_issues.md` に登録する
2. **作業中**: 中断時に「いまどこ」を書く
3. **完了**: 内容を三分法で仕分けてから状態遷移する
4. **廃棄**: 採用しなかった場合、`.99_faded/` に mv する

### 完了時の三分法

issue を閉じる前に、内容を 3 種類に仕分ける:

- 永続的な指針・知識・決定 → 関連 wiki page に書き戻す（必須）
- issue としての作業ログ（判断過程・選択肢比較・着手順・採用判断）→ `.90_fixed/` に mv して保持（issue tracker 代替）
- 一時的な作業計画・進捗・中断点メモ → 上 2 つの過程で取り上げ済みなので、issue 本体は通常通り保持

判断過程・選択肢比較は wiki に書き戻すには文脈依存が強すぎるが、捨てるには価値がある中間ゾーン。
issue を「closed issue」として保持することでこの中間ゾーンの居場所を作る。

## 関連

- [[LLM-Wiki]] — 中断耐性の弱さを補う
- [[lw-kit-詳細設計-guide]] — ☔ TODO に流し込むワークフローのメニュー
- 状態管理 + skill 化の設計経緯はワークスペース側の issue に残る（kit には含まれない）
