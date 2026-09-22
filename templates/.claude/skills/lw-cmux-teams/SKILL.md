---
name: lw-cmux-teams
effort: medium
description: Spawns and manages Agent Teams teammates via cmux. Use when setting up parallel teammates for review, research, or implementation.
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Bash(find:*)
  - Agent
  - SendMessage
  - TaskCreate
  - TaskList
argument-hint: "[task description]"
---

# lw-cmux-teams

設計判断の why は `$KIT/docs/lw-kit/40_スキル設計/lw-kit-スキル設計-lw-cmux-teams.md`、本ファイルは how + 具体値の正本。

cmux 上で Agent Teams を使うための skill。
タスク内容を受け取りチーム構成を決定して teammate を spawn・管理する。
引数なしで呼ぶと fable advisor を 1 人立ち上げて待機する。

## 用語

- lead: 現在のセッション。ユーザーと直接対話し、teammate を spawn・管理する実行者
- teammate: lead から spawn される子エージェント。独立した Claude Code フルセッション
- worker: teammate のうち汎用的なタスク実行役（`worker-N`）。役割が分化していない場合のフォールバック
- advisor: teammate のうち助言専任の役割。read / search / アドバイスのみ。lead が明示的に依頼した場合を除き書き込みしない

## Input

- `$ARGUMENTS`: タスクの説明（省略可）
  - 引数あり: チーム構成パターンから適切な構成を選び、teammate を spawn してタスクを渡す
  - 引数なし: advisor パターン（fable 1 人 spawn + WIP issue 読み込み待機）

## 実行フロー

全体像（3 ステップ）: `1. チーム構成決定` → `2. spawn` → `3. 結果統合`

### 1. チーム構成の決定

引数なし → advisor パターン（後述の「advisor パターン」セクション参照）。

引数あり → `$ARGUMENTS` の内容に適したチーム構成パターンを選択する（後述の「チーム構成パターン」参照）。

### 2. teammate の spawn

Agent ツール（foreground）で spawn する。cmux が各 teammate を別ペインに表示する。

Agent ツールに渡す引数:

- `name`: teammate name（例: `advisor` / `researcher` / `reviewer`）
- `subagent_type`: `.claude/agents/` 配下に定義があればそのタイプ名を指定。未定義なら省略
- `model`: 既定 `sonnet`（advisor は `fable`）
- `effort`: advisor は `medium`、他は省略（セッション既定を継承）
- `prompt`: briefing。次の 8 要素を全て書く

briefing の 8 要素:

1. 役割（何をする teammate か）
2. 読むべき資料（パスで渡す。teammate は lead の context を持たない）
3. やらないこと
4. 触らないファイル（`log.md` / `index.md` / `1_issues.md` / `2_done.md` / 他 teammate 担当ファイル。lead 集約で管理するものを個別更新すると衝突する）
5. 報告経路（`SendMessage({to: "team-lead", ...})` で返すこと、プレーンテキスト出力は lead に届かないこと、考えがまとまった時点で途中でも打つことの 3 点。書かないと teammate は報告したつもりで届かず、lead 側には idle 通知だけが見える）
6. 終了状態（測定可能な形で。残ったものを 1 件ずつ説明できる形にする）
7. 完了報告の形（終了状態が満たされたことを確かめた手段と実出力を添えさせる）
8. エスカレーション順（詰まったら待たずに lead に問う）

NG パターン:

- `run_in_background: true` で呼ぶ（cmux のペイン表示が機能しない）
- `cmux new-pane` + `claude` で手動起動（Agent Teams の管理外になる）

### 3. 結果の統合

全 teammate 完了後、結果をまとめて報告する。
合意点・相違点がある場合は明示する。

タスク管理: 引数ありモードでは TaskCreate / TaskList でタスクを管理する。advisor パターンではタスク管理は使わない（ユーザーが直接 advisor に指示する）。

全完了の検知: 各 teammate が完了時に SendMessage で lead に報告する。報告を受けたら TaskList で全タスクの状態を確認し、全完了なら統合へ進む。
報告は終了状態を確かめた手段と実出力を見てから受け取る。ファイルで確かめられる主張は Read で 1 件当てる。

shutdown: ユーザーの確認を得てから、各 teammate に `SendMessage({to: <name>, message: {type: "shutdown_request", reason: "..."}})` を送る。teammate は `shutdown_response` で承認する。セッション終了時に自動 cleanup されるので、shutdown は明示的に終わらせたい場合のみ。

## advisor パターン

引数なしのデフォルト動作。fable を advisor として 1 人 spawn し、資料を読ませて待機させる。

手順:

1. 現在の WIP issue を特定する（worktree 名 / `find 00_issues -maxdepth 1 -name "*.md"` から推定）
2. issue の `related:` / `sources:` / 本文のリンク先を「関連資料」として列挙する
3. fable を spawn する。briefing はステップ 2 の 8 要素を advisor の値で埋める。役割 = lead の相談相手・レビュー役、読むべき資料 = 手順 2 で列挙したもの、やらないこと = 明確な指示があるまで自分から動かない / lead が明示的に依頼した場合を除き書き込みしない、終了状態 = 資料を読み終えて「読み終わりました」と報告した時点
4. advisor が読み終わり報告を返したら、ユーザーからの指示を待つ

advisor の仕様:

- name: `advisor`
- model: `fable`
- effort: `medium`
- 役割: lead（Opus）の相談相手・レビュー役。実作業は lead が行う

## チーム構成パターン

advisor 以外のパターン。引数ありの場合に `$ARGUMENTS` から選択する。

### 調査 + 実装パターン

- researcher: 調査担当（コード変更なし）
- implementer: 実装担当

### レビューパターン

観点別に reviewer を分ける（例: security / performance / test coverage）。
観点数に応じて 2-3 人。

### Test + Fix Loop パターン

- watcher: テスト監視担当（watch モードで実行し、失敗をサマリーして fixer に報告）
- fixer: 修正担当（watcher の出力をもとにコードを修正）

### 大規模実装パターン

モジュール単位で worker を分ける。

- worker-1: モジュール A 担当
- worker-2: モジュール B 担当
- ...

## ルール

teammate 構成・運用に関する制約。フロー横断で適用する。

- teammate は最大 5 人まで（トークンコスト管理）
- teammate は気軽に立ち上げすぎない。タスクの独立性と規模が投入に見合うかを判断する
- 同じファイルを複数の teammate が編集しないようにタスクを分割する
- teammate のモデル既定は `sonnet`。advisor は `fable`。`opus` はユーザーから明示指示があった時のみ
- teammate name は役割名を優先（`researcher` / `reviewer` / `advisor` 等）。汎用 `worker-N` は役割が決まらない場合のフォールバック
- 引数なし時のタスクは lead が決めない、ユーザー投入を待つ。文脈推測でタスクを teammate に押し付けない
- ユーザーが lead に直接依頼した作業は teammate に二次委譲しない（依頼宛先のシグナルを優先）
- teammate は作業開始前にアプローチを lead に報告する。lead はアプローチが妥当と判断したらユーザーに確認せず承認してよい
- lead は teammate から上がった問いのうち、自分で答えられないものだけユーザーに上げる
- 設計書やチーム定義が worker に割り当てた作業は、効率を理由に lead が実行しない
- lead は teammate を shutdown する前に必ずユーザーに「cleanup 進めていい?」を確認する
- 一時的な調査・レビュー用 subagent（finder 等、結果だけ欲しいもの）は `name` なしで spawn する。team アクティブ中に `name` 付きで Agent を呼ぶと teammate 化して管理対象が増える
- 引数ありモードでは、task の所有者の設定を dispatch より前に済ませる。後から設定すると当人に割り当て通知が飛び、報告済みの teammate との往復が生じる

## 既知の制約

Agent Teams に共通する制約。skill で回避できないので運用で気をつける。

- 1 session = 1 team。lead は固定（昇格・譲渡不可）
- session resume で in-process teammate は復元されない（再 spawn が必要）
- task status のラグ（teammate が completed マーク忘れ）。lead 側で TaskList を見て補正する場合あり
- shutdown が遅い（teammate が現在処理中の tool call を完了するまで待つ）。`shutdown_request` に応答せず idle 通知を繰り返す場合は、`shutdown_response` を `approve: true` で返すよう明示して再送する
- teammate からの background subagent は不可（in-process mode）
