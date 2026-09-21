---
type: entity
tags: [claude-code, statusline, cli, feature]
sources:
  - https://code.claude.com/docs/en/statusline
created: 2026-05-29
updated: 2026-09-22
---

# Claude-Codeのステータスライン

画面下部に表示されるカスタマイズ可能なバー。
シェルスクリプトを実行し、stdin 経由で受け取った JSON セッションデータを元に、stdout へ出力したテキストがそのまま表示される。
コンテキスト使用率・セッションコスト・git ブランチなどをリアルタイムに見せる用途で使う。

## セットアップ

3 通りある。

- `/statusline` コマンド: 自然言語で指示するとスクリプトを自動生成する
- 手動設定: `settings.json` の `statusLine` フィールドにスクリプトのパスかインラインコマンドを指定する
- `ccstatusline` 等のコミュニティツール: TUI で対話的に組み立てる

`statusLine` が取るフィールド:

| フィールド             | 内容                                                                  |
| ---------------------- | --------------------------------------------------------------------- |
| `type`                 | `"command"` 固定                                                      |
| `command`              | スクリプトのパス、またはインラインのシェルコマンド                    |
| `padding`              | 水平方向の追加スペース（文字数、既定 0）。UI 既定の余白への上乗せ     |
| `refreshInterval`      | N 秒ごとに再実行（最小 1）。イベント駆動の更新に追加される            |
| `hideVimModeIndicator` | 組み込みの `-- INSERT --` 表示を消す。`vim.mode` を自前で描く時に使う |

`subagentStatusLine` は別キーで、agent パネルに並ぶ subagent の行を自前で描く。
入出力の形はメインのステータスラインと異なり、詳細は [[Claude-Codeステータスラインの組み方]] が持つ。

`statusLine` キーは settings.json 配下なので、設定ファイルの一般仕様は [[Claude-Code-settings.json]] を参照。

## 動作の仕組み

入出力は stdin に JSON、stdout にテキスト。
ローカル実行なので API トークンを消費しない。

セッション開始（resume 含む）で 1 回走り、以降は次の契機で再実行される。

- 新しいアシスタントメッセージの到着
- `/compact` の完了
- パーミッションモードの変更
- vim モードの切り替え
- `statusLine.command` の変更
- `refreshInterval` のタイマー経過
- 直前に渡した利用枠の `resets_at` 到達
- 直前に渡したプロンプトキャッシュの `expires_at` 到達

更新は 300ms でデバウンスされる。
`command` の変更だけはデバウンスを飛ばして即座に走る。
実行中に次の更新が来ると、走っているスクリプトはキャンセルされる。
背景の subagent を待っている間などはイベントが止まるので、時刻を出すなら `refreshInterval` が要る。

出力でできること:

- 複数行: 出力 1 行が表示 1 行になる
- 色: ANSI エスケープコード
- リンク: OSC 8 エスケープ。iTerm2 / Kitty / WezTerm は対応、Terminal.app は非対応。`FORCE_HYPERLINK=1` で検出を上書きできる
- 幅の取得: `tput cols` は効かない（stdout が端末に直結していない）。`COLUMNS` / `LINES` 環境変数を読む

オートコンプリート・ヘルプ・パーミッションプロンプトの表示中は一時的に隠れる。
フルスクリーン描画でない場合、同じ行の右側に MCP エラー等の通知が出るので、狭い端末では自分の出力が切られる。

## 利用可能な JSON フィールド

スクリプトが stdin で受け取れるフィールド。

| フィールド                                                   | 内容                                                                  |
| ------------------------------------------------------------ | --------------------------------------------------------------------- |
| `model.id` / `model.display_name`                            | モデル識別子 / 表示名                                                 |
| `session_id`                                                 | セッション識別子（キャッシュファイル名に使える）                      |
| `session_name`                                               | `/rename` で付けた名前                                                |
| `prompt_id`                                                  | 処理中プロンプトの UUID                                               |
| `transcript_path` / `cwd`                                    | 会話ログのパス / 作業ディレクトリ                                     |
| `version`                                                    | Claude Code のバージョン                                              |
| `workspace.current_dir` / `.project_dir`                     | 作業 / 起動ディレクトリ                                               |
| `workspace.added_dirs`                                       | `/add-dir` で足したディレクトリの配列                                 |
| `workspace.git_worktree`                                     | リンク worktree 内にいる時の worktree 名                              |
| `workspace.repo.host` / `.owner` / `.name`                   | origin リモートから解析したリポジトリ識別                             |
| `output_style.name`                                          | 出力スタイル名                                                        |
| `context_window.used_percentage` / `.remaining_percentage`   | コンテキスト使用率 / 残り（最初の応答前は `null`）                    |
| `context_window.total_input_tokens` / `.context_window_size` | 現在の入力トークン / モデルの窓サイズ                                 |
| `context_window.current_usage`                               | 直近 API 呼び出しの入出力・キャッシュ読み書きトークン                 |
| `exceeds_200k_tokens`                                        | 200k 超えかどうか                                                     |
| `cost.total_cost_usd`                                        | 概算コスト。`/clear` で 0 に戻る                                      |
| `cost.total_duration_ms` / `.total_api_duration_ms`          | 経過時間 / API 待ち時間                                               |
| `cost.total_lines_added` / `.total_lines_removed`            | セッション中の追加・削除行数                                          |
| `rate_limits.five_hour` / `.seven_day`                       | 5 時間枠 / 7 日枠の `used_percentage` と `resets_at`（epoch 秒）      |
| `rate_limits.spend_limit`                                    | gateway 経由の支出上限。超過すると 100 を超える                       |
| `prompt_cache.warm` / `.caching_observed`                    | キャッシュが TTL 内か / キャッシュが観測されたか                      |
| `prompt_cache.ttl` / `.expires_at`                           | 書いた TTL（`5m` / `1h`）と失効時刻                                   |
| `prompt_cache.hit_ratio` / `.requests` / `.misses`           | ヒット率・リクエスト数・ミス数                                        |
| `prompt_cache.last_miss_cause.causes`                        | 直近ミスの推定原因（`system_prompt_changed` / `tools_changed` 等）    |
| `effort.level`                                               | `low` / `medium` / `high` / `xhigh` / `max`。対応モデルの時だけ現れる |
| `thinking.enabled`                                           | 拡張思考が有効か                                                      |
| `fast_mode`                                                  | fast mode かどうか                                                    |
| `vim.mode`                                                   | vim モード（有効時のみ）                                              |
| `agent.name` / `.type`                                       | `--agent` 起動時のエージェント名                                      |
| `pr.number` / `.url` / `.review_state` / `.kind`             | 現ブランチの PR / MR。`kind` が `mr` なら GitLab                      |
| `worktree.name` / `.path` / `.branch` / `.original_branch`   | worktree セッション時の情報                                           |

`rate_limits` は claude.ai の Pro / Max 契約か gateway 配下でのみ、かつ最初の API 応答の後に現れる。
`prompt_cache` も最初の API 応答の後に現れる。
どちらも無いことを前提に組む。

## 落とし穴 / Tips

- 出力は短く保つ（バーの幅は限られる）
- スクリプトが非ゼロ終了、または無出力だとステータスラインが空になる
- 遅いスクリプトは更新をブロックする。`git status` のような遅い操作は一時ファイルにキャッシュする
- `null` は最初の API 応答前に普通に出る。`// 0` 等のフォールバックを入れる
- `disableAllHooks: true` にするとステータスラインも無効になる（managed settings のものだけが残る）
- 組織が `allowManagedHooksOnly` を設定していると、自作ステータスラインは警告なしに消える
- ワークスペースの信頼を受け入れるまで表示は空のまま。`claude --debug` に `Status line command skipped: workspace trust not accepted` が出る
- ANSI / OSC 8 が他の UI 更新と重なると描画が乱れることがある。複数行とエスケープの組み合わせで起きやすい
- デバッグは `claude --debug`、モック JSON を流してスクリプト単体テストも可能
- `/statusline` に複数行の指示を貼り付けると、コマンドとして解釈されず本文として送られることがある。長い指示を渡す時は結果を確認する

## 関連

- [[Claude-Codeステータスラインの組み方]] — スクリプトを書く時の実装パターンとコミュニティツール
- [[Claude-Code-settings.json]] — `statusLine` キーが属する設定ファイルの一般仕様
