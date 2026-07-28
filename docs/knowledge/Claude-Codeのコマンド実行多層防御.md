---
type: concept
tags: [claude-code, security, defense-in-depth, bash, hook]
sources: []
created: 2026-05-29
updated: 2026-07-07
---

# Claude-Codeのコマンド実行多層防御

危険な Bash コマンド（`rm -rf /` のような破壊的操作）を Claude Code で防ぐには、単一の対策ではなく複数のレイヤーを重ねる。
1 つの層が破られても次の層で止める、という defense in depth の考え方を Claude Code の設定機構に当てはめたもの。

## 3 つの防御層

| 層              | 役割                               | 強度 | 実装コスト |
| --------------- | ---------------------------------- | ---- | ---------- |
| `settings.json` | 権限の基盤（allow/deny + sandbox） | 中   | 低         |
| PreToolUse hook | 実行直前のコマンド内容検査         | 高   | 中         |
| `CLAUDE.md`     | 方針の明示（意図の伝達）           | 低   | 低         |

層を重ねる利点は冗長性にある。
`settings.json` の deny を擦り抜けても hook が内容を見て止め、hook をバイパスされても sandbox がファイルシステムの到達範囲を縛る。

### レイヤー1: settings.json（権限 + サンドボックス）

権限の基盤層。
`permissions.allow` / `permissions.deny` で許可・拒否するツール呼び出しを宣言し、`sandbox` でファイルシステム・ネットワーク・プロセスの到達範囲を制限する。

サンドボックスは Claude Code 標準で有効。
無効化には明示フラグ（`--dangerously-disable-sandbox`）を要求する設計で、`filesystem.allowedDirs` を `$PROJECT_DIR` に絞り `deniedDirs` でシステムディレクトリ（`/` / `/etc` / `/usr` 等）を守る。
ネットワークも `allowedDomains` で許可先を限定できる。

settings.json の仕様一般は [[Claude-Code-settings.json]] を参照。

### レイヤー2: PreToolUse hook（実行前検査）

3 層で最も強い層。
ツール実行の直前に Bash コマンド文字列を受け取り、正規表現で危険パターン（`rm -rf /` / `dd` / `sudo` / fork bomb 等）を検査する。
マッチしたら `exit 2` を返して Claude にブロックを通知する。

settings.json の allow/deny がコマンドの先頭しか見ないのに対し、hook は引数まで含めた中身を検査できる。
これが「パターンマッチの限界」を補完する核心になる。
hook 機構一般は [[Claude-Code-Hook]] を参照。

### レイヤー3: CLAUDE.md（方針明示）

最も弱い補助層。
全セッションで自動ロードされ「`rm` は使わない」等の方針を Claude に伝えるが、文章による指示なので従わないリスクが残る。
enforcement を保証する力はなく、意図の共有に留まる（確実性が要るなら hook に倒す、判断軸は [[Claude-Code-Hook]]「CLAUDE.md との使い分け」セクション）。

## パターンマッチの限界

`allowed-tools: Bash(rm *)` のようなパターンはコマンドの先頭にマッチするだけで、引数の中身（`-rf /` か `-i ./tmp/x` か）までは区別できない。
つまり settings.json 単体では「`rm` を許可するが破壊的な `rm` だけ止める」ができない。
この穴を PreToolUse hook の内容検査が埋める、という分担が多層防御の要になる。

## llm-wiki での参照

lw-archive-weekly skill はファイル移動に `rm` を必要とするため `rm` を許可している。
その安全性を、sandbox による `$PROJECT_DIR` 限定（プロジェクト外に到達させない）と hook による危険パターン検出の 2 層で担保する。
許可しつつ破壊的操作だけ塞ぐ、という判断がこのパターンの典型適用例になっている。

## 関連

- [[Claude-Code-settings.json]] — 基盤層の権限・sandbox 設定
- [[Claude-Code-Hook]] — 検査層となる PreToolUse hook の仕組み
