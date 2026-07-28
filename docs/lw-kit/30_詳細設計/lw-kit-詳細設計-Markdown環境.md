---
type: synthesis
tags: [llm-wiki-kit, markdown, lint, formatter, environment]
sources:
  - conversation
  - 10_raw/20260211_markdown環境整備のアイデア.md
created: 2026-02-11
updated: 2026-07-07
---

# llm-wiki-kit の Markdown 環境

llm-wiki-kit ワークスペースの Markdown 品質管理ツールの構成と設定判断。

## 現在の構成

- パッケージマネージャ: npm
- lint: `markdownlint-cli2` — `npm run lint:md`（チェック） / `npm run lint:md:fix`（修正）
- format: `prettier` — `npm run format`（チェック） / `npm run format:fix`（修正）
- pre-commit hook: `lefthook` — `npm install` 時に `prepare: lefthook install` で自動登録

設定ファイルの実体は `.markdownlint-cli2.yaml` / `.prettierrc` / `.prettierignore` / `lefthook.yml` / `package.json` を参照。

script の命名規約は無印 = チェック（安全）、`:fix` = 修正（危険）。
フールプルーフのため、修正を伴う script は必ず `:fix` を明示する。

## ツール選定

| ツール            | 採用 | 理由                                            |
| ----------------- | ---- | ----------------------------------------------- |
| markdownlint-cli2 | ✅   | lint。`markdownlint-cli` の後継版               |
| prettier          | ✅   | format。責務分離 + 保存時自動 lint 環境との整合 |
| lefthook          | ✅   | pre-commit hook。Markdown 用途の 2 ジョブ構成   |
| simple-git-hooks  | ❌   | lefthook に置き換え                             |
| pnpm              | ❌   | npm に置き換え                                  |
| bun               | ❌   | npm に置き換え                                  |

各ツールの設定判断は以下のセクションに集約する。

## markdownlint-cli2

設定ファイル形式は yaml を採用。
chatai は jsonc だが、llm-wiki-kit では日本語コメントとの相性で yaml の方が読みやすい。

### ignore の判断

- `github/**`: 外部リポ取り込み（[[claude-obsidian]] / [[karpathy-wiki]] / llm-wiki-gist / [[llmwiki]] / [[wiki-skills]] / claude-code-leak）。
  参照資料として持ち込んだもので、こちら側で書式を直す筋ではない。
- `10_raw/**`: gitignore 済みの思考素描領域。
  lint 対象外が運用方針。
- `node_modules/**`: cli2 のデフォルト除外。
  設定ファイル化のタイミングで明示しておく。

### disable の根拠

chatai/ui_be_with_me（同じく日本語ナンバリングディレクトリ運用の書籍プロジェクト）の disable をベースに、llm-wiki-kit 固有の事情で追加。

| ルール                     | 根拠                                                                                                           |
| -------------------------- | -------------------------------------------------------------------------------------------------------------- |
| MD001 heading-increment    | 見出しレベルを部分的に飛ばす運用を許容                                                                         |
| MD009 trailing-space       | 行末 2 スペース改行を使う場面を許容                                                                            |
| MD012 multiple-blanks      | 連続空行を許容                                                                                                 |
| MD013 line-length          | 日本語の自然な行長を阻害するため（80 字制限は CJK 不適）                                                       |
| MD024 no-duplicate-heading | 対話ログで `# you asked` / `# gemini response` が H1 として連発する運用、`siblings_only` でも吸収しきれない    |
| MD025 single-h1            | 対話ログでの話者見出し + frontmatter title と本文 H1 のダブルカウント                                          |
| MD026 trailing-punctuation | `？` を含む見出しを許容                                                                                        |
| MD028 blanks-in-blockquote | blockquote 内の発言者切り替えで空行を使う                                                                      |
| MD029 ol-prefix            | 順序リスト番号を連番強制しない。`20_library/` の目次で章ごとにリセットする `- 1. xxx` 形式を許容               |
| MD032 blanks-around-lists  | リスト前後の空行を強制しない。順序リストと箇条書きの混在（`- はじめ` → `- 1. xxx` → `- ステップアップ`）を許容 |
| MD033 inline-html          | Obsidian の `<br>` / callout / `<name>` 等で使う                                                               |
| MD034 no-bare-urls         | bare URL 許容。`<>` 囲みを強制すると vim yank 時の visual 選択が面倒                                           |
| MD036 emphasis-as-heading  | raw の生メモで太字見出し代用が頻出                                                                             |
| MD037 no-space-in-emphasis | glob パターン `**` を強調マーカーと誤検出する fix の副作用を防ぐ                                               |
| MD040 fenced-code-language | レビュー引用やディレクトリツリー等で言語指定なしを許容                                                         |
| MD041 first-line-h1        | frontmatter があるので最初の行は H1 にならない                                                                 |

## prettier

### 採用理由

- 責務分離: フォーマットは linter ではなくフォーマッタにやらせるのが筋
- Web 標準: front 周りで prettier は標準ツール、入れるのを標準にしたい
- 保存時自動 lint との整合: VSCode / Neovim で保存時 lint 自動実行モードを入れたため、フォーマッタも整える流れ
- 決定打: `proseWrap: "preserve"` で「文は `。` ごとに改行」運用が破壊されないと判明（chatai/ui_be_with_me で検証済み）
- markdownlint との責務衝突なし: 全体 format 後も `npm run lint:md` で 0 件維持を確認

### 主要オプション

| 選択肢                                       | 根拠                                                                                                                                                                                                                       |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `proseWrap: "preserve"`                      | 「文は `。` ごとに改行」運用が prettier の自動折り返しで破壊されないようにする決定打                                                                                                                                       |
| `printWidth: 120`                            | code block の標準幅、Markdown の自然な行長と整合                                                                                                                                                                           |
| `embeddedLanguageFormatting: off` (md only)  | コードブロック内の TS / JS / YAML 等を勝手に整形しない（コード例の意図を保つ）                                                                                                                                             |
| `.obsidian/` ignore                          | 必須。Obsidian プラグインの minified js を整形すると 10 万行展開される事故のため                                                                                                                                           |
| `10_raw/` ignore                             | raw 取り込み領域（gitignore 済みの素描・調査資料）なので整形対象外                                                                                                                                                         |
| `--log-level warn` (`format` / `format:fix`) | prettier がデフォルトで吐く全ファイル列挙（repo 全体 280 件超の `(unchanged)` 行）が `/lw-commit` 先叩き時に context window を埋めるのを防ぐ。書き換えたファイルと警告 / エラーは残るので差分確認・lint 把握は損なわれない |

### 運用上の落とし穴

導入時に実害として踏み抜いた注意点。今後 prettier を扱うときに参照する。

| 落とし穴                                | 症状                                                                                                                                                                                                      | 対処                                                                                                                                                                                                                   |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| emphasis 正規化（双方向）               | `_xxx_` → `*xxx*` も `*xxx*` → `_xxx_` も発生。`20260303_山田太郎_転入届` → `20260303*山田太郎*転入届`、本文中の `Bash(rm *), Bash(mkdir *)` → `Bash(rm _), Bash(mkdir _)` のように意味やコマンドが壊れる | `_` や `*` を含む識別子・パス・glob・コマンド例示は必ずコードスパン化（`` ` `` で囲む）。CLAUDE.md の文書規約（[[lw-kit-詳細設計-CLAUDE.md]]）に明文化済み。frontmatter (YAML) 内の `*` は対象外なのでコードスパン不要 |
| ネストしたコードフェンスの 4 BT 副作用  | ` ```markdown ` 内に ` ```bash ` がある場合、外側を ` ```` ` (4 BT) に正しく昇格するが、副作用で同ファイル内の独立した他のコードブロックの閉じも 4 BT 化されて構造が壊れる                                | 手動で各閉じフェンスを正しい BT 数に戻す（内側 3 BT、独立ブロック 3 BT、外側ネスト元だけ 4 BT）                                                                                                                        |
| `.obsidian/` plugin の minified js 展開 | 初回 `npm run format` で plugin の minified js が 10 万行展開され 25.5 万行 insertion 発生                                                                                                                | `.prettierignore` に `.obsidian/` を必ず含める                                                                                                                                                                         |
| 保存時 prettier auto-format との衝突    | VSCode / Neovim で保存時 prettier 自動実行を有効にしていると、Claude Code の Edit が立て続けに走るとき「File has been modified since read」が連続発生する                                                 | 連続 Edit する場合は 1 つずつ実行する、または Read してから Edit を直列化する                                                                                                                                          |

## lefthook

### 採用理由

- 強制力のあるバックアップ: 保存時 auto-format は editor 設定依存、lefthook なら commit 時に確実に整形 + lint チェックがかかる
- push 禁止規約と衝突しない: pre-commit 局所、push hook は使わないので CLAUDE.md の push 禁止と整合
- 2 ジョブで足りる: chatai の Markdown 用 2 ジョブ構成を流用。nano-code のフル構成（lint / typecheck / test / gitleaks + commitlint）は Markdown 用途にはオーバースペック

### 2 ジョブ

pre-commit のみ、push hook は使わない。

| ジョブ  | 内容                                                         | 失敗時の挙動                                                 |
| ------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| format  | staged の `*.md` に対して `npx prettier --write` + `git add` | エラー時 commit ブロック（通常は自動修正で続行）             |
| lint:md | staged の `*.md` に対して `npx markdownlint-cli2` チェック   | 違反検出時 commit ブロック、`npm run lint:md:fix` で手動修正 |

### hook は project-pin のローカル版を使う

lint / format ジョブは `npx markdownlint-cli2` / `npx prettier` で呼ぶ。
`npx` 経由だと `node_modules` の project-pin 版（`package.json` 記載）を叩く。
裸の `markdownlint-cli2` で呼ぶと PATH 上の global（`npm install -g` 由来）を拾い、`npm run lint:md`（npm script = `node_modules/.bin` 優先のローカル版）と version がずれる。
この場合、global が先行して新 rule（例: MD060 table-column-style）を持つと、ローカル `npm run lint:md` が 0 error でも hook だけ commit を弾く（proxy が本物のゲートと食い違う）。
hook をローカル版に固定することで version を `package.json` に一元管理し、`npm run lint:md` を pre-commit の忠実な proxy にする。

## 関連

- [[lw-kit-詳細設計-CLAUDE.md]]: Git 規約や運用ルール
