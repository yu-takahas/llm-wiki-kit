---
type: synthesis
tags: [claude-code, CLAUDE.md, llm-wiki-kit, design]
sources:
  - conversation
  - "[[Claude-Codeのメモリ階層]]"
  - 10_raw/llm-wiki-kit/20260304_CLAUDE.md設計.md
  - https://platform.claude.com/docs/ja/build-with-claude/prompt-engineering/prompting-claude-opus-5
  - https://platform.claude.com/docs/ja/build-with-claude/prompt-engineering/claude-prompting-best-practices
created: 2026-03-04
updated: 2026-08-06
---

# llm-wiki-kit の CLAUDE.md 設計

llm-wiki-kit ワークスペース固有の CLAUDE.md / rules / skills 運用と、その背景にある設計判断。
[[Claude-Codeのメモリ階層]] が一般論、本ページは llm-wiki-kit での具体決定。

**本ページは決定根拠のみを持つ。** 書式・具体値・列挙は `.claude/CLAUDE.md` と各 rule が正本。

## 層の使い分け

置き場境界の判定は [[lw-kit-詳細設計-rules]]「責務分担」が正本で、本節は CLAUDE.md 視点の要約。

- `.claude/CLAUDE.md`: ワークスペース普遍ルール。何をどこで管理するかの index と、領域に紐づかない規約を持つ
- `.claude/rules/`: 領域別の規約。構成と設計指針は [[lw-kit-詳細設計-rules]] に集約
- `.claude/skills/`: 個別タスクのワークフロー
- auto memory: リポジトリ外（`~/.claude/projects/<エンコードしたパス>/memory/`）に置かれるユーザー個人の好み（commit type の選好、パッケージマネージャ、作業の進め方、報告の粒度等）。kit の配布対象には含まれない

### `$KIT` の定義

配布される `CLAUDE.md` は `$KIT`（llm-wiki-kit の場所）の定義行を持つ。
`setup.sh` が生成時に placeholder を clone 元の実パスに置換する（[[lw-kit-詳細設計-setup.sh]]）。

skill / guide / rules が設計書と規範を `$KIT/docs/...` で指すため、ワークスペース側に定義がないと参照が解決しない。
参照の書き分けの規約と判断の根拠は [[lw-kit-ガイド設計-skill-guide]]「決定」セクション。

## 他 page からの参照

他の設計記録・wiki page が CLAUDE.md を参照する時は、本 page（llm-wiki-kit の CLAUDE.md 設計）を経由する。
`.claude/CLAUDE.md` を直接指さない。
CLAUDE.md の構成（セクション追加 / リネーム / 分割）が変わったとき、直参照していた page の参照が一斉に壊れるのを防ぐため。
本 page が CLAUDE.md への参照を集約するハブになる。
rules も同じ構造で、[[lw-kit-詳細設計-rules]] がハブ。

ハブとして未完のところが 1 つある。
文書規約（コードスパン化 / `。` 改行 / `[[link]]` / 口語比喩の禁止）の決定根拠を本 page がまだ持っておらず、他 page からの参照がその受け皿を期待している状態にある（未決）。

## wiki link の解決

CLAUDE.md は `[[link]]` で書くことを指示するので、`[[Foo]]` から `Foo.md` を見つける手段も同じ場所に置く。
fresh session の Claude Code は `[[link]]` に初見で出会った時に解決手段を持たないため、`find` コマンドを明記して 1 手で辿れるようにする。

`index.md` を Read して一覧から探す方法は採らない。
一覧を丸ごと context に載せるコストに対して `find` 1 発の方が軽く、`index.md` は「何があるか」を知りたい時に読むもので link 解決には要らない。

名前だけで 1 件に特定できるのは、タイトルがワークスペース全体で一意であることが前提。
この前提が崩れると `find` は複数件を返し、解決手段として成立しなくなる。
一意性を担保する規定は rule にも lint にも無く、運用で保っている（未決）。

検索対象のディレクトリは CLAUDE.md のコマンドが持つ。
`[[link]]` で参照する置き場が増えたら、そのコマンドに足す。

## Git 規約の llm-wiki-kit 固有判断

- type の選好: kit は決めない。どの type を優先するかは利用者ごとに違うので auto memory 層に属する。CLAUDE.md が複数の type を並べているのはそのため
- project 命名で数字落としを採るのは、フラット運用との整合による（「1 つ下のサブディレクトリ名」を採ると、サブディレクトリを作らない方針と矛盾する）
- project 命名を主旨で決めるのは、「変更数最多」で決めると case 単位の作業の主旨が潰れるため
- ブランチ戦略: 作業ごとに新規ブランチを切る。配布物側に規範文は置いておらず、運用で保っている
- remote push 禁止: GitHub / Bitbucket / AWS CodeCommit いずれも、個人情報や secrets 混入リスクのため。担保は `setup.sh` が remote を設定しないことによる

## 出力量の規約

応答の量と作業中の報告のペースを `.claude/CLAUDE.md` が規定し、成果物の分量は `.claude/rules/wiki.md` が持つ。

kit の規約と skill は「書かないモデル」への対策として書かれてきたため、下限側の防御だけがあって上限側の規定が無かった。
モデルが自発的に書くようになると、この非対称がそのまま増幅器として働く。

置き場が 2 つに分かれるのは、応答とナレーションが領域に紐づかず `paths` で絞れないのに対し、成果物の分量は wiki page の本文制約に属するため。
文言はモデル提供元のプロンプティング資料の推奨文から採っている（frontmatter `sources:` 参照）。
資料が挙げる残り 2 種（タスクのスコープ / 自己修正）は Claude Code のシステムプロンプトが同等の文を持つので入れていない。

## 不採用にした設計選択

検討して採らなかった選択肢。同じ提案が再燃した時に「検討済み」と分かるよう残す。

- `related:` frontmatter フィールド: skill のリネームでパスが無効になる → 本文 `[[link]]` で代替
- CLAUDE.md へのカスタムスキル一覧記載: `.claude/skills/` に置けば Claude が認識する → 書かない
- overview.md（手動メンテの全体俯瞰ファイル）: [[claude-obsidian]] で 1 ヶ月放置の実証、人も LLM も触らない single point of failure → 廃止、ルート `index.md`（type 別 MOC）で代替
- wiki schema を wiki page として `30_wiki/` に置く: 毎セッション読まれて肥大する → `.claude/rules/wiki.md` の `paths` 条件付きロードが筋
- `status: seed/developing/evergreen` frontmatter: [[claude-obsidian]] で機能不全の実証 → 不採用
- `quality:` block（4 軸 rating）: [[karpathy-wiki]] でも personal scale には overkill → 不採用
- `.claude/CLAUDE.md` への旧 frontmatter テンプレ記載: schema は `wiki.md` の `paths` 条件付きロードに委ね、CLAUDE.md は誘導のみ

## 改訂指針

`.claude/CLAUDE.md` を将来改訂する時に従う方針。

- CLAUDE.md はワークスペース全体に必要な普遍ルールだけに絞る
- `30_wiki/` 配下の schema は `.claude/rules/wiki.md` が `paths` 条件付きで担う、CLAUDE.md には書き写さない
- サイズは [[Claude-Codeのメモリ階層]] のサイズ規律に従う（具体値は下の検算チェックリスト）
- 冗長な解説は wiki page に置き、CLAUDE.md は「何をどこで管理するかの index」に徹する
- 操作を誤らないための注意書き（`$KIT` の書き換えや削除時の影響のような、その場の判断に効くもの）は実物に残す。index に徹するのは管理の地図についてで、操作の指示は対象外
- 領域に紐づかない執筆・応答の規約は CLAUDE.md が持つ（`paths` で絞れないため rules に降ろすと常時ロードのファイルが増える）
- 詳細な手順や個別の決定根拠は実践ノウハウに沿って wiki page 側に置く

## 検算チェックリスト

CLAUDE.md を改訂した後、以下を確認する。

- 200 行未満か（[[Claude-Codeのメモリ階層]] のサイズ規律）
- 旧 schema（`created_at` / `updated_at` / `source` singular / `YYYYMMDD_` 等）の痕跡が残っていないか
- 「wiki / rules / skills の使い分け」が CLAUDE.md 単独で読み取れるか
- 詳細な解説が紛れ込んでいないか（紛れていれば wiki page へ移す）
- リスト項目の見出し的太字を多用していないか
- 本ページが実物の具体（コマンド・列挙・書式）を写していないか。写しは実物と一緒にずれる

## 関連

- [[Claude-Codeのメモリ階層]]: Claude Code 仕様一般・ベストプラクティス
- [[lw-kit-詳細設計-README]]: README（人間向け）と CLAUDE.md（Claude 向け）の対関係
- [[lw-kit-詳細設計-issue]]: 進行中タスクの中断点メモ
- [[lw-kit-詳細設計-rules]]: rules の設計・運用・改訂の起点（wiki.md / issue.md 等の構成はそちらを参照）
