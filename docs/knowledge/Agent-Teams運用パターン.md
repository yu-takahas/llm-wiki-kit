---
type: synthesis
tags: [claude-code, agent-teams, multi-agent, operations, best-practice]
sources:
  - "[[Claude-Code-Agent-Teams]]"
  - "[[cmux]]"
created: 2026-05-29
updated: 2026-07-20
---

# Agent-Teams運用パターン

[[Claude-Code-Agent-Teams]] を実際に回すときの設計パターンと Tips。
機構の仕様は entity 側、本ページはコミュニティの実践と Anthropic / OpenAI の公式知見から抽出した使いこなしに絞る。

## 向いている使い方

- 独立性の高いタスクの並列実行（モジュール別実装、調査と実装の分離）
- レビュー・テスト・実装の役割分担（プログラマー / レビュアー / テスター）
- 複数仮説の並列検証（バグ調査で各 teammate が別の仮説を追う）
- cross-layer の分担（frontend / backend / test を各 teammate が担当）

委任の現実的な打率として、創造的タスクでは 8 割は委任できても残り 2 割は人間の視点が要る。
丸投げの完成度を過信せず、判断と仕上げは人間が持つ前提で設計する。

## orchestrator パターン

lead（orchestrator）と teammate（sub-agent）の役割分担には 2 つの主要パターンがある。

| パターン                   | 仕組み                                                                           | 使い所                                    |
| -------------------------- | -------------------------------------------------------------------------------- | ----------------------------------------- |
| Manager（agents as tools） | lead が teammate をツールとして呼び出し、結果を受け取って次の判断をする          | 結果だけ欲しい時。teammate 間の通信が不要 |
| Handoff（ルーティング）    | lead が会話を適切な teammate にルーティングし、teammate がそのまま応答を所有する | teammate に判断を委ねたい時               |

Agent Teams は Handoff 寄りの設計（teammate が独立した context を持ち、自律的に動く）。
sub-agent は Manager 寄り（結果を caller に返すだけ）。
目的に応じて使い分ける。

Anthropic の研究システムでは lead が「クエリ分析 → 戦略策定 → sub-agent 生成」を担当し、sub-agent は「明確な目標、出力形式、ツール選択、タスク境界」を受け取って独立実行する。
lead は自分で実装せず、分割・割り当て・統合に専念する。

## advisor / レビュー役の活用

専門化した reviewer を置くパターンがいくつかある。

- adversarial reviewer: 他の teammate の理論を積極的に反論させる。「devil's advocate」を明示的に role 指定する。sequential だと anchoring bias がかかるが、並列 + 相互反論で生き残った結論の精度が上がる
- plan approval: teammate に plan mode を要求し、lead が承認するまで実装に入らない。リスクの高いタスクで有効
- 引用検証エージェント: 出力の正確性を検証する専門 agent。Anthropic の研究システムで採用
- ルーブリック評価: lead が自分の出力を評価基準（正確性、引用精度、完全性）で自己採点する

## エラーリカバリ

| 手法             | 仕組み                                                            | 適用場面                 |
| ---------------- | ----------------------------------------------------------------- | ------------------------ |
| git revert       | 悪い変更を git で巻き戻して動作する状態に復旧                     | コード変更の失敗         |
| チェックポイント | 進捗を JSON ファイル等に外部化し、セッション再開時に読み込む      | 長時間タスクの中断・再開 |
| 代替 teammate    | 停止した teammate の代わりに新しい teammate を spawn して引き継ぐ | teammate のエラー停止    |
| 早期検知         | セッション開始時に基本機能テストを実施し、破損状態を早期に発見    | 環境の健全性確認         |

v2.1.198+ では teammate がエラーで停止すると lead に自動通知される。
lead からのメッセージで API エラーリトライ待ちの teammate を即座に再開できる。

長時間ループ固有のリカバリ手法として、セッション開始時に `init.sh` で環境の破損を素早く判定する手法や、完了宣言を鵜呑みにせず条件を満たすまで繰り返す Ralph Loop パターンがある。
詳細は [[エージェントループの運用手法]] を参照。

## 進捗管理

外部ファイルで進捗を追跡するのが実践的。3 つの主要パターンがある。

- PROGRESS.md（チェックリスト型）: `[ ]` / `[-]` / `[x]` でタスクの進捗を管理。最も軽量で `/loop` で広く使われる
- `feature_list.json`（構造化 JSON 型）: `passes` フィールドのみ更新可能。JSON は LLM が不適切に書き換えにくい
- CHANGELOG.md（研究ノート型）: 完了タスクだけでなく、失敗アプローチとその理由も記録する lab notes
- git commit log: 実装の履歴と説明

各形式の詳細と使い分けは [[エージェントループの運用手法]] を参照。

Agent Teams の共有タスクリストは pending → in_progress → completed の 3 状態で管理される。
タスク間の依存関係を自動管理（依存が完了すると後続がアンブロック）。
file locking で複数 teammate の同時 claim を防止。

hooks（`TaskCreated` / `TaskCompleted` / `TeammateIdle`）でカスタムロジックを挟める。
`TeammateIdle` を exit code 2 で返すとフィードバック付きで再稼働させられる。

## 多重度とタスク粒度

チーム構成は 3〜5 人が最適。
Anthropic の研究システムでは「シンプルな事実調査は 1 人、比較は 2〜4 人、複雑な研究は 10 人以上」。
3 人の集中した teammate が 5 人の散漫な teammate を上回ることが多い。

タスク粒度の目安:

- teammate あたり 5〜6 タスク
- 1 タスクは自己完結して検証可能な成果物を出す粒度
- 小さすぎると coordination overhead が勝つ、大きすぎると check-in なしに長時間走って手戻りリスク

トークンコストは teammate 数に比例（通常の 4〜5 倍、研究系は 15 倍）。
routine なタスクは 1 セッションの方がコスト効率がいい。

## コンフリクト回避

1 teammate = 1 ファイルセットが鉄則。同じファイルを複数 teammate が編集すると上書きが起きる。

| 手法         | 仕組み                                                                             |
| ------------ | ---------------------------------------------------------------------------------- |
| 担当分割     | 各 teammate が所有するファイルセットを明示的に分ける                               |
| git worktree | teammate ごとに独立した worktree で作業し、完了後にマージ                          |
| 直列化       | 同じファイルを触る必要がある作業は直列に実行                                       |
| 出力の外部化 | sub-agent が外部ファイルにアウトプットを保存し、軽量な参照のみ orchestrator に返す |

## 失敗パターン

| パターン             | 内容                                                                                      |
| -------------------- | ----------------------------------------------------------------------------------------- |
| 通信障害             | teammate 完了を lead が受信できず待ちぼうけ                                               |
| ファイル競合         | 複数 teammate の同時編集でコンフリクト                                                    |
| セッション断絶       | in-process teammate はセッション再開で復元されない                                        |
| トークン爆発         | 各 teammate が独立 context のため通常の 4-5 倍を消費                                      |
| rewind / resume 不可 | チーム操作の巻き戻し・再開ができない                                                      |
| ステータス遅延       | タスク状態の更新が遅れ lead の判断がずれる                                                |
| lead の自走          | lead が teammate の完了を待たず自分で実装を始める。「wait for teammates」と明示指示が必要 |

## Tips

- lead の初期プロンプトに「N 人 + 各役割」を具体的に明示する
- delegate モードでは lead はコードに触らず、分割・割り当て・統合に専念する
- teammate には十分なコンテキストを渡す（lead の会話履歴は引き継がれない）
- broadcast は最小限に（全員送信はトークンコストが線形に増える）
- `TaskCompleted` フックで自動テストやリント通過を完了条件にし、品質ゲートを設ける
- まず research / review から始める（コード変更なし、並行のリスクが低い）
- 慣れたら new feature（各 teammate が独立したモジュールを担当）
- refactoring / migration は同一ファイル共有が多く上級者向け

## 関連

- [[エージェントループの運用手法]] — 状態ファイル形式・ハンドオフ・停止条件・リカバリの具体的手法
- [[Claude-Code-Agent-Teams]] — 運用対象の協調機構の仕様
- [[cmux]] — `cmux claude-teams` での起動とペイン表示
- feedback-観察-失敗事例 — cmux-teams 運用で踏んだ失敗の蓄積先（配布時は空テンプレート）
- [[Claude-Code並列セッション運用]] — もう一方の並列モデル（worktree 型）
