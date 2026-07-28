---
type: entity
tags: [claude-code, multi-agent, agent-teams, feature]
sources:
  - https://code.claude.com/docs/en/agent-teams
created: 2026-05-29
updated: 2026-07-15
---

# Claude-Code-Agent-Teams

1 つの lead セッションが複数の teammate を生成・調整し、共有タスクリストとメールボックスで協調させる Claude Code の機能。
実験機能で、環境変数 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` または `settings.json` の `env` で有効化する。
v2.1.178 で TeamCreate / TeamDelete が廃止され、セッション起動時に暗黙の 1 チームが自動生成される方式に移行した。

## アーキテクチャ

| 要素      | 役割                                                     |
| --------- | -------------------------------------------------------- |
| Team Lead | メインセッション。タスク割り当て・結果統合               |
| Teammates | 独立した Claude Code インスタンス、各自の context window |
| Task List | 共有タスクリスト（pending → in_progress → completed）    |
| Mailbox   | エージェント間メッセージング                             |

teammate は lead の会話履歴を引き継がず、spawn 時のプロンプトと CLAUDE.md のみで動く。
権限は lead の設定を継承する。
これが [[Sub-Agent]] との分かれ目で、Sub-Agent は空 context で結果を返して終わるのに対し、teammate は独立したフル instance としてタスクをセルフクレームし mailbox で通信し続ける。

## タスクとメッセージング

- lead がタスクを作成して割り当てる、または teammate がセルフクレームする
- タスク間に依存関係を設定でき、依存先完了まで blocked になる
- ファイルロックで同一ファイルへの競合を防ぐ
- message は特定 teammate へ、broadcast は全員へ（トークンコストに注意）。teammate 同士も名前で直接やり取りできる
- 終了系メッセージ: `shutdown_request` で teammate に終了を要請し、`shutdown_response` で承認/拒否を返す
- メールボックスの実体は `~/.claude/teams/{team-name}/inboxes/{agent-name}.json`。v2.1.207 以降、不正なエントリは個別除去される（以前は 1 つ壊れると全体がブロックされた）

## フック（品質ゲート）

| フック          | 用途                                                     |
| --------------- | -------------------------------------------------------- |
| `TeammateIdle`  | teammate アイドル時。exit code 2 でフィードバック + 継続 |
| `TaskCreated`   | タスク作成時。exit code 2 で作成拒否                     |
| `TaskCompleted` | タスク完了時。exit code 2 で完了拒否（品質ゲート）       |

フック機構一般は [[Claude-Code-Hook]] 参照（全 27 種にこの 3 つが含まれる）。

## 表示モード

`teammateMode`（`~/.claude/settings.json`）で設定する。CLI では `--teammate-mode` フラグ。

| モード                     | 動作                                                           | 要件               |
| -------------------------- | -------------------------------------------------------------- | ------------------ |
| `in-process`（デフォルト） | 全 teammate がメインターミナル内。矢印キーで選択、Enter で表示 | 不要               |
| `auto`                     | tmux / iTerm2 なら split、なければ in-process にフォールバック | tmux or iTerm2     |
| `tmux`                     | split pane 強制。tmux or iTerm2 を自動検出                     | tmux or iTerm2     |
| `iterm2`（v2.1.186+）      | iTerm2 native split 明示                                       | iTerm2 + `it2` CLI |

v2.1.179 以前のデフォルトは `auto` だったが、以降は `in-process` に変更された。
split-pane は VS Code 内蔵 terminal / Windows Terminal / Ghostty 単体では非対応。

in-process mode の操作:

| 操作                    | キー                       |
| ----------------------- | -------------------------- |
| teammate 選択           | 矢印キー（上下）           |
| teammate セッション表示 | Enter（選択後）            |
| teammate の停止         | `x`（選択した teammate）   |
| タスクリスト表示        | `Ctrl+T`                   |
| teammate への割り込み   | Escape（セッション表示中） |

v2.1.199 以降、idle な teammate の行は他の teammate がまだ作業中の間は表示され続ける。全員 idle になると 30 秒後に非表示になるが、teammate 自体は動作中で再度アドレス可能。3 人以上が idle の場合、超過分は折りたたまれる。

## teammate の spawn 制御

- subagent definition の再利用: spawn 時に既存の subagent type を名前指定で呼べる。`tools` は allowlist として、`model` はそのまま適用、body は teammate の system prompt に append（置換でなく追加）。`skills` / `mcpServers` は適用されず teammate の project / user settings から load される。
- plan approval 必須化: teammate を read-only plan mode で動かし、plan を lead に提出させ approve / reject させられる。lead の判断基準はプロンプトで誘導できる（「test coverage が無い plan は reject」等）。
- model 指定: spawn 時に Agent ツールの `model` パラメータで個別指定できる。未指定時のデフォルトは `/config` の Default teammate model で設定する（lead の `/model` は継承しない）。

## チームのライフサイクル（v2.1.178+）

- セッション起動時にチームが自動生成される。チーム名は `session-{セッションID先頭8文字}` で自動導出
- teammate は Agent ツールの `name` パラメータで直接 spawn する。setup step は不要
- 旧 API の `team_name` パラメータは受け付けるが無視される（deprecated）。hook payload の `team_name` フィールドも同様
- チーム設定は `~/.claude/teams/{team-name}/config.json` に保存され、セッション終了時に自動削除される
- タスクは `~/.claude/tasks/{team-name}/` にローカル永続化（resume 用）。`cleanupPeriodDays` 設定で GC

## 制限事項

- セッション再開時に in-process teammate は復元されない（`/resume` / `/rewind` 不可、再 spawn が必要）
- タスクステータスが遅延し dependent task が block されることがある
- ネストされたチーム不可（teammate は自分のチームを作れない）
- 1 セッション 1 チーム、lead は固定（teammate を lead に昇格できない、leadership 移譲不可）
- in-process teammate からの background subagent は不可
- spawn 時の per-teammate permission mode は設定不可（後からの個別変更は可能）

## 関連

- [[cmux]] — `cmux claude-teams` で Agent Teams をネイティブペインとして起動できる
- [[Sub-Agent]] — 独立 context のエージェント、teammate との違い（結果返却のみ vs 常駐協調）
- [[Claude-Code-Hook]] — `TeammateIdle` / `TaskCreated` / `TaskCompleted` の発火元
- [[Agent-Teams運用パターン]] — 実践から抽出した成功 / 失敗パターンと Tips
