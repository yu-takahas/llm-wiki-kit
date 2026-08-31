---
type: project
tags: [llm-wiki-kit, architecture]
sources:
  - conversation
created: 2026-07-20
updated: 2026-08-31
---

# llm-wiki-kit のディレクトリ構成

llm-wiki-kit（`~/project/wiki/llm-wiki-kit/`）を今の構成にした理由。

**本ページは構成上の決定根拠のみを持つ。**
ディレクトリとファイルの実体は repo が正本で、本ページに写さない。

## ルートに置くもの

llm-wiki-kit のルートには kit 自身の管理用ファイルのみ置く。
kit 自身の開発で Claude Code を使う場合、kit ルートに別途 `.claude/` を作る（`templates/` 内のものとは独立）。

## テンプレフォルダの境界

`templates/` 配下のファイルが `setup.sh` の cp 対象であり、`lw-sync` の対象でもある。
この境界はディレクトリ構造で表現する（manifest ファイルは持たない）。

`templates/` ディレクトリ自体はワークスペースにコピーされない（中身がルートに展開される）。
`.claude/` / dotfiles / `package.json` 等も、配る以上はこの中に入る。

`docs/` は cp 対象外。
何を配るかの選定基準は [[lw-kit-基本設計-スターターテンプレ]] が持つ。

空ディレクトリ（`10_raw/` / `40_project/` 等）は `.gitkeep` で git に追跡させる。

## ワークスペース用 `.gitignore` が PDF を除外する理由

`20_library/books/`（PDF 実体）を除外する。
蔵書機能を使えば必ず作られるディレクトリで、自炊 PDF は 1 冊で数十 MB になる。
ignore を忘れて commit すると履歴に残り、消すには履歴書き換えが必要になる。

## `docs/knowledge/` を取り込む時

必要な page だけを `30_wiki/` に cp する。
取り込んだ page が `docs/lw-kit/` の設計書を `[[link]]` で指している場合、ワークスペース側には実体がないので解決しなくなる。

対処は 2 つ。どちらでもよい。

- 参照が要るなら `[[link]]` を `$KIT/docs/lw-kit/...` のパス表記に書き換える（`$KIT` はワークスペースの `CLAUDE.md` で定義済み）
- 参照が要らないなら行ごと落とす

kit 側で最初からパス表記にしない理由は [[lw-kit-ガイド設計-skill-guide]]「決定」セクションを参照。
knowledge 集合内の `[[link]]` と `docs/lw-kit/` の設計書への `[[link]]` を温存するのは、kit を Obsidian vault として開いた時のナビゲーションを優先するため。
集合外への参照だけ平文に戻す。

## settings.json 設計方針

配るかどうかの軸は「どの環境・どの利用者でも同じ値になるか」。
kit の skill 群はどの環境でも同じコマンドを使うので、その permission は値が変わらず配れる。
作業用ディレクトリへのアクセス許可も、パスが固定なら同じ理由で配れる。

配らないものは、なぜ同じ値にならないかで行き先が 3 つに分かれる。
軸は配る / 配らないを決めるだけで、行き先までは決めない。

- 環境ごとに違う（パス固有の設定）→ `settings.local.json`
- 利用者ごとに違う（個人の好み）→ auto memory の管轄（[[lw-kit-詳細設計-CLAUDE.md]]「層の使い分け」）
- 値そのものを配ってはいけない（API キー関連）→ どこにも置かない（[[lw-kit-要件定義]] の非機能要件「秘匿情報の排除」）

実際に何が入っているかは `templates/.claude/settings.json` が正本。

## 関連

- [[lw-kit-基本設計-スターターテンプレ]] — 配布物の選定基準
- [[lw-kit-詳細設計-setup.sh]] — 配布の実行
