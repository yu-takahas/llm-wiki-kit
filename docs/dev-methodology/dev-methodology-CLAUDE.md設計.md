---
type: synthesis
tags: [開発手法, CLAUDE.md, 助言層, add-dir, nudge]
sources:
  - "[[dev-methodology-ワークフロー基本設計]]"
  - "[[Claude-Codeのメモリ階層]]"
created: 2026-07-18
updated: 2026-07-28
---

# 案件 CLAUDE.md 設計

助言層の配備先としての案件 CLAUDE.md の設計判断。
基本設計が定めた助言層の内容（nudge / コミット規約 / テストランナー / リファクタ分離等）を、案件の `.claude/CLAUDE.md` に配備する。

## 配置と有効化

案件の `.claude/CLAUDE.md` に書く。
add-dir 構成では `.claude/rules/` がロードされないため、rules ではなく CLAUDE.md に集約する。

add-dir の CLAUDE.md は `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` で有効化できる（v2.1.20 で追加、ドキュメント未記載）。
この環境変数が将来消えても壊れないよう、skill が必須とする情報は skill 内で自力 Read する二重化設計にする。

クリティカルの判定: その情報が読まれないと TDD サイクルや commit フローが壊れるもの（テストコマンド / typecheck コマンド / テストランナーの選択等）。
これらは `/lw-tdd` の事前条件で案件 CLAUDE.md から検出する仕組みが既にある。

既存の `rules/coding.md` / `rules/testing.md` も add-dir 運用では読まれないため、CLAUDE.md に統合して rules ディレクトリを廃止する。

## 却下した選択肢

- `rules/workflow.md`: add-dir 構成では rules がロードされないため、nudge として機能しない
- ワークスペース側の rules に案件の nudge を置く: 案件固有の内容をワークスペースに書く帰属のねじれ

## セクション構成

案件横断で再利用するパターン。案件ごとに具体値は異なるが構成は共通。

- コーディング規約: 型・定数の集約先、バリデーション方針、フレームワーク固有の注意等
- テストランナー: ランナー共存の事実情報（どのランナーがどのテスト系統を担うか）
- 開発ワークフロー: TDD nudge（いつ `/lw-tdd` を使うか） / テスト削除・skip 禁止 / リファクタと機能追加を混ぜない / カバレッジ基準 / 外側ループの組み込み skill 呼び出し順序（/simplify → /code-review → /verify）
- コミット規約: type と説明の形式

## コミット規約の衝突回避

ワークスペースを cwd にして add-dir で案件を触る運用では、ワークスペースの Git 規約（`type(project): 説明`）もセッションにロードされる。
案件 CLAUDE.md のコミット規約に「このリポジトリへの commit はこちらの規約に従う」と明記し、衝突を防ぐ。

## 保守規律

- 200 行未満を維持する（[[Claude-Codeのメモリ階層]] のサイズ規律）
- 具体値・列挙を書かない（ファイル名の列挙・件数・サイズ等は `ls` に任せる）
- コードスタイルは CLAUDE.md に書かない（linter / formatter に任せる）。CLAUDE.md に入れて良いのは formatter で表現できない判断（アーキテクチャ / 命名の意図 / バリデーション方針等）

## スコープ外

鮮度チェック（セッション開始時の `updated:` 突合）/ 大きい issue の分解判断 / 調査 → `10_raw/` → render の流れはワークスペース運用の内容であり、案件 CLAUDE.md には書かない。
ワークスペース側（issue 運用の rule か skill）の課題として扱う。

## 関連

- [[dev-methodology-ワークフロー基本設計]] — 助言層の定義、ガードレール配置層
- [[Claude-Codeのメモリ階層]] — CLAUDE.md / rules / skills の使い分け
- [[lw-kit-詳細設計-CLAUDE.md]] — ワークスペース側の CLAUDE.md 設計（参考パターン）
