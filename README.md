<img src="assets/llm-wiki-kit-logo-loop.webp" alt="llm-wiki-kit" width="324">

# llm-wiki-kit

![Requires Claude Code](https://img.shields.io/badge/requires-Claude_Code-D97757)
![Last commit](https://img.shields.io/github/last-commit/yu-takahas/llm-wiki-kit)
![License](https://img.shields.io/github/license/yu-takahas/llm-wiki-kit)

調べたことと決めたことを wiki に貯めて、Claude Code に読み書きさせるためのテンプレート。

会話で決めたことはコンテキストが切れると消えますが、wiki page に残しておけば次の会話で読み直せます。
調べたものを資料として保存する、資料を読んで wiki page にする、page 同士を `[[link]]` で繋ぐ、作業を issue で追う。
こうした手順を skill と rule として持っているので、Claude Code がそのまま実行できます。

コードだけでなく、設計書やナレッジ管理を LLM でやりたい場合の出発点として使えます。

## 動かすのに要るもの

- git
- node
- Claude Code 本体と、そのアカウント

この repo は public なので clone は誰でもできますが、動かすのは Claude Code です。
そのアカウントと課金は別に要ります。

`setup.sh` は git と node が無いとその場で止まります。
Claude Code は、セットアップの最後に起動するところで要ります。

## セットアップ

```bash
git clone https://github.com/yu-takahas/llm-wiki-kit.git
cd llm-wiki-kit
./setup.sh
```

デフォルトでは `~/wiki/my-wiki` にワークスペースが作られます。
別の場所に作りたい場合:

```bash
./setup.sh ~/path/to/my-wiki
```

`setup.sh` がやるのは、テンプレートのコピー、`git init`、依存のインストール、最初の commit までです。
最後に Claude Code が起動します。
起動せずに終わらせたい場合は `./setup.sh --no-launch` を使います。

## 最初にやること

チュートリアルの issue が 4 本入っています。
Claude Code が起動したら、こう話しかけると始まります。

```
00_issues/tutorial-01-first-wiki.md を読んで、チュートリアルを始めたい。最初のステップから案内して
```

| issue                    | やること                                      |
| ------------------------ | --------------------------------------------- |
| `tutorial-01-first-wiki` | テーマを 1 つ調べて、最初の wiki page を作る  |
| `tutorial-02-review`     | もう 1 本作り、レビューして直すサイクルを回す |
| `tutorial-03-graduation` | 自分のテーマで一通りを自走する                |
| `tutorial-04-weekly`     | wiki が溜まってきた頃のメンテナンスをする     |

Obsidian があると `[[link]]` を GUI で辿れます。
無くても全部動きます。

## ディレクトリ構造

```
00_issues/          進行中タスクのメモ。1 ファイルが 1 つの作業単位
10_raw/             調べたものを加工せず置く場所
20_library/         本の目次と PDF
30_wiki/            整理した知識。他の場面でも使い回せるもの
40_project/         案件ごとの wiki page
50_feedback/        Claude の振る舞いについての蓄積
90_reports/weekly/  週次アーカイブ
```

最初に触るのは `00_issues/` と `10_raw/` と `30_wiki/` です。
`10_raw/` に集めたものを読んで、使い回せる知識は `30_wiki/` へ、その案件でしか使わないものは `40_project/<案件>/` へ振り分けます。

残りは使いたくなった時に見れば足ります。

ルートには `index.md`（wiki のカタログ）、`log.md`（操作履歴）、`1_issues.md` / `2_done.md` / `0_icebox.md`（タスクの盤面）が置かれます。

## skill

`/lw-<name>` で起動します。

| skill                | 何が起きるか                                                                   |
| -------------------- | ------------------------------------------------------------------------------ |
| `/lw-research-doc`   | URL かキーワードを渡すと、調べて `10_raw/` に資料を作る                        |
| `/lw-render`         | `10_raw/` の資料を読んで、`30_wiki/` や `40_project/` に wiki page を作る      |
| `/lw-create-issue`   | 作業を `00_issues/` の issue として起票する                                    |
| `/lw-update-issue`   | issue の進行中・中断点・TODO を最新化し、前の状態を経緯に降ろす                |
| `/lw-commit`         | issue の最新化・盤面・`log.md` / `index.md` の更新をまとめてから commit する   |
| `/lw-doc-review`     | 文書を層別にレビューして、指摘をファイルに出す（修正はしない）                 |
| `/lw-fix-review`     | 指摘を反映し、再利用できる知見を `50_feedback/` に貯める                       |
| `/lw-code-review`    | 組み込みの `/code-review` を包み、指摘を `/lw-fix-review` が読める形で保存する |
| `/lw-tdd`            | テストシナリオごとに subagent を立てて Red-Green-Refactor を回す               |
| `/lw-lint`           | broken link・frontmatter 欠落・孤立 page を検査する（wiki は書き換えない）     |
| `/lw-archive-weekly` | 完了したタスクを `90_reports/weekly/` へ移し、盤面から下ろす                   |
| `/lw-retro`          | セッションを振り返り、観察と知見を `50_feedback/` に反映する                   |
| `/lw-cmux-teams`     | cmux 上で teammate を立ち上げ、並列作業や相談をする                            |

規約は `.claude/rules/` が持ちます。
対象のファイルを Claude Code が読んだ時に自動でロードされるので、こちらから呼ぶ必要はありません。

skill も rule もワークスペースの中にコピーされるので、自分の仕事に合わせて書き換えられます。

## もっと知る

- [takahas.dev/works/llm-wiki-kit](https://takahas.dev/works/llm-wiki-kit) — これは何か、なぜ作ったか、実際に何を載せているか
- `docs/lw-kit/lw-kit-アーキテクチャ設計.md` — 構造・ワークフロー・設計原則。他の設計書へはここから辿れます

## ライセンス

MIT License. 詳細は `LICENSE` を参照してください。
