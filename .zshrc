#
# Source at https://github.com/nivertius/zsh-rc/
# Download Powerline-patched fonts from
#    https://github.com/powerline/fonts
#
#---------------------------------- Pre Setup ---------------------------------

autoload colors; colors

autoload -Uz add-zsh-hook

LAST_RETURN_VALUE=0

# Characters
if [[ -n $(echo '\u2603' 2>/dev/null) ]] then
  MULTIBYTE_SUPPORTED="\u2603"
fi

if [[ -n $MULTIBYTE_SUPPORTED ]] then
  UNSTAGED_CHARACTER="\u26a1"
  CHANGES_CHARACTER="\u00b1"
  BRANCH_CHARACTER="\ue0a0"
  DETACHED_CHARACTER="\u27a6"
  REVISION_CHARACTER="\u2022"
  FAILED_CHARACTER="\u2718"
  SUCCESS_CHARACTER="\u2714"
  SUPERUSER_CHARACTER="\u26a1"
  JOBS_CHARACTER="\u2699"
  NO_JOBS_CHARACTER="\u2022"
  SEGMENT_SEPARATOR_FORWARD="\ue0b0"
  SEGMENT_SEPARATOR_BACKWARD="\ue0b2"
else
  UNSTAGED_CHARACTER="!"
  CHANGES_CHARACTER="*"
  BRANCH_CHARACTER="~"
  DETACHED_CHARACTER="%"
  REVISION_CHARACTER="r"
  FAILED_CHARACTER="X"
  SUCCESS_CHARACTER="V"
  SUPERUSER_CHARACTER="#"
  JOBS_CHARACTER="O"
  NO_JOBS_CHARACTER="."
  SEGMENT_SEPARATOR_FORWARD=""
  SEGMENT_SEPARATOR_BACKWARD=""
fi


#---------------------------------- Helpers -----------------------------------

# Search file up in directory tree. Either print path to found file or nothing
find_up () {
  path=$(pwd)
  while [[ "$path" != "" ]]; do
    if [[ -e "$path/$1" ]]; then
    	echo "$path/$1"
    	return;
    fi
    path=${path%/*}
  done
}

command-exists () {
  return $(command -v $1 >/dev/null);
}

#---------------------------------- Listings ----------------------------------

if command-exists dircolors; then
    eval "$(dircolors -b)"
fi
LSOPTS="-lAvF --color=auto" # long mode, show all, natural sort, type squiggles, friendly sizes
LLOPTS="--color=always"  # so | less is colored

alias ls="ls $LSOPTS"
alias ll="ls $LLOPTS | less -FX"

#---------------------------------- Tab completion ----------------------------

# Force a reload of completion system if nothing matched; this fixes installing
# a program and then trying to tab-complete its name
_force_rehash() {
    (( CURRENT == 1 )) && rehash
    return 1    # Because we didn't really complete anything
}

# Always use menu completion, and make the colors pretty!
zstyle ':completion:*' menu select yes
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Completers to use: rehash, general completion, then various magic stuff and
# spell-checking.  Only allow two errors when correcting
zstyle ':completion:*' completer _force_rehash _complete _ignored _match _correct _approximate _prefix
zstyle ':completion:*' max-errors 2

# When looking for matches, first try exact matches, then case-insensiive, then partial word completion
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'r:|[._-]=** r:|=**'

# Turn on caching, which helps with e.g. apt
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh/cache"
mkdir -p $HOME/.zsh/cache

# Show nice warning when nothing matched
zstyle ':completion:*:warnings' format '%No matches: %d%b'

# Show titles for completion types and group by type
zstyle ':completion:*:descriptions' format "%U%B%F{yellow}» %d%u%b%f"
zstyle ':completion:*' group-name ''

# Ignore some common useless files
zstyle ':completion:*' ignored-patterns '*?.pyc' '__pycache__'
zstyle ':completion:*:*:rm:*:*' ignored-patterns

# Directories
zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
zstyle ':completion:*' squeeze-slashes true

# kill: advanced kill completion
zstyle ':completion::*:kill:*:*' command 'ps xf -U $USER -o pid,%cpu,cmd'
zstyle ':completion::*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;32'

# sudo completion
zstyle ':completion:*:sudo:*' command-path append /sbin /usr/sbin

SSH_HOSTS=($([[ -f $HOME/.ssh/config ]] && print -n $(cat $HOME/.ssh/config | sed '/^Host [^*]/!d;s/Host *\([^ \#]\+\)/\1/' | sort)))

zstyle ':completion:*:ssh:*' hosts $SSH_HOSTS
zstyle ':completion:*:scp:*' hosts $SSH_HOSTS
zstyle ':completion:*:ssh:*' users # disables users completion
zstyle ':completion:*:scp:*' users # disables users completion

# maven completions (from zsh-users/zsh-completions)
zstyle ':completion:*:*:mvn:*:matches' group 'yes'
zstyle ':completion:*:*:mvn:*:options' description 'yes'
zstyle ':completion:*:*:mvn:*:options' auto-description '%d'

# Always do mid-word tab completion
setopt complete_in_word

# don't expand aliases _before_ completion has finished
setopt complete_aliases

#---------------------------------- Corrections -------------------------------

# dont correct arguments to dot-files
CORRECT_IGNORE='[._]*'
CORRECT_IGNORE_FILE='[._]*'

#---------------------------------- Prediction --------------------------------

autoload predict-on
autoload predict-off

zle -N predict-on
zle -N predict-off
bindkey "^Z" predict-on    # C-z
bindkey "^X^Z" predict-off # C-x C-z 

#---------------------------------- History -----------------------------------

setopt append_history # Allow multiple terminal sessions to all append to one zsh command history
setopt extended_history # save timestamp of command and duration
setopt inc_append_history # Add comamnds as they are typed, don't wait until shell exit
setopt hist_expire_dups_first # when trimming history, lose oldest duplicates first
setopt hist_ignore_dups # Do not write events to history that are duplicates of previous events
setopt hist_ignore_space # remove command line from history list when first character on the line is a space
setopt hist_find_no_dups # When searching history don't display results already cycled through twice
setopt hist_reduce_blanks # Remove extra blanks from each command line being added to history
setopt hist_verify # don't execute, just expand history
setopt share_history # imports new commands and appends typed commands to history
setopt hist_no_store # remove the history (fc -l) command from the history when invoked. 

export HISTFILE=~/.zsh_history
export HISTSIZE=1000000
export SAVEHIST=1000000

#---------------------------------- Prompt ------------------------------------

# Based on agnoster's Theme - https://gist.github.com/3712874

CURRENT_BG='NONE'

prompt_segment() {
  local direction newbg newfg text
  direction="$1"
  newbg="$2"
  newfg="$3"
  text="$4"
  if [[ -z $text ]]; then return; fi
  if [[ $newbg != $CURRENT_BG ]]; then
	if [[ "$direction" == 'forward' ]]; then
		if [[ $CURRENT_BG != 'NONE' ]]; then
		    print -n "%{%K{$newbg}%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR_FORWARD%{%F{$newfg}%}"
		else 
		    print -n "%{%K{$newbg}%F{$newfg}%}"
		fi
	else
	    print -n "%{%F{$newbg}%}$SEGMENT_SEPARATOR_BACKWARD%{%F{$newfg}%K{$newbg}%}"
	fi
  fi
  print -n " $text "
  CURRENT_BG=$newbg
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR_FORWARD"
  fi
  CURRENT_BG=''
}

prompt_clear() {
  print -n "%{%k%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Root privileges
prompt_root() {
  if [[ $UID -eq 0 ]]; then
    print -n $SUPERUSER_CHARACTER
  fi
}

# Different username
prompt_user() {
  local user=$USER
  if command-exists whoami && [[ -z $user ]] then
    user=$(whoami)
  fi
  if [[ "$user" != "$DEFAULT_USER" && $UID -ne 0 ]]; then
    print -n $user
  fi
}

# Different host
prompt_host() {
  if [[ -n "$SSH_CONNECTION" ]]; then
    print -n "%m"
  fi
}

# Makefile exists
prompt_makefile() {
  if [[ -f Makefile ]]; then
    print -n "make"
  fi
}


# Status:
# - was there an error
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  if [[ $LAST_RETURN_VALUE -ne 0 ]]; then
    symbols+="%{%F{red}%}$FAILED_CHARACTER%{%f%}"
  else
    symbols+="%{%F{green}%}$SUCCESS_CHARACTER%{%f%}"
  fi
  if [[ $(jobs -l | wc -l) -gt 0 ]]; then
    symbols+="%{%F{cyan}%}$JOBS_CHARACTER%{%f%}"
  else
    symbols+="%{%F{white}%}$NO_JOBS_CHARACTER%{%f%}"
  fi
  echo "$symbols"
}

## Main prompt
prompt_forward() {
  CURRENT_BG='NONE'
  prompt_segment forward black   default "$(prompt_status)"
  prompt_segment forward red     yellow  "$(prompt_root)"
  prompt_segment forward magenta black   "$(prompt_user)"
  prompt_segment forward cyan    black   "$(prompt_host)"
  prompt_segment forward blue    black   '%~'               # prompt directory
  prompt_end
  prompt_clear
}

## Reverse prompt
prompt_backward() {
  CURRENT_BG='NONE'
  prompt_segment backward magenta black   "$MAVEN_PROJECT"   # prompt maven project
  prompt_segment backward cyan    black   "$(prompt_makefile)"
  prompt_segment backward yellow  black   "$vcs_info_msg_0_" # prompt vcs
  prompt_segment backward green   black   "%T"      # prompt time
  prompt_clear
}

prompt2_forward() {
  CURRENT_BG='NONE'
  prompt_segment forward black   default "$(prompt_status)"
  prompt_segment forward red     yellow  "$(prompt_root)"
  prompt_segment forward magenta black   "$(prompt_user)"
  prompt_segment forward cyan    black   "$(prompt_host)"
  prompt_segment forward blue    black   '%~'               # prompt directory
  prompt_segment forward red     black   '%_'               # unmatched quote
  prompt_end
  prompt_clear
}

prompt_precmd() {
  vcs_info
  PROMPT="%{%f%b%k%}$(prompt_forward) "
  PS="$PROMPT"
  PS2="%{%f%b%k%}$(prompt2_forward) "
  RPROMPT="%{%f%b%k%}$(prompt_backward)"
  PRS="$RPROMPT"
  SPROMPT="Correct %{%F{red}%}%R%{%f%} to %{%F{green}%}%r%f? [%Uy%ues|%Un%uo|%Ua%ubort|%Ue%udit] "
}

ZLE_RPROMPT_INDENT=1
prompt_opts=(cr subst percent)

add-zsh-hook precmd prompt_precmd

#---------------------------------- VCS ---------------------------------------

autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git hg svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' get-revision true

# these formats are set for PROMPT
zstyle ':vcs_info:*' formats "%s $BRANCH_CHARACTER%b $REVISION_CHARACTER%i%u"
zstyle ':vcs_info:*' actionformats "%s $BRANCH_CHARACTER%b $REVISION_CHARACTER%i%u [%a]"
zstyle ':vcs_info:*' branchformat '%b'

zstyle ':vcs_info:hg*' unstagedstr "$CHANGES_CHARACTER"
zstyle ':vcs_info:hg*' hgrevformat "%r" # default "%r:%h"

zstyle ':vcs_info:git*' formats "%s $BRANCH_CHARACTER%b%u"
zstyle ':vcs_info:git*' actionformats "%s $BRANCH_CHARACTER%b%u [%a]"
zstyle ':vcs_info:git*' unstagedstr "$UNSTAGED_CHARACTER"
zstyle ':vcs_info:git*' stagedstr "$CHANGES_CHARACTER"

#---------------------------------- Screen ------------------------------------


function title {
    # param: title to use

    local prefix=''

    # If I'm in a screen, all the windows are probably on the same machine, so
    # I don't really need to title every single one with the machine name.
    # On the other hand, if I'm not logged in as me (but, e.g., root), I'd
    # certainly like to know that!
    if [[ $USER != "$DEFAULT_USER" ]]; then
        prefix="[$USER] "
    fi
    # Set screen window title
    if [[ $TERM == "screen"* ]]; then
        print -n "\ek$prefix$1\e\\"
    fi


    # Prefix the xterm title with the current machine name, but only if I'm not
    # on a local machine.  This is tricky, because screen won't reliably know
    # whether I'm using SSH right now!  So just assume I'm local iff I'm not
    # running over SSH *and* not using screen.  Local screens are fairly rare.
    prefix=$HOST
    if [[ $SSH_CONNECTION == '' && $TERM != "screen"* ]]; then
        prefix=''
    fi
    # If we're showing host and not default user prepend it
    if [[ $prefix != '' && $USER != "$DEFAULT_USER" ]]; then
        prefix="$USER@$prefix"
    fi
    # Wrap it in brackets
    if [[ $prefix != '' ]]; then
        prefix="[$prefix] "
    fi

    # Set xterm window title
    if [[ $TERM == "xterm"* || $TERM == "screen"* ]]; then
        print -n "\e]2;$prefix$1\a"
    fi
}

function title_precmd {
    # Shorten homedir back to '~'
    local shortpwd=${PWD/$HOME/\~}
    title "zsh $shortpwd"
}

function title_preexec {
    title $*
}

add-zsh-hook preexec title_preexec
add-zsh-hook precmd title_precmd

#---------------------------------- Bindings ----------------------------------

bindkey -v

# General movement
# Taken from http://wiki.archlinux.org/index.php/Zsh and Ubuntu's inputrc
bindkey "\e[1~" beginning-of-line
bindkey "\e[4~" end-of-line
bindkey "\e[5~" beginning-of-history
bindkey "\e[6~" end-of-history
bindkey "\e[3~" delete-char
bindkey "\e[2~" quoted-insert
bindkey "\e[1;5C" forward-word
bindkey "\e[1;5D" backward-word
bindkey "\e[5C" forward-word
bindkey "\eOc" emacs-forward-word
bindkey "\e[5D" backward-word
bindkey "\eOd" emacs-backward-word
bindkey "\e\e[C" forward-word
bindkey "\e\e[D" backward-word

bindkey ' ' magic-space # do history expansion on space

# for non RH/Debian xterm, can't hurt for RH/Debian xterm
bindkey "\eOH" beginning-of-line
bindkey "\eOF" end-of-line
# for freebsd console
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line

# Tab completion
bindkey "^r" history-incremental-search-backward
bindkey '^i' complete-word              # tab to do menu
bindkey "\e[Z" reverse-menu-complete    # shift-tab to reverse menu

# Up/down arrow.
# I want shared history for ^R, but I don't want another shell's activity to
# mess with up/down.  This does that.
down-line-or-local-history() {
    zle set-local-history 1
    zle down-line-or-history
    zle set-local-history 0
}
zle -N down-line-or-local-history
up-line-or-local-history() {
    zle set-local-history 1
    zle up-line-or-history
    zle set-local-history 0
}
zle -N up-line-or-local-history

bindkey "\e[A" up-line-or-local-history
bindkey "\e[B" down-line-or-local-history

#---------------------------------- Aliases ----------------------------------

# Use interactive sudo instead of su
alias su="sudo -u root -i"
# disable sudo correction for commands
alias sudo="nocorrect sudo"

# More powerful terminal reset
#   \e< - resets \e[?2l which puts terminal into VT52 mode
#   reset - normal terminal reset
#   stty sane - puts tty in sane state (like accepting input, no character translation etc.)
#   setterm -reset - puts reset terminal string, as identified by setterm
#   tput reset - puts terminal reset strings from terminfo
#   clear - simple clear terminal window
#   \033c - exactly "<ESC>c" which is VT100 code for resetting terminal
alias reset='echo -e "\e<"; reset; stty sane; setterm -reset; tput reset; clear; echo -e "\033c"'

# Shortcuts for clipboard manipulation
alias xclip-in='xclip -selection c -in'
alias xclip-out='xclip -selection c -out'

#---------------------------------- VIM pager --------------------------------

vim_pager() {
	local source_file;
	if [ ! -t 1 ]; then
		echo "Cannot use vim pager with non-terminal output" 1>&2
		return 1
	fi
	if [ $# -gt 0 ]; then
		source_file="$@";
	elif [ ! -t 0 ]; then
		source_file="-";
	else
		echo "Input stream or file name missing" 1>&2
		return 2
	fi
	vim --cmd 'let no_plugin_maps = 1' -c 'runtime! macros/less.vim' $source_file
}
alias vless='vim_pager'

#---------------------------------- Maven ------------------------------------
# Read project information from current directory - needed for prompt

maven_read_project() {
	local location parts
	location=$(find_up pom.xml)
	if [[ ! -r "$location" || -z $commands[xmllint] ]]; then
		MAVEN_PROJECT=""
		return 1;
	fi
	# executing xmllint takes some time, so this does it in single execution
	parts=($(echo "cat /*[local-name()='project']/*[local-name()='artifactId']/text()\n" \
				"cat /*[local-name()='project']/*[local-name()='version']/text()\n" \
				"cat /*[local-name()='project']/*[local-name()='parent']/*[local-name()='version']/text()\n" | \
		xmllint --shell $location 2>/dev/null | \
		sed '/^\/ >/d' | \
		sed '/^ -------/d'))
	if [[ "${#parts}" > 1 ]]; then
		MAVEN_PROJECT="${parts[1]}@${parts[2]}"
	else 	
		MAVEN_PROJECT="pom!"
	fi;
}

add-zsh-hook chpwd maven_read_project

#---------------------------------- Copy zshrc remote -------------------------

sshc() {
	local source target
	source=${ZDOTDIR:-$HOME}
	target="/tmp/.zdot-${RANDOM}"
	ssh -q -o "ControlPath=/tmp/.cm-%r@%h:%p" -o "ControlMaster=yes" -o "ControlPersist=yes" $1 'false'
	ssh -q -o "ControlPath=/tmp/.cm-%r@%h:%p" $1 "mkdir $target"
	scp -q -o "ControlPath=/tmp/.cm-%r@%h:%p" $source/.zshrc $1:$target/.zshrc
	ssh -q -o "ControlPath=/tmp/.cm-%r@%h:%p" $1 -t "ZDOTDIR=$target exec zsh -l"
	ssh -q -o "ControlPath=/tmp/.cm-%r@%h:%p" $1 "rm -r $target"
	ssh -q -o "ControlPath=/tmp/.cm-%r@%h:%p" -O stop $1 
}

#---------------------------------- Miscellaneous ---------------------------- 

setopt extended_glob 
setopt correct # try to correct the spelling of commands. 
setopt correct_all # try to correct the spelling of all arguments in a line. 
setopt numeric_glob_sort # if numeric filenames are matched by a filename generation pattern, sort the filenames numerically rather than lexicographically. 
setopt nomatch # if there is match on file pattern, dont run command (instead of running command with unchanged parameters)
setopt interactive_comments # allow comments in command line
setopt multios # enable multiple input/output redirections that work as expected

unsetopt beep # (dont) beep on errors
unsetopt notify # (dont) report the status of background jobs immediately, rather than waiting until just before printing a prompt. 
unsetopt auto_cd # (dont) enter the directory that was inputed as command
unsetopt auto_remove_slash # (dont) remove last slash when next character is delimiter
unsetopt csh_junkie_quotes # (dont) complain if a quoted expression runs off the end of a line; prevent quoted expressions from containing un-escaped newlines. 

# Don't count common path separators as word characters
WORDCHARS=${WORDCHARS//[&.;\/]}

# Report time if command takes too long
REPORTTIME=5

TIMEFMT=$(echo "$fg[green]${SEGMENT_SEPARATOR_BACKWARD}$bg[green]$fg[black] %*Es $fg[yellow]$SEGMENT_SEPARATOR_BACKWARD$bg[yellow]$fg[black] %P $reset_color")

# Don't glob with commands that expects glob patterns
for command in find wget git; \
    alias $command="noglob $command"

# load zsh extended move
autoload -Uz zmv

#---------------------------------- Machine specific --------------------------

if [[ -r $HOME/.zlocal ]]; then
    source $HOME/.zlocal
fi

#---------------------------------- Post Setup --------------------------------

# at last initialize completion
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

store_last_return_value() {
	LAST_RETURN_VALUE="$?"
}

# Store last return value into separate variable
# This must be exactly first precmd function, because other precmd might modify $?
precmd_functions=(store_last_return_value $precmd_functions)


