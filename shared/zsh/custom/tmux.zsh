function tmux-cli() {
  if tmux has-session -t tmux-cli 2>/dev/null; then
    tmux attach -t tmux-cli
    return
  fi

  tmux new-session -d -s tmux-cli -x "$(tput cols)" -y "$(tput lines)"

  tmux split-window -v -l 2 -t tmux-cli
  tmux split-window -h -t tmux-cli:0.0

  tmux send-keys -t tmux-cli:0.0 "cd $(pwd) && clear" Enter
  tmux send-keys -t tmux-cli:0.1 'claude' Enter
  tmux send-keys -t tmux-cli:0.2 'printf "  ctrl+b ←→ panes  |  ctrl+b c new window  |  ctrl+b d detach  |  tmux kill-session -t tmux-cli  |  ctrl+b [ scroll mode"; read' Enter

  tmux select-pane -t tmux-cli:0.0
  tmux attach -t tmux-cli
}