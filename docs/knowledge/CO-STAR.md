---
type: entity
tags: [prompt-engineering, framework, CO-STAR]
sources:
  - https://prompt-ya.com/co-star/
  - https://qiita.com/Simon_Zhang/items/28f4e1c7799fa7fa2635
created: 2026-05-17
updated: 2026-05-17
---

# CO-STAR

Singapore 政府 (GovTech) 発の 6 要素構造化プロンプトフレームワーク。
Sheila Teo が提唱し、2024 年のシンガポール政府主催 GovTech ハッカソンでプロンプトエンジニアリング最優秀賞を獲得。
Anthropic / OpenAI コミュニティでも広く参照される標準フレームワーク。

## 構成要素

| 要素      | 内容                       | 例                                             |
| --------- | -------------------------- | ---------------------------------------------- |
| Context   | 背景・前提情報             | 「シンガポール政府の若年層向け教育プログラム」 |
| Objective | LLM に達成させたい具体目的 | 「3 つの広告コピーを生成する」                 |
| Style     | 文体・書き方               | 「カジュアル、若者向け」                       |
| Tone      | 感情のトーン               | 「励まし、ポジティブ」                         |
| Audience  | 受け手                     | 「15-25 歳の学生」                             |
| Response  | 出力形式                   | 「箇条書き 3 つ、各 50 字以内」                |

## 使い分け

業務標準化・チーム展開で標準的に使われる。
日常タスクなら CRISPE、汎用一発指示なら深津式が軽量。
創造タスクなら BAB / CREATE、戦略立案なら COAST が適合。
他フレームワーク 8 種との比較は [[効果的なプロンプト設計の方法論]] 「3 層整理」セクションの「層 2」 を参照。

## 関連

- [[効果的なプロンプト設計の方法論]] — 3 層整理の層 2
- [[プロンプト設計原則]] — wiki page の書き方（Audience / Tone 設計）と wiki-style.md の根拠
