# vim:et sts=2 sw=2 ft=zsh
#
# A simple theme that displays relevant, contextual information.
#
# A simplified fork of the original sorin theme from
# https://github.com/sorin-ionescu/prezto/blob/master/modules/prompt/functions/prompt_sorin_setup
#
# Requires the `prompt-pwd`, `git-info` & `async` zmodules

#
# 16 Terminal Colors
# -- ---------------
#  0 black
#  1 red
#  2 green
#  3 yellow
#  4 blue
#  5 magenta
#  6 cyan
#  7 white
#  8 bright black
#  9 bright red
# 10 bright green
# 11 bright yellow
# 12 bright blue
# 13 bright magenta
# 14 bright cyan
# 15 bright white
#

_prompt_sorin_vimode() {
  case ${KEYMAP} in
    vicmd) print -n ' %B%F{2}❮%F{3}❮%F{1}❮%b' ;;
    *) print -n ' %B%F{1}❯%F{3}❯%F{2}❯%b' ;;
  esac
}

_prompt_sorin_keymap_select() {
  zle reset-prompt
  zle -R
}
if autoload -Uz is-at-least && is-at-least 5.3; then
  autoload -Uz add-zle-hook-widget && \
      add-zle-hook-widget -Uz keymap-select _prompt_sorin_keymap_select
else
  zle -N zle-keymap-select _prompt_sorin_keymap_select
fi

typeset -g VIRTUAL_ENV_DISABLE_PROMPT=1

setopt nopromptbang prompt{cr,percent,sp,subst}

zstyle ':zim:prompt-pwd:fish-style' dir-length 1

_prompt_sorin_async_callback() {
  case $1 in
    _prompt_sorin_async_git)
      _prompt_sorin_git="$3"
      zle && zle reset-prompt
      ;;
    "[async]")
      # Code is 1 for corrupted worker output and 2 for dead worker.
      if [[ $2 -eq 2 ]]; then
          typeset -g prompt_prezto_async_init=0
      fi
      ;;
  esac
}

function _prompt_sorin_async_git {
  cd -q "$1"
  if (( $+functions[git-info] )); then
    git-info
    print "${(e)git_info[status]}"
  fi
}

_prompt_sorin_async_tasks() {
  # Initialize async worker. This needs to be done here and not in
  # prompt_sorin_setup so the git formatting can be overridden by other prompts.
  if (( !${prompt_prezto_async_init:-0} )); then
    async_start_worker prompt_sorin -n
    async_register_callback prompt_sorin _prompt_sorin_async_callback
    typeset -g prompt_prezto_async_init=1
  fi

  # Kill the old process of slow commands if it is still running.
  async_flush_jobs prompt_sorin

  # Compute slow commands in the background.
  async_job prompt_sorin _prompt_sorin_async_git "$PWD"
}

_prompt_sorin_precmd() {
  setopt LOCAL_OPTIONS
  unsetopt XTRACE KSH_ARRAYS

  # Format PWD.
  _prompt_sorin_pwd=$(prompt-pwd)

  # Handle updating git data. We also clear the git prompt data if we're in a
  # different git root now.
  local new_git_root="${$(git rev-parse --git-dir 2>/dev/null || return 0):A}"
  if [[ $new_git_root != $_sorin_cur_git_root ]]; then
    _prompt_sorin_git=''
    _sorin_cur_git_root=$new_git_root
  fi

  _prompt_sorin_async_tasks
}

typeset -gA git_info
if (( ${+functions[git-info]} )); then
  # Set git-info parameters.
  zstyle ':zim:git-info' verbose yes
  zstyle ':zim:git-info:action' format '%F{7}:%F{9}%s'
  zstyle ':zim:git-info:ahead' format ' %F{13}⬆'
  zstyle ':zim:git-info:behind' format ' %F{13}⬇'
  zstyle ':zim:git-info:branch' format ' %F{2}%b'
  zstyle ':zim:git-info:commit' format ' %F{3}%c'
  zstyle ':zim:git-info:indexed' format ' %F{2}✚'
  zstyle ':zim:git-info:unindexed' format ' %F{4}✱'
  zstyle ':zim:git-info:position' format ' %F{13}%p'
  zstyle ':zim:git-info:stashed' format ' %F{6}✭'
  zstyle ':zim:git-info:untracked' format ' %F{7}◼'
  zstyle ':zim:git-info:keys' format \
    'status' '%%B$(coalesce "%b" "%p" "%c")%s%A%B%S%i%I%u%f%%b'

  # Add hook for calling git-info before each command.
  autoload -Uz add-zsh-hook && add-zsh-hook precmd _prompt_sorin_precmd
fi

# Define prompts.
PS1='${SSH_TTY:+"%F{9}%n%F{7}@%F{3}%m "}%F{4}${_prompt_sorin_pwd}%b%(!. %B%F{1}#%b.)$(_prompt_sorin_vimode)%f '
RPS1='${VIRTUAL_ENV:+"%F{3}(${VIRTUAL_ENV:t})"}%(?:: %F{1}✘ %?)${VIM:+" %B%F{6}V%b"}${(e)_prompt_sorin_git}%f'
SPROMPT='zsh: correct %F{1}%R%f to %F{2}%r%f [nyae]? '
