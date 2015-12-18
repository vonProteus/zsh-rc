#
# Source at https://gist.github.com/nivertius/7fea1d83d56debc816ca
#
#---------------------------------- Configuration -----------------------------

DEFAULT_USER="nivertius"
EDITOR="vim"

#---------------------------------- Pre Setup ---------------------------------

autoload colors; colors

autoload -Uz add-zsh-hook

LAST_RETURN_VALUE=0

# Characters
PLUSMINUS="\u00b1"
BRANCH="\ue0a0"
DETACHED="\u27a6"
CROSS="\u2718"
LIGHTNING="\u26a1"
GEAR="\u2699"
BULLET="\u2022"
CROSSING="\u292c"

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

#---------------------------------- Tab completion ----------------------------

autoload -Uz compinit
compinit

# Force a reload of completion system if nothing matched; this fixes installing
# a program and then trying to tab-complete its name
_force_rehash() {
    (( CURRENT == 1 )) && rehash
    return 1    # Because we didn't really complete anything
}

# Always use menu completion, and make the colors pretty!
zstyle ':completion:*' menu select yes
zstyle ':completion:*:default' list-colors ''

# Completers to use: rehash, general completion, then various magic stuff and
# spell-checking.  Only allow two errors when correcting
zstyle ':completion:*' completer _force_rehash _complete _ignored _match _correct _approximate _prefix
zstyle ':completion:*' max-errors 2

# When looking for matches, first try exact matches, then case-insensiive, then partial word completion
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'r:|[._-]=** r:|=**'

# Turn on caching, which helps with e.g. apt
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Show titles for completion types and group by type
zstyle ':completion:*:descriptions' format "$fg_bold[black]» %d$reset_color"
zstyle ':completion:*' group-name ''

# Ignore some common useless files
zstyle ':completion:*' ignored-patterns '*?.pyc' '__pycache__'
zstyle ':completion:*:*:rm:*:*' ignored-patterns

# kill: advanced kill completion
zstyle ':completion::*:kill:*:*' command 'ps xf -U $USER -o pid,%cpu,cmd'
zstyle ':completion::*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;32'

zstyle :compinstall filename "$HOME/.zshrc"

# Always do mid-word tab completion
setopt complete_in_word

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
PRIMARY_FG=black

# Characters
SEGMENT_SEPARATOR="\ue0b0"

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n "%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%}"
  else
    print -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Root privileges
prompt_root() {
  if [[ $UID -eq 0 ]]; then
    prompt_segment red yellow " %(!.%{%F{yellow}%}.)$LIGHTNING "
  fi
}

# Different username
prompt_user() {
  local user=`whoami`

  if [[ "$user" != "$DEFAULT_USER" && $UID -ne 0 ]]; then
    prompt_segment magenta $PRIMARY_FG " %(!.%{%F{yellow}%}.)$user "
  fi
}

# Different host
prompt_host() {
  if [[ -n "$SSH_CONNECTION" ]]; then
    prompt_segment cyan $PRIMARY_FG " %m "
  fi
}

# VCS status
prompt_vcs() {
  local ref
  ref="$vcs_info_msg_0_"
  if [[ -n "$ref" ]]; then
    prompt_segment yellow $PRIMARY_FG " $ref "
  fi
}

# Dir: current working directory
prompt_mvn() {
  if [[ -n "$MAVEN_PROJECT_ARTIFACT" ]]; then
    prompt_segment magenta $PRIMARY_FG " $MAVEN_PROJECT_ARTIFACT@$MAVEN_PROJECT_VERSION "
  fi
}

# show current time
prompt_time() {
  local current_date
  current_date=`date +%R`
  prompt_segment green $PRIMARY_FG " ${current_date} "
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue $PRIMARY_FG ' %~ '
}

# Status:
# - was there an error
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  if [[ $LAST_RETURN_VALUE -ne 0 ]]; then
  	symbols+="%{%F{red}%}$CROSS"
	if [[ $LAST_RETURN_VALUE -ne 1 ]]; then
		symbols+="$CROSS $CROSS"
	fi
  fi
  if [[ $(jobs -l | wc -l) -gt 0 ]]; then
  	symbols+="%{%F{cyan}%}$GEAR"
  fi
  if [[ -n "$symbols" ]]; then
  	prompt_segment $PRIMARY_FG default " $symbols "
  fi
}

## Main prompt
prompt_main() {
  CURRENT_BG='NONE'
  prompt_time
  prompt_status
  prompt_root
  prompt_user
  prompt_host
  prompt_dir
  prompt_mvn
  prompt_vcs
  prompt_end
}

prompt_precmd() {
  vcs_info
  PROMPT="%{%f%b%k%}$(prompt_main) "
}


prompt_opts=(cr subst percent)

add-zsh-hook precmd prompt_precmd

#---------------------------------- VCS ---------------------------------------

autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git hg svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' get-revision true

# these formats are set for PROMPT
zstyle ':vcs_info:*' formats "%s $BRANCH%b $BULLET%i%u"
zstyle ':vcs_info:*' actionformats "%s $BRANCH%b $BULLET%i%u [%a]"
zstyle ':vcs_info:*' branchformat '%b'

zstyle ':vcs_info:hg*' unstagedstr "$PLUSMINUS"
zstyle ':vcs_info:hg*' hgrevformat "%r" # default "%r:%h"

zstyle ':vcs_info:git*' formats "%s $BRANCH%b%u"
zstyle ':vcs_info:git*' actionformats "%s $BRANCH%b%u [%a]"
zstyle ':vcs_info:git*' unstagedstr "$LIGHTNING"
zstyle ':vcs_info:git*' stagedstr "$PLUSMINUS"

#---------------------------------- Listings ----------------------------------

LSOPTS='-lAvF'  # long mode, show all, natural sort, type squiggles, friendly sizes
LLOPTS=''
case $(uname -s) in
    FreeBSD)
        LSOPTS="${LSOPTS} -G"
        ;;
    Linux)
        eval "$(dircolors -b)"
        LSOPTS="$LSOPTS --color=auto"
        LLOPTS="$LLOPTS --color=always"  # so | less is colored

        # Just loaded new ls colors via dircolors, so change completion colors
        # to match
        zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
        ;;
esac
alias ls="ls $LSOPTS"
alias ll="ls $LLOPTS | less -FX"

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

bindkey -e

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

# for non RH/Debian xterm, can't hurt for RH/Debian xterm
bindkey "\eOH" beginning-of-line
bindkey "\eOF" end-of-line
# for freebsd console
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line

# Tab completion
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

#---------------------------------- Maven ------------------------------------
# Coloring maven output
# based on https://gist.github.com/katta/1027800

mvn-color()
{
  # Filter mvn output using sed. Before filtering set the locale to C, so invalid characters won't break some sed implementations
  unset LANG
  LC_CTYPE=C mvn $@ | sed \
    -e "s/\(-\{20,\}\)/$fg_bold[black]\1$reset_color/g" \
    -e "s/Building \(.*\)/$fg_bold[magenta]\1$reset_color/g" \
    -e "s/--- \([^@]\+\)@\(.*\) ---/-- $fg_bold[magenta]\2$reset_color - $fg_bold[cyan]\1$reset_color ---/g" \
    -e "s/\(\(BUILD \)\?SUCCESS\)/$fg_bold[green]\1$reset_color/g" \
    -e "s/\(\(BUILD \)\?FAILURE\)/$fg_bold[red]\1$reset_color/g" \
    -e "s/\(SKIPPED\)/$fg_bold[yellow]\1$reset_color/g" \
  	-e "s/\(\[INFO\]\)\(.*\)/$fg_bold[blue]\1$reset_color\2/g" \
    -e "s/\(\[WARNING\]\)\(.*\)/$fg_bold[yellow]\1$reset_color\2/g" \
    -e "s/\(\[ERROR\]\)\(.*\)/$fg_bold[red]\1$reset_color\2/g" \
    -e "s/Tests run: \([^,]*\), Failures: \([^,]*\), Errors: \([^,]*\), Skipped: \([^,]*\)/$fg_bold[green]Tests run: \1$reset_color, Failures: $fg_bold[red]\2$reset_color, Errors: $fg_bold[red]\3$reset_color, Skipped: $fg_bold[yellow]\4$reset_color/g"
  # Make sure formatting is reset
  echo -ne "%{$reset_color%}"
}
alias mvn='mvn-color'

# Read project information from current directory - needed for prompt

maven_read_project() {
	local location parts
	location=$(find_up pom.xml)
	if [[ ! -r "$location" ]]; then
		MAVEN_PROJECT_ARTIFACT=""
		MAVEN_PROJECT_VERSION=""
		return 1;
	fi
	# executing xmllint takes some time, so this does it in single execution
	parts=($(echo "cat /*[local-name()='project']/*[local-name()='artifactId']/text()\n" \
				"cat /*[local-name()='project']/*[local-name()='version']/text()\n" \
				"cat /*[local-name()='project']/*[local-name()='parent']/*[local-name()='version']/text()\n" | \
		xmllint --shell $location | \
		sed '/^\/ >/d' | \
		sed '/^ -------/d'))
	MAVEN_PROJECT_ARTIFACT=${parts[1]}
	MAVEN_PROJECT_VERSION=${parts[2]}
}

add-zsh-hook chpwd maven_read_project

#---------------------------------- Miscellaneous ---------------------------- 

setopt extended_glob 
setopt nomatch # if there is match on file pattern, dont run command (instead of running command with unchanged parameters)
setopt interactive_comments # allow comments in command line
setopt csh_junkie_quotes # complain if a quoted expression runs off the end of a line; prevent quoted expressions from containing un-escaped newlines. 

unsetopt beep # (dont) beep on errors
unsetopt notify # (dont) report the status of background jobs immediately, rather than waiting until just before printing a prompt. 
unsetopt auto_cd # (dont) enter the directory that was inputed as command
unsetopt auto_remove_slash # (dont) remove last slash when next character is delimiter

# Don't count common path separators as word characters
WORDCHARS=${WORDCHARS//[&.;\/]}

# Report time if command takes too long
REPORTTIME=5

# Don't glob with find or wget
for command in find wget; \
    alias $command="noglob $command"

#---------------------------------- Post Setup --------------------------------

store_last_return_value() {
	LAST_RETURN_VALUE="$?"
}

# Store last return value into separate variable
# This must be exactly first precmd function, because other precmd might modify $?
precmd_functions=(store_last_return_value $precmd_functions)

#---------------------------------- Machine specific --------------------------

if [[ -r $HOME/.zlocal ]]; then
    source $HOME/.zlocal
fi

