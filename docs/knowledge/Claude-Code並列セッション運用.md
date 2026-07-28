---
type: synthesis
tags: [claude-code, worktree, parallel-session, git, operations]
sources:
  - "[[git-worktree]]"
  - https://code.claude.com/docs/en/worktrees
created: 2026-05-30
updated: 2026-05-30
---

# Claude-Code並列セッション運用

[[git-worktree]] の上に Claude Code が提供する worktree 機能と、それを使って複数 session を物理的にぶつけずに並走させる運用。
狙いは編集ファイルが衝突しないこと、すなわち各 session に独立した作業ツリーを与えること。
[[Claude-Code-Agent-Teams]] が「1 つの作業ツリーを lead + teammates が共有して協調」する並列モデルなのに対し、worktree は「作業ツリーそのものをレーンごとに分ける」並列モデルで、両者は競合点の出方が逆になる。

## Claude Code の worktree 機能

`claude --worktree <name>`（`-w`）で worktree を自動生成し、隔離 session を立てる。
名前を省くと自動生成される（例: `bright-running-fox`）。
デフォルト配置は `.claude/worktrees/<name>/`、ブランチ名は `worktree-<name>`。
初回利用前に通常の `claude` を一度起動して workspace trust dialog を通す必要がある。

base branch は既定で `origin/HEAD`（remote の default branch）。
remote 未設定または fetch 失敗時はローカル `HEAD` にフォールバックする。
ローカル `HEAD` を常に base にするには `settings.json` の `worktree.baseRef` を `"head"` にする（取りうる値は `"fresh"` / `"head"` の 2 値のみ、任意の git ref は指定不可）。
PR から切る場合は `claude --worktree "#1234"` で `origin` から `pull/1234/head` を fetch し `.claude/worktrees/pr-1234` に配置する。

worktree は fresh checkout なので untracked / gitignored ファイル（`.env` 等）は持ち込まれない。
プロジェクト root に `.worktreeinclude` を置くと、`.gitignore` syntax にマッチしかつ gitignored なファイルだけが新規 worktree にコピーされる（tracked ファイルは複製しない）。
非 git VCS（SVN / Perforce / Mercurial 等）には `WorktreeCreate` / `WorktreeRemove` hook で対応するが、この経路では `.worktreeinclude` は処理されないのでファイルコピーは hook 内で実装する。

### subagent isolation

会話中に「use worktrees for your agents」と頼むか、custom subagent の frontmatter に `isolation: worktree` を付けると、subagent ごとに一時 worktree が作られる（[[Sub-Agent]]）。
変更がなければ subagent 終了時に自動削除される。

### cleanup の挙動

- 変更なし & untracked なし & 新規 commit なし → 自動削除
- 名前付き session は確認 prompt
- 変更あり → 残すか削除するか確認
- `-p`（非対話実行）+ `--worktree` → 自動 cleanup されない。`git worktree remove` で手動削除

クラッシュや中断で orphan 化した subagent worktree は `cleanupPeriodDays` 経過後に sweep される（変更なし条件）。
`--worktree` で作った named worktree はこの sweep の対象外。
依存関係のインストール（`npm install` 等 / venv 作成等）は worktree ごとに必要になる。

## 並列運用の指針

[[git-worktree]] 一般の指針（モジュール単位で切る / rebase / session 境界 commit / 並列数 2-4）に加え、Claude Code 特有の運用:

- `.claude/worktrees/` を `.gitignore` に追記し、メイン checkout 側で worktree 内ファイルが untracked として見えないようにする。
- レビュー session の heartbeat: 並列で走らせる時、定期的に `git fetch --all` を打って sibling worktree の新規 commit を引き込む session を別建てすると、相互参照のずれが減る。

## llm-wiki での適用

並列レーンで本当に競合するのは「両レーンが書く同じファイル」だけ。
SSOT ファイルの衝突耐性は性質によって分かれる。

- `log.md`: 末尾追記オンリー。`.gitattributes` に `merge=union` を指定すれば rebase / merge 時に両ブランチの追加行を全部残して自動マージできる。`merge=union` は重複を消さず並び順も保証しないが、append-only ログとは相性が良い。
- `index.md`: セクション構造を持つため `merge=union` だと重複 entry が出やすい。対象外にして統合（rebase / merge）時に手で見る。
- wiki page 本体 / `issue.md`: 意味的衝突になり自動マージ不可。同じ page を 2 レーンに触らせないレーン設計で守る側。

レーン分けの判定軸はファイル衝突だけでなく lead の認知負荷も入れる。
毛色の近い作業（例: skill ドキュメント現役化と worktree 運用試運転のような「運用メタ」同士）を並列にすると、ファイルが分かれていても lead の頭の中で混線し、同じ SSOT を両レーンが触る事故も起きやすい。
意味的に遠い作業同士を並列に置く。

`merge=union` は git の merge / rebase が挟まる時だけ働き、同一作業ツリー内の同時編集には効かない点に注意する。
worktree は `HEAD` から fresh checkout されるので、untracked / 未 commit の素材（`/lw-render` 対象の raw 等）は worktree に来ない。
並列レーンに渡したい変更は先に commit してから worktree を切る。
依存物コピーの観点では llm-wiki は `.env` 等の untracked 設定が薄く、`.worktreeinclude` の活用余地は少ない。

統合後の後片付けは `git worktree remove` で行う（llm-wiki 既定は線形 log を保つため rebase 統合）。

## 関連

- [[git-worktree]] — 土台となる git 機構
- [[Sub-Agent]] — `isolation: worktree` で同じ機構を subagent ごとに使う
- [[Claude-Code-Agent-Teams]] — 作業ツリー共有型の並列モデル（worktree とは競合点の出方が逆）
- [[Agent-Teams運用パターン]] — 共有型並列を回すときの実践パターン
