---
type: project
tags: [llm-wiki-kit, architecture]
sources:
  - conversation
created: 2026-07-20
updated: 2026-07-28
---

# llm-wiki-kit のディレクトリ構成

llm-wiki-kit（`~/project/wiki/llm-wiki-kit/`）のディレクトリ構成。

## ディレクトリツリー

```
llm-wiki-kit/
├── templates/                 ← setup.sh が cp する範囲 = lw-sync の対象
│   ├── .claude/
│   │   ├── CLAUDE.md
│   │   ├── rules/
│   │   │   ├── wiki.md
│   │   │   ├── wiki-style.md
│   │   │   ├── project.md
│   │   │   ├── issue.md
│   │   │   └── skeleton-confirm.md
│   │   ├── skills/
│   │   │   ├── lw-research-doc/
│   │   │   ├── lw-render/
│   │   │   ├── lw-update-issue/
│   │   │   ├── lw-create-issue/
│   │   │   ├── lw-commit/
│   │   │   ├── lw-retro/
│   │   │   ├── lw-lint/
│   │   │   ├── lw-archive-weekly/
│   │   │   ├── lw-tdd/
│   │   │   ├── lw-code-review/
│   │   │   ├── lw-doc-review/
│   │   │   ├── lw-fix-review/
│   │   │   └── lw-cmux-teams/
│   │   ├── agents/
│   │   └── settings.json
│   ├── 00_issues/
│   │   ├── .guide/               dev-guide.md（issue の TODO に流し込む手順のメニュー）
│   │   ├── tutorial-01-first-wiki.md
│   │   ├── tutorial-02-review.md
│   │   ├── tutorial-03-graduation.md
│   │   ├── tutorial-04-weekly.md
│   │   ├── .00_icebox/
│   │   ├── .10_todo/
│   │   ├── .90_fixed/
│   │   └── .99_faded/
│   ├── 10_raw/
│   ├── 20_library/
│   │   └── library.md
│   ├── 30_wiki/
│   │   └── .doc-review.md
│   ├── 40_project/
│   ├── 50_feedback/
│   │   └── （テンプレ）
│   ├── 90_reports/
│   │   └── weekly/
│   ├── .prettierrc
│   ├── .prettierignore
│   ├── .gitignore                ワークスペース用
│   ├── .gitattributes
│   ├── .markdownlint-cli2.yaml
│   ├── lefthook.yml
│   ├── package.json
│   ├── index.md
│   ├── log.md
│   ├── 0_icebox.md
│   ├── 1_issues.md
│   └── 2_done.md
├── docs/                          ← 参考資料（cp 対象外）
│   ├── lw-kit/                    kit 自身の設計書群
│   ├── dev-methodology/           開発手法の設計書
│   └── knowledge/                 kit を理解するための wiki（手動 cp で取り込む）
├── setup.sh
├── .gitignore                     llm-wiki-kit 用（templates/ 内のものとは別）
├── LICENSE
└── README.md
```

llm-wiki-kit のルートには kit 自身の管理用ファイルのみ置く。
kit 自身の開発で Claude Code を使う場合、kit ルートに別途 `.claude/` を作る（templates/ 内のものとは独立）。

## 各ディレクトリの役割

### `templates/`

`setup.sh` がワークスペースに cp するファイル群。
`.claude/` / dotfiles / `package.json` 等すべてこの中に含む。
このディレクトリの内容 = cp 対象 = lw-sync の対象。
`templates/` ディレクトリ自体はワークスペースにコピーされない（中身がルートに展開される）。

空ディレクトリ（`10_raw/` / `40_project/` 等）は `.gitkeep` で git に追跡させる。

ワークスペース用 `.gitignore` は `20_library/books/`（PDF 実体）を除外する。
蔵書機能を使えば必ず作られるディレクトリで、自炊 PDF は 1 冊で数十 MB になる。
ignore を忘れて commit すると履歴に残り、消すには履歴書き換えが必要になる。

### `docs/`

参考資料。`setup.sh` の cp 対象には含めない。

- `docs/lw-kit/` — kit 自身の設計書群（要件定義 / repo 構造 / チュートリアル設計等）
- `docs/dev-methodology/` — 開発手法の設計書（TDD / AI 駆動開発 / ガードレール設計等）
- `docs/knowledge/` — kit を理解するための wiki。ユーザーが手動で cp してワークスペースの `30_wiki/` に取り込む。knowledge 集合内の `[[link]]` と `docs/lw-kit/` の設計書への `[[link]]` は温存する（kit を Obsidian vault として開いた時のナビゲーションを優先）。それ以外の集合外への参照は平文に戻す

### `docs/knowledge/` を取り込む時

必要な page だけを `30_wiki/` に cp する。
取り込んだ page が `docs/lw-kit/` の設計書を `[[link]]` で指している場合、ワークスペース側には実体がないので解決しなくなる。

対処は 2 つ。どちらでもよい。

- 参照が要るなら `[[link]]` を `$KIT/docs/lw-kit/...` のパス表記に書き換える（`$KIT` はワークスペースの `CLAUDE.md` で定義済み）
- 参照が要らないなら行ごと落とす

kit 側で最初からパス表記にしない理由は [[lw-kit-ガイド設計-skill-guide]]「決定」セクションを参照。

## テンプレフォルダの境界

`templates/` 配下のファイルが `setup.sh` の cp 対象であり、`lw-sync` の対象でもある。
この境界はディレクトリ構造で表現する（manifest ファイルは持たない）。

`docs/` は cp 対象外。

## settings.json 設計方針

kit の `settings.json` に含める項目:

- skill の permission 設定（`lw-*` skill が使う tool の allowlist）
- 汎用的な Bash permission（`git` / `find` / `grep` 等）

含めない項目（マシン固有 / 個人固有、`settings.local.json` で管理）:

- API キー関連
- パス固有の設定
- 個人の好み設定（auto memory で管理すべきもの）
