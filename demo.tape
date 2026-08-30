# README 冒頭に置く録画。`vhs demo.tape` で撮る。
#
# 撮る前に消すもの:
#   rm -rf ~/wiki/llm-wiki-kit ~/wiki/demo-wiki
#
# 再現するのは setup.sh まで。
# Claude の応答は毎回変わるので、最後の数秒は撮るたびに違う絵になる。

Output assets/llm-wiki-kit-demo.gif

Require git
Require claude

Set Shell "bash"
Set FontSize 15
Set Width 1100
Set Height 640
Set Padding 20
Set Framerate 20
Set TypingSpeed 30ms

# 作業ディレクトリとプロンプトを整える（録画には映さない）。
# CLAUDE_* / CMUX_* は、Claude Code や cmux の中から vhs を走らせた時に
# 子セッション扱いの警告がステータス行に出るので落とす。
Hide
Type `unset CLAUDECODE CLAUDE_CODE_CHILD_SESSION CLAUDE_CODE_ENTRYPOINT CLAUDE_CODE_SESSION_ID CLAUDE_CODE_MESSAGING_SOCKET CLAUDE_CODE_MESSAGING_TOKEN CLAUDE_CODE_BRIDGE_SESSION_ID CLAUDE_CODE_EXECPATH CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD CLAUDE_PID CLAUDE_EFFORT AI_AGENT NODE_OPTIONS`
Enter
Type "mkdir -p ~/wiki && cd ~/wiki"
Enter
# プロンプトはオレンジ、打ったコマンドはシアン、コマンドの出力は白。
# macOS の bash は 3.2 で PS0 を持たないので、色のリセットは DEBUG trap で行う。
Type `PS1='\[\033[38;5;209m\]$\[\033[0m\] \[\033[1;96m\]'`
Enter
Type `trap 'printf "\033[0m"' DEBUG`
Enter
Type "clear"
Enter
Show

Type "git clone https://github.com/yu-takahas/llm-wiki-kit.git"
Enter
Sleep 3s

Type "cd llm-wiki-kit"
Enter
Type "./setup.sh"
Enter
Sleep 1500ms

Type "~/wiki/demo-wiki"
Sleep 500ms
Enter
Sleep 2s

# npm install / lefthook / 初回 commit の待ちは飛ばす
Hide
Sleep 30s
Show
Sleep 3500ms

# Enter で Claude Code が起動する。
# 起動直後の画面はアカウント名と環境の警告が出るので映さない。
# 話しかけたあと、応答が伸びてその画面が流れ切ってから Show する。
Enter
Hide
Sleep 8s
Enter
Sleep 6s
Type "00_issues/tutorial-01-first-wiki.md を読んで、チュートリアルを始めたい。最初のステップから案内して"
Sleep 500ms
Enter
Sleep 18s
Show
Sleep 8s
