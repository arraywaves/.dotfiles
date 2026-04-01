# .dotfiles
Maybe someone will find this useful, below this are just some reminders for myself while I work on making things more automated over time. 


## homebrew

**Install**:
`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

**Install packages:**
`brew bundle --file=path-to-brewfile`
*OR*
`export HOMEBREW_BUNDLE_FILE=path-to-brewfile`
`brew bundle`

[brew bundle/Brewfile Docs](https://docs.brew.sh/Brew-Bundle-and-Brewfile)


## infisical

**Add to .env**
`INFISICAL_API_URL="https://secrets-domain.tld"`
`INFISICAL_PROJECT_ID="shell-project-id"`
`INFISICAL_ENV="context-environment-slug"`

**Login**
`infisical login` or `infisical login -i` for browser-less login

**Setup**
`cd` into project and run `infisical init`

**Install pre-commit hook (per project):**
`infisical scan install --pre-commit-hook`

**Add to scripts:**
`infisical run --env=dev -- [rest of script]`


## zsh

**Add to `.zshrc`:**
`source ~/.dotfiles/shared/zsh/.ohmyzsh`

**Add custom plugins:**
`ln -s ~/.dotfiles/shared/zsh/plugins/pluginname ~/.oh-my-zsh/custom/plugins/pluginname`


## tmux

**Symlink conf:**
`ln -s ~/.dotfiles/shared/tmux/.tmux.conf ~/.tmux.conf`
  
**Symlink tmux macro file:**
`ln -s ~/.dotfiles/shared/zsh/custom/tmux.zsh ~/.oh-my-zsh/custom/tmux.zsh`


## zed

**Create Symlink**
`ln -s ~/.dotfiles/shared/zed/settings.json ~/.config/zed/settings.json`


## ghostty

**Add to end of default config:**
`config-file = /path/to/config`


## caddy + dnsmasq

**Run:**
`TERM=xterm-256color sudo nano /opt/homebrew/etc/dnsmasq.conf`
**Add:**
`address=/.localhost/127.0.0.1`

**Run:**
- `sudo mkdir -p /etc/resolver`
- `echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/localhost`
- `sudo brew services start dnsmasq`

**Setting up a project in Caddyfile:**
`projectname.localhost {
  reverse_proxy localhost:DEV_SERVER_PORT
}`

**Run:**
`caddy start` to start the service in the background.
`caddy run` to start the service in a terminal window.


## claude-code

Link dotfiles global CLAUDE.md instructions to claude-code: 
`ln -s ~/.dotfiles/shared/claude-code/CLAUDE.md ~/.claude/CLAUDE.md` // instructs claude to read and write to `AGENTS.md`

Link dotfiles skills to claude-code:
`rm -rf ~/.claude/skills` if dir already exists
`ln -s ~/.dotfiles/shared/claude-code/skills ~/.claude/skills`

**Tavily MCP**
in `.claude/settings.json` add:
`"env": {
	"TAVILY_API_KEY": "tvly-YOUR_API_KEY"
}`

`claude` and run `/plugin marketplace add tavily-ai/tavily-plugins` and `/plugin install tavily@tavily-plugins`

**Railway**
`railway login --browserless`
`claude mcp add railway-mcp-server -- vpx -y @railway/mcp-server`
`vpx skills add railwayapp/railway-skills`

**Context7 MCP**
`claude mcp add --scope user context7 -- vpx -y @upstash/context7-mcp --api-key YOUR_API_KEY`

## opencode

`export OPENCODE_CONFIG=path-to-opencode.json`


## python

**Set PATH:**
`echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc`
`echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc`
`echo 'eval "$(pyenv init - zsh)"' >> ~/.zshrc`
`source ~/.zshrc`

**Install Python (latest):**
`pyenv install 3.x` picks latest stable minor release in python3 automatically
`pyenv global 3.x.x` sets system python version


## vite+

**Install (check homebrew if reading this):**
`curl -fsSL https://vite.plus | bash`

**Commands:**
`vp create`				Create a new project
`vp env`					Manage Node.js versions
`vp env doctor`		Verify your Node setup
`vp env off`				Opt out of Node management
`vp install`				Install dependencies
`vp migrate`				Migrate to Vite+
`vp help`


## blender

**Open:** `~/.dotfiles/shared/blender/default.blend`
_File > Save Startup File > Confirm_


## macOS Performance Tip

"If you are using macOS, add your terminal app (Ghostty, iTerm2, Terminal, …) to the approved "Developer Tools" apps in the Privacy panel of System Settings and restart your terminal app. Your Rust builds will be about ~30% faster."
_Source: [vite+ contributing](https://github.com/voidzero-dev/vite-plus/blob/main/CONTRIBUTING.md#macos-performance-tip)_
