# skill 設計ガイド

## 対象タスク

使う: skill の新規設計と、既存 skill の設計変更（手順の追加・削除 / 判断基準の変更 / SSOT 分担の見直し）。
使わない: コードを書く issue（`dev-guide.md`）/ wiki page の作成 / 調査系のタスク。

---

skill 設計 issue を書くときのメニュー。
該当するセクション・行だけ issue にコピーする（該当しないものはコピーしない）。
コピーするのは着手する時。着手が遠い issue に全区切りを積むと、TODO の分量が作業の重さを誤認させる。
issue に既に区切り構造がある場合、guide の区切り見出しは持ち込まず該当行だけ差す。
項目の追加・並び替えは自由。
既存 skill の軽微な修正（typo / 1 行追記 / `allowed-tools` の 1 件追加）はこのガイドごとスキップしてよい。
ガイドごとでも行単位でも、スキップしたら 🪣 経緯に 1 行残す（コピー漏れとスキップ判断は guide 側からは区別できないため）。
設計書・規範・配布物の置き場を指すパス（`$KIT/docs/lw-kit/` / `$KIT/docs/knowledge/` / `$KIT/templates/`）は kit 開発の例。案件の置き場と一覧に読み替える。
`(ユーザー)` マークはユーザー本人が手を動かす項目（lead は実行せず、完了を待つ）。

---

## 設計判断

「案だし」で埋める（準備で読んだ結果を、設計書を書き始める前に判断へ落とす）。
全項目に「判断 + 根拠 1 行」を書く（チェックだけにしない）。
埋めた内容は設計書の正本になる（issue はドラフト置き場）。

- skill 名: <候補比較と採用理由>
- 配置: <global / project-local の判断根拠>
- `disable-model-invocation`: <true / false と根拠>
- `allowed-tools`: <最小リストと、各ツールが要る理由>
- description: <`disable-model-invocation: false` なら英語 third person、三単現動詞始まり。1 文目 = 何をするか、2 文目 = Triggers when ...。`true` なら description は context に載らないので日本語でよい>
- SSOT 分担宣言: why → 設計書 / how（具体値・条件式・列挙・手順）→ SKILL.md

## 先行例

参考にする既存の型。
設計書 1〜2 本 + FIXED issue 1 本を指名して書く。

---

## ☔ TODO

### 準備

規範は `$KIT/docs/knowledge/` の 5 本（`Claude-Code-Skillの書き方` / `Progressive-Disclosure` / `Claude-Codeのメモリ階層` / `プロンプト設計原則` / `レビューワークフローの設計原則`）。
`/lw-doc-review` がレビュー時に渡す規範と重なるので、書く前に読んで指摘を先に潰す。
レビュー時は対象 skill の種類で絞られるが、設計時は絞らない。

- [ ] 規範 5 本を読む
- [ ] 類似 skill の設計書（`$KIT/docs/lw-kit/40_スキル設計/`）と FIXED issue を精読し、「先行例」セクションに書き残す
- [ ] issue 内の参照（設計書のパス / skill 名 / `[[link]]`）が現存するか確認し、ずれていれば issue を先に直す

### 案だし

- [ ] advisor を含めて方針を議論し、選択肢と採否を issue に記録する
- [ ] 「設計判断」セクションを埋める（全項目、根拠付き）

### 設計書

机上ドッグフーディングの完了条件 = 発見した問題（または「問題なし」の宣言）が 🪣 経緯にある。
スキップ可 = 既存 skill の改修で手順の流れが変わらない場合のみ。

- [ ] 骨子を lead に提示して合意する（`.claude/rules/skeleton-confirm.md` 準拠）
- [ ] 設計書を書く（why + 却下代替案 + 不変条件。具体値・手順は SKILL.md に譲る前提で）
- [ ] 机上ドッグフーディング: 実在の対象 1 件に設計書の手順を頭から通す（結果を 🪣 経緯に記録）

### 設計書レビュー

- [ ] `/lw-doc-review` で設計書をレビューする
- [ ] `/lw-fix-review` で採否判断する

### SKILL.md

- [ ] SKILL.md の骨子を lead に提示して合意する（新規 skill の場合。既存 skill の部分改修は設計書の合意で代替してよい）
- [ ] SKILL.md を実装する（設計書の why を how に落とす。具体値・条件式・列挙はこちらが正本）
- [ ] `/lw-doc-review` で SKILL.md をレビューする（`allowed-tools` と本文の使用ツールの一致も見る）
- [ ] `/lw-fix-review` で採否判断する

### 横展開

skill を増減・改名したら以下を同期する（該当するものだけコピー）:

- [ ] `$KIT/docs/lw-kit/lw-kit-アーキテクチャ設計.md` の skill 一覧と用語集
- [ ] hub `$KIT/docs/lw-kit/lw-kit.md` のスキル設計一覧
- [ ] `.claude/rules/` の関連 rule（必要な場合）
- [ ] kit templates 側（`$KIT/templates/.claude/skills/`）への複製・同期
- [ ] skill 名を変えた場合: 旧名で全リポジトリを grep し、設定ファイル（`.doc-review.md` の glob 等）と他 SKILL.md / guide からの参照を追従する

### 動作確認

- [ ] (ユーザー) 新セッションで skill を起動し、実タスク 1 件を通す
- [ ] 問題があれば設計書に戻る（戻った事実と原因を 🪣 経緯に記録する）

### SSOT スリムダウン

完了条件 = 設計書に SKILL.md と同じ数値・閾値・リストが残っていない（残っていたら重複している）。
設計書に残すのは why + 却下代替案 + 保守規律。

- [ ] SKILL.md を正本に、設計書から具体値・条件式・列挙・手順の写しを削る（削減の before → after 行数を 🪣 経緯に記録）
