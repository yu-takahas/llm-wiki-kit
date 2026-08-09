---
type: concept
tags: [Temperature, decoding, サンプリング, LLM, exploration-exploitation]
sources:
  - https://platform.claude.com/docs/ja/build-with-claude/prompt-engineering/claude-prompting-best-practices
created: 2026-05-26
updated: 2026-08-09
---

# Temperature

Temperature（温度）は、LLM が次トークンを確率的に選ぶ際の出力分布の鋭さを制御するサンプリングパラメータ。
softmax のロジットを温度 T で割ってから確率に変換するため、T が分布のエントロピーを直接左右する。

## 挙動

- 低温（T < 1）: 分布が尖り、最尤トークンに集中する。決定的・保守的な出力になる
- 高温（T > 1）: 分布が平坦化し、低確率トークンも出やすくなる。多様で予測しにくい出力になる
- T → 0: 実質 greedy（argmax）、常に最尤トークンを選ぶ

## 探索・活用との関係

Temperature は decoding における [[探索・活用ジレンマ]] の制御つまみそのもの。
高温は探索（多様な候補を試す）、低温は活用（既知の最善を取る）に対応する。
固定値で扱うのが従来だが、近年は生成中に隠れ状態から温度を適応選択する手法や、RLHF 等の RL ポストトレーニングで生じる探索の崩壊に対し温度をメタポリシーとして制御する研究が進んでいる。

## Claude API での扱い

Anthropic は [[Claude]] Opus 4.7 以降で API パラメータとしての Temperature を廃止し、出力調整をプロンプトに委ねる方式に移行した。
同じ時期に思考の制御方法も入れ替わっている。

- `temperature` — Opus 4.7 以降で廃止
- `budget_tokens`（拡張思考の手動バジェット）— Opus 4.6 / Sonnet 4.6 では動くが非推奨、4.7 以降のモデルでは 400 エラーになる
- `thinking: {type: "adaptive"}`（適応的思考）— モデルがいつどれだけ思考するかを動的に決める方式。4.6 以降はこちらが主

思考の深さは effort（`low` / `medium` / `high` / `xhigh` / `max`）で制御する。
Opus 5 と Sonnet 5 は Claude API と Claude Code で既定が `high`。
トークンの厳格な上限が要る場合は `max_tokens` を使う。

サンプリングの温度そのものが無くなったわけではなく、呼び出し側から触れる面が閉じた。
出力の多様性を動かしたいなら、プロンプトで指示するか effort を変える。

## リスト生成のパラドックス

直感に反するが、T=0 の方が T=1 よりリストを終わらせにくい。

リストが 5 個続いたとき、「6 個目が来る確率 60%」「終了確率 40%」だとする。
T=0 では常に確率最大の選択肢を選ぶため「6 個目」を選び続け、終了確率 40% が永遠に選ばれない。
T=1 では確率分布をそのまま使うため、40% の確率で「終了」が選ばれるチャンスが累積的に生まれる。

T=0 は「確率の奴隷」になり、確率上位の「続行」を選び続けて目的地（終了）を通り過ぎる。

## Repetition Penalty

既出トークンの Logits を後付けに引き下げ、自己回帰ループを物理的に阻害する手法。
「の」「は」などの頻出語まで制限がかかり、文章が不自然になるリスクがある。

## 関連

[[探索・活用ジレンマ]] / RLHF / Top-p

Temperature パラメータの査読論文では、AdapT 動的調整や 0-1 範囲の有意差なしなど、固定温度の前提を問い直す研究が報告されている。
Temperature・Top-p の各社 API 仕様比較では、各ツール（GitHub Copilot / Cursor 等）の実態差が報告されている。
「生成AIが毎回違う答えを返すのはなぜか」を扱うブログ記事が、Temperature を主軸に LLM のサンプリング過程を解説している。
