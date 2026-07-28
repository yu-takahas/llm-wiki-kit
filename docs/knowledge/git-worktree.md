---
type: entity
tags: [git, worktree, version-control, parallel]
sources:
  - https://git-scm.com/docs/git-worktree
created: 2026-05-30
updated: 2026-05-30
---

# git-worktree

1 つのリポジトリに複数の作業ディレクトリをぶら下げる git の機能。
オブジェクト DB と refs を共有したまま、`HEAD` / index / 作業ファイルだけを作業ツリーごとに独立させる。
ブランチを切り替えずに別ブランチの作業を物理的に別ディレクトリで並行できるのが本質。

## 共有されるもの / 独立するもの

リポジトリ全体で共有:

- オブジェクト DB（`.git/objects`）
- 参照（`refs/heads/*` / `refs/tags/*`）
- 設定（`.git/config`）

worktree ごとに独立:

- `HEAD`
- index（staging area）
- `refs/bisect/*` / `refs/worktree/*` / `refs/rewritten/*`

同一ブランチを 2 つの worktree で同時 checkout はできない（`--force` で上書き可だが非推奨）。
index の整合性を守るための仕様。
worktree 固有設定は `git config extensions.worktreeConfig true` を有効化したうえで `git config --worktree <key> <value>` で持たせる。

## 主要サブコマンド

- `git worktree add <path> [<commit-ish>]` — 作業ツリー追加。`-b <branch>` で新規ブランチ、`-B` で既存ブランチ強制リセット、`-d` で detached、`--orphan` で未生成ブランチ、`--no-checkout` で checkout 抑制、`--lock` でロック状態作成。`path` 末尾名が自動でブランチ名になる。
- `git worktree list` — 一覧。`-v` で verbose、`--porcelain` でスクリプト向け。
- `git worktree remove <worktree>` — 削除。`-f` で未追跡ファイルあっても、`--force --force` でロック済みも削除。
- `git worktree lock / unlock` — 可搬デバイスや network share 上の worktree を自動 prune から守る（`--reason` で理由付与）。
- `git worktree move <worktree> <new-path>` — 移動。submodule を含む worktree は移動不可。
- `git worktree prune` — 手動削除された worktree の管理データを掃除（`-n` で dry run、`--expire <time>` で期限指定）。
- `git worktree repair` — メインまたはリンクを `mv` で移動した後の接続復旧。

他 worktree の `HEAD` は `git rev-parse main-worktree/HEAD` / `git rev-parse worktrees/<name>/HEAD` で参照する。

## 典型ユースケース

- 緊急修正中の作業継続: 本流を触らず `git worktree add -b hotfix ../hotfix master` で別ツリーに hotfix を切り、終わったら `git worktree remove`。
- 複数機能の並行開発: 機能ごとに `git worktree add -b <feat> ../<feat>` で別ツリーを立てる。

## 並列運用の指針

git worktree を並列開発に使うときコミュニティで定着している指針:

- モジュール単位で切る、タスク単位では切らない。同モジュール内の複数タスクは同一 worktree で逐次、別モジュールにまたがる時だけ並列にすると編集衝突を物理的にゼロにできる。
- worktree 間の同期は merge でなく rebase。merge commit を作らない方が `git log` が線形で読みやすい。
- session 境界で commit する。未 commit 状態は失われやすい唯一の状態なので tiny に保つ。
- 並列数は 2-4。5+ は破綻しやすく、staggered start で運用するのが現実的。

## 統合（merge / rebase）

並列レーンの成果を統合先ブランチに取り込むときの手順。

- 統合先がまだ動いていなければ `git merge <worktree-branch>` は fast-forward で済む。merge commit も衝突も出ない。
- 2 本目以降のレーンは統合先が進んだ後なので、各 worktree で `git rebase <統合先>` してから merge する。先に commit した方を fast-forward で取り込み、もう片方を rebase する順。
- レーンが単一 commit なら、rebase + merge の代わりに統合先で `git cherry-pick <commit>` でも線形に取り込める。別 worktree に checkout 中のブランチでも本体側から実行でき、merge commit も作らない。
- 取り込む前に `git merge-tree --write-tree <統合先> <worktree-branch>` で衝突を予測できる。exit 0 かつ衝突マーカーが出なければ自動マージで済む。
- 衝突が出るのは両レーンが触った同じファイルだけ。レーン設計で被りを避けていれば統合はほぼ自動で済む。
- 統合後の片付けは `git worktree remove <path>` + `git branch -d <branch>` の 2 つ。ただし自分がいま入っている worktree は remove できない（その worktree が cwd になっているため）。close は本体か別の worktree から行う。

llm-wiki の SSOT（`log.md` を `merge=union`、`index.md` は手で見る）まわりの扱いは [[Claude-Code並列セッション運用]] の「llm-wiki での適用」を参照。

## worktree の繋がりと保守

worktree と本体リポジトリは絶対パスのリンクで相互参照している。
本体側は `.git/worktrees/<name>/` に worktree の場所を、worktree 側は `.git`（ディレクトリでなくファイル）に本体の場所を記録する。
このため worktree や本体のフォルダを `mv` するとリンクが切れる。
`repair` / `lock` / `prune` はこの繋がりまわりの事故を直す・防ぐための保守コマンドで、構文は「主要サブコマンド」を参照。

- repair: 切れたリンクの繋ぎ直し。`git worktree move` を使わず手で `mv` してしまった時の救済。正規の `move` を使えばリンクは自動更新されるので本来は不要。
- lock / unlock: 一時的に見えなくなる worktree（外付けドライブや network share 上で、抜いた / マウントが外れた間）を `prune` の自動削除から守る、およびその解除。`--reason` は後で理由を思い出すためのメモ。
- prune: 手動削除した worktree の管理データ残骸（`.git/worktrees/<name>/`）を掃除する。lock された worktree は対象外になる。

これらの出番はローカルで `.claude/worktrees/` 配下に worktree を置き `remove` で正規に片付ける運用ならほぼ無い（手で `rm` した・フォルダを `mv` した時だけ踏む）。

## llm-wiki での参照

- [[Claude-Code並列セッション運用]] が Claude Code の `--worktree` 統合と llm-wiki 運用論の土台として参照する。
- subagent の `isolation: worktree`（[[Sub-Agent]]）も同じ機構の上に立つ。
