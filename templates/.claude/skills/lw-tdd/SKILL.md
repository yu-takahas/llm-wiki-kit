---
name: lw-tdd
description: "Runs TDD Red-Green-Refactor cycles with subagent isolation. Dispatches one implementer subagent per test scenario, verifies evidence, and updates issue progress."
disable-model-invocation: true
allowed-tools: [Read, Edit, Grep, Glob, Task, "Bash(npm run:*)"]
argument-hint: "[fix <説明> | シナリオ指定]"
---

# lw-tdd

内側ループ（Red-Green-Refactor）を 1 シナリオ = 1 subagent で回す TDD skill。
設計判断の why は `$KIT/docs/lw-kit/40_スキル設計/lw-kit-スキル設計-lw-tdd.md`。

入力: `$ARGUMENTS` はバグ修正モード（`fix <説明>`）や特定シナリオの指定。省略時は issue から自動選択。

## 事前条件

サイクルに入る前に確認する。

1. WIP issue にテストシナリオセクションがあり、未チェック `[ ]` 行が存在する（なければフォールバック: テスト案を提示 → lead 承認 → issue に書き込み）
2. issue の設計仕様セクションが埋まっている（未完了なら lead に報告して停止）
3. テスト・typecheck コマンドが検出できる（案件 `CLAUDE.md` → `package.json` の `scripts.test` → lead に聞く の順）

## 準備

テストスイートと typecheck を走らせ、Baseline を記録する。
Green の定義は「テスト pass + typecheck pass」の複合。

```text
Baseline: <N> tests / <N> pass / <N> fail / typecheck <pass|fail>
```

既存の失敗がある場合はメモし、Red/Green 判定から除外する。

## サイクル（main loop）

TODO 完了まで自走で回す。
止めたいときは lead が割り込む。

Bash スコープは `npm run *` に制限されている。
npm 以外のランナーを使う案件では frontmatter の `allowed-tools` を変更する。

### 1. シナリオ選択

issue の「テストシナリオ」セクションと ☔ TODO から次の未チェック `[ ]` 行を拾う。

行選別規則（対象はコードシナリオのみ。判別基準の正本は `00_issues/.guide/dev-guide.md`）:

- 対象外: プロンプトシナリオ（ラベルや `(ユーザー)` マークで判別）
- 対象外: 作業行（関数削除 / コード移行 / revert 等）
- ランナー判断: シナリオがどのテストランナーに属するか判断してから絞り込む

「次はこれ」と報告してそのまま subagent を dispatch（確認待ちしない）。

### 2. subagent dispatch

シナリオごとに新規 Agent を spawn する（SendMessage で前の subagent を再利用しない）。
agent 名はシナリオ ID を含める（例: `impl-01-statusExpressionMap` / `impl-03-patch-schema`）。名前の使い回しを構造的に防ぐ。
理由: briefing がプロンプト先頭に入り直すことで遵守率の維持装置として機能する。再利用すると briefing が context の奥に沈み、後半サイクルで Red 飛ばし・過剰実装が起きやすくなる。

`briefing.md` をベースに、以下を動的に埋めて dispatch する:

- 対象シナリオの文言 + モード（通常 / バグ修正 / 実装先行）。対象の実装が既にあると分かっているなら実装先行を指定する（判断が付かなければ通常でよい。subagent が Verify RED で気づいて分岐する）
- テストコマンド / typecheck コマンド
- サイクルごとの検証範囲（全スイート / 対象 spec のみ）。ビルドを伴う E2E がある案件は後者にし、全体確認は TODO 消化後に main が 1 回まとめて行う
- 次のシナリオの文言（「このサイクルでやらないこと」に逐語で入れる）
- Baseline 結果
- issue の設計仕様・参考パターンの関連抜粋
- 触らないファイル
- 既存テストの参考ファイルパス（subagent が Read する）

### 3. 証拠確認

subagent の完了報告を受け取り、以下を確認する:

- Verify RED: 失敗理由が「機能欠落」であること（typo / import エラーではない）。実装が先にあるシナリオでは「壊した対象と失敗理由」が対象ごとに埋まっていること
- Verify GREEN: 新テスト + typecheck が pass。検証範囲が全スイートなら全スイートも。出力にエラー・警告がないこと
- Per-cycle checklist: 全 OK（項目は `briefing.md`）
- 消した振る舞い: 報告の「消した振る舞い」欄がシナリオの意図に含まれるか確認する（含まれなければ差し戻し）
- 変更ファイル一覧 / 追加テスト数: 記録として受け取る（検証対象外）

証拠に問題があれば subagent に差し戻すか、lead に相談する。

subagent のライフサイクル:

- 問題なし → shutdown して次のシナリオで新規 spawn
- 問題あり（差し戻し / 修正指示）→ 同じ subagent に SendMessage で追撃。解決後に shutdown
- 応答なし（idle 通知のみで結果が返らない）→ 1 回催促。それでも返らなければ `git diff` で変更を直接確認し、lead が証拠を検証する

### 4. issue 更新

subagent の報告の「issue 更新」欄を見て、該当行を `[x]` に更新する。

### 5. REPEAT

次の未チェック行に進む（ステップ 1 に戻る）。
全行完了したら全スイート + typecheck を 1 回走らせる（検証範囲を対象 spec のみにしていた場合は、ここが全体確認の唯一の機会になる）。
緑を確認したら「TODO が空になった、`/lw-commit` を提案」で skill 終端。

## エラー対応

- subagent が停止条件で止まった → main が判断（差し戻し / 次のシナリオと統合 / lead 相談）
- 事前条件未達 → lead に報告して停止
- 環境エラー → 停止して報告

$ARGUMENTS
