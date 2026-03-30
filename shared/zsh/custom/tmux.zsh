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

function tmux-dev() {
  if tmux has-session -t tmux-dev 2>/dev/null; then
    tmux attach -t tmux-dev
    return
  fi

  tmux new-session -d -s tmux-dev -x "$(tput cols)" -y "$(tput lines)"

  tmux split-window -v -l 2 -t tmux-dev
  tmux split-window -h -p 66 -t tmux-dev:0.0
  tmux split-window -h -p 50 -t tmux-dev:0.1

  tmux send-keys -t tmux-dev:0.0 "cd $(pwd) && clear" Enter
  tmux send-keys -t tmux-dev:0.1 "cd $(pwd) && clear" Enter
  tmux send-keys -t tmux-dev:0.2 'claude' Enter
  tmux send-keys -t tmux-dev:0.3 'printf "  ctrl+b ←→ panes  |  ctrl+b c new window  |  ctrl+b d detach  |  tmux kill-session -t tmux-dev  |  ctrl+b [ scroll mode"; read' Enter

  tmux select-pane -t tmux-dev:0.0
  tmux attach -t tmux-dev
}