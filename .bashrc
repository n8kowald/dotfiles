# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Colours!
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

# Aliases
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ls='ls -hF --color=auto'
#alias ls='ls -FH'
alias lsd="ls -l | egrep '^d'"
alias ebrc='vim ~/.bashrc'
alias evrc='vim ~/.vimrc'
alias fu='sudo $(history -p !-1)'
alias reload='source ~/.bashrc && echo "Reloaded ~/.bashrc successfully"'
alias show_aliases="clear && grep -r -h 'alias' ~/dotfiles/ --exclude=.git* --exclude=HEAD* --exclude=master*"
alias dotfiles='cd ~/dotfiles'
#alias gh="open `git remote -v | grep fetch | awk '{print $2}' | sed 's/git@/http:\/\//' | sed 's/com:/com\//'`| head -n1"

extract () {
  if [ -f $1 ] ; then
      case $1 in
          *.tar.bz2)   tar xvjf $1    ;;
          *.tar.gz)    tar xvzf $1    ;;
          *.bz2)       bunzip2 $1     ;;
          *.rar)       rar x $1       ;;
          *.gz)        gunzip $1      ;;
          *.tar)       tar xvf $1     ;;
          *.tbz2)      tar xvjf $1    ;;
          *.tgz)       tar xvzf $1    ;;
          *.zip)       unzip $1       ;;
          *.Z)         uncompress $1  ;;
          *.7z)        7z x $1        ;;
          *)           echo "don't know how to extract '$1'..." ;;
      esac
  else
      echo "'$1' is not a valid file!"
  fi
}

# Grunt wrappers
function gi() {
	npm install --save-dev grunt-"$@"
}
export -f gi
function gci() {
	npm install --save-dev grunt-contrib-"$@"
}
export -f gci

# tmux aliases
alias tls="tmux list-sessions"
alias tma='tmux attach -t $2'
if [ -f /etc/bash_completion.d/tma ]; then
	. /etc/bash_completion.d/tma
fi

function tmh {
    printf "${YELLOW}New session:${NORMAL} tmux new -s session-name\n"
    printf "${YELLOW}Reopen session:${NORMAL} tmux attach -t session-name\n"
    printf "${YELLOW}Show sessions:${NORMAL} tmux ls\n"
    printf "${YELLOW}Kill session:${NORMAL} tmux kill-session -t tmux-config\n"
}

function seizure
{
    yes "$(seq 231 -1 16)" | while read i; do printf "\x1b[48;5;${i}m\n"; sleep .02; done
}

export LANG=en_US.UTF-8

# save all the histories
export HISTFILESIZE=1000000
export HISTSIZE=1000000

# don't put duplicate lines or empty spaces in the history
export HISTCONTROL=ignoreboth

# combine multiline commands in history
shopt -s cmdhist

# merge session histories
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
#shopt -s checkwinsize
  
# make the dir command work kinda like in windows (long format)
alias dir='ls --color=auto --format=long'
   
# make grep highlight results using color
export GREP_OPTIONS='--color=auto'

# Use Vim for the default editor
export SVN_EDITOR=vim
export VISUAL=vim
export EDITOR=vim

# folders to add to path
export PATH=$PATH:/lib/:/lib/node_modules/npm/bin/:/usr/local/bin/phpunit
export LD_LIBRARY_PATH=/usr/local/lib

source /home/nkowald/think-finance/tools/bash/think-finance.sh
