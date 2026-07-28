---
type: synthesis
tags: [開発手法, settings.json, permission層, add-dir]
sources:
  - "[[dev-methodology-ワークフロー基本設計]]"
  - "[[Claude-Codeのメモリ階層]]"
created: 2026-07-18
updated: 2026-07-28
---

# 案件 settings.json 設計

permission 層としての案件 settings.json の設計判断。
基本設計が定めた permission 層の内容（反復コマンドの自動許可、破壊操作のブロック）を、案件の `.claude/settings.json` に配備する。

## 配置と制約

案件の `.claude/settings.json` に置く。
add-dir 構成では settings.json がロードされない（anthropics/claude-code #52934、not planned でクローズ）。
CLAUDE.md と異なり、環境変数等での有効化手段は確認できていない。

案件ディレクトリを cwd にした場合のみ有効。
ワークスペース cwd + add-dir の主運用では効かない。

## 未決事項

- ワークスペース側の settings に案件共通の deny（`git push --force` / `rm -rf` 等）を持たせるか。主運用で deny を効かせるにはこの経路しかないが、案件ごとにコマンド体系が異なるため allow は案件側に残す必要がある

## 関連

- [[dev-methodology-ワークフロー基本設計]] — permission 層の定義
