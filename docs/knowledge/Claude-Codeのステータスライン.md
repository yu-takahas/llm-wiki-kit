---
type: entity
tags: [claude-code, statusline, cli, feature]
sources:
  - https://code.claude.com/docs/ja/statusline
created: 2026-05-29
updated: 2026-05-29
---

# Claude-Codeのステータスライン

画面下部に表示されるカスタマイズ可能なバー。
シェルスクリプトを実行し、stdin 経由で受け取った JSON セッションデータを元に、stdout へ出力したテキストがそのまま表示される。
コンテキスト使用率・セッションコスト・git ブランチなどをリアルタイムに見せる用途で使う。

## セットアップ

3 通りある。

- `/statusline` コマンド: 自然言語で指示するとスクリプトを自動生成する
- 手動設定: `settings.json` の `statusLine` フィールドに `type: command` と自作スクリプトのパスを指定する（`padding` で水平スペースを調整）
- `ccstatusline` 等のコミュニティツール: TUI で対話的に組み立てる

`statusLine` キーは settings.json 配下なので、設定ファイルの一般仕様は [[Claude-Code-settings.json]] を参照。

## 動作の仕組み

- 入出力: stdin に JSON、stdout にテキスト。複数行出力すると各行が別行として表示される
- 更新タイミング: 新しいアシスタントメッセージの後、パーミッションモード変更時、vim モード切替時
- 更新は 300ms でデバウンスされる
- ローカル実行なので API トークンを消費しない
- ANSI エスケープコードで色付け、OSC 8 エスケープでクリック可能リンクも作れる

## 利用可能な JSON フィールド

スクリプトが stdin で受け取れる主なフィールド。

| フィールド                              | 内容                           |
| --------------------------------------- | ------------------------------ |
| `model.id` / `model.display_name`       | モデル識別子と表示名           |
| `workspace.current_dir` / `project_dir` | 作業 / 起動ディレクトリ        |
| `cost.total_cost_usd`                   | セッション総コスト（USD）      |
| `cost.total_duration_ms`                | セッション経過時間             |
| `context_window.used_percentage`        | コンテキスト使用割合           |
| `context_window.context_window_size`    | 最大サイズ（200000 / 1000000） |
| `session_id` / `version`                | セッション識別子 / バージョン  |
| `vim.mode`                              | vim モード                     |
| `worktree.name` / `.path` / `.branch`   | worktree 情報                  |

## コミュニティツール

| ツール              | 特徴                                             |
| ------------------- | ------------------------------------------------ |
| `ccstatusline`      | TUI で対話設定、Powerline 対応、`npx` で即実行   |
| `claude-statusline` | Go 製、Starship 風プリセットとフォーマット文字列 |
| `starship-claude`   | テーマと追加機能付きの事前構築設定               |

## 落とし穴 / Tips

- 出力は短く保つ（バーの幅は限られる）
- `git status` のような遅い操作は一時ファイルにキャッシュする
- `null` になりうるフィールドは `// 0` 等のフォールバックを入れる
- `disableAllHooks: true` にするとステータスラインも無効になる
- デバッグは `claude --debug`、モック JSON を流してスクリプト単体テストも可能

## 関連

- [[Claude-Code-settings.json]] — `statusLine` キーが属する設定ファイルの一般仕様
