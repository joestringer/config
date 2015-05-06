# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

if [ "x$(ip netns identify $$)" != "x" ]; then
    namespace="[$(ip netns identify $$)]"
fi

use_color=true

# Set colorful PS1 only on colorful terminals.
# dircolors --print-database uses its own built-in database
# instead of using /etc/DIR_COLORS.  Try to use the external file
# first to take advantage of user additions.  Use internal bash
# globbing instead of external grep binary.
safe_term=${TERM//[^[:alnum:]]/?}   # sanitize TERM
match_lhs=""
[[ -f ~/.dir_colors   ]] && match_lhs="${match_lhs}$(<~/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs}    ]] \
        && type -P dircolors >/dev/null \
        && match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true

if ${use_color} ; then
        # Enable colors for ls, etc.  Prefer ~/.dir_colors #64489
        if type -P dircolors >/dev/null ; then
                if [[ -f ~/.dir_colors ]] ; then
                        eval $(dircolors -b ~/.dir_colors)
                elif [[ -f /etc/DIR_COLORS ]] ; then
                        eval $(dircolors -b /etc/DIR_COLORS)
                fi
        fi

        if [[ ${EUID} == 0 ]] ; then
                PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\h\[\033[01;33m\]${namespace}\[\033[01;34m\] \W \$\[\033[00m\] '
        else
                PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[01;33m\]${namespace}\[\033[01;34m\] \w \$\[\033[00m\] '
        fi

        alias ls='ls --color=auto'
        alias grep='grep --colour=auto'
else
        if [[ ${EUID} == 0 ]] ; then
                # show root@ when we don't have colors
                PS1='\u@\h \W \$ '
        else
                PS1='\u@\h \w \$ '
        fi
fi

# Try to keep environment pollution down, EPA loves us.
unset use_color safe_term match_lhs

# enable bash completion in interactive shells
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# Client-specific settings
if [ -e ~/.bashrc.local ]; then
    source ~/.bashrc.local
fi

# Personal Settings
export EDITOR=vim
alias ll="ls -lh"
alias ll="ls -lha"
alias nv="nano -v"
alias nt="nano -E"
alias gi="git di"
alias show="git show"
alias lr="less -r"
alias :e="vim"

# Tmux Attach
function ta() {
    if [ $# -eq 0 ]; then
        SESSION=0;
    else
        SESSION=$1
    fi

    # Prevent nesting
    if [ -n "$TMUX" ]; then
        echo "Thwarted an attempt to nest tmux sessions."
        return 1
    fi

    tmux has-session -t $SESSION
    if [ $? -ne 0 ]; then
        tmux new-session -d -s $SESSION;
    fi

    # Clear unattached sessions
    IDLE=$(tmux ls 2>/dev/null | egrep "^.*\.[0-9]{14}.*[0-9]+\)$" | cut -f 1 -d:)
    for old_session_id in $IDLE; do
        tmux kill-session -t $IDLE
    done

    CLIENTID=$SESSION+`date +%Y%m%d%H%M%S`
    tmux new-session -d -t $SESSION -s $CLIENTID
    tmux attach-session -t $CLIENTID
    tmux kill-session -t $CLIENTID
}

# Keep trying
function kt()
{
    while true; do
        $*;
        sleep 1;
    done
}

function watchmake() {
    while true; do
        inotifywait -q -e move $1;
        make;
        sleep 1;
    done
}

# Grep recursive
function gr()
{
    if [ "$#" == "1" ]
    then
        grep -r "$*" . | grep -vE "(cscope|tags|.git|testsuite|_build*)" | grep "$*"
    elif [ "$#" -ge "2" ]
    then
        grep -r $*
    else
        echo `grep`
    fi
}

# Git send email with prompt.
function gse()
{
    if [ `git diff | wc -l` -ne 0 ] || [ `git diff --cached | wc -l` -ne 0 ]; then
        echo "There are uncommitted changes in the tree."
        return
    fi
    echo "Have you run 'make check' yet?"
    echo "What's the shape of the patch?"
    echo "Which branch is this for?"
    echo
    read -r -p "Continue? [y/N] " response
    case "$response" in
        [yY])
            git send-email "$@"
            ;;
        *)
            ;;
    esac
}

# Git push upstream with prompts.
function gpu()
{
    echo "Patches between upstream and local master:"
    git log --oneline upstream/master..core/master
    echo
    echo "Have you run 'make check'?"
    echo "Do the patches have their Acks?"
    echo
    read -r -p "exec 'git push upstream core/master:master'? [y/N] " response
    case $response in
        [yY])
            git push upstream core/master:master
            ;;
        *)
            ;;
    esac
}

# Given current git branch foo.X, create and switch to branch foo.X+1.
function gcn()
{
    branch=`git status | head -n 1 | cut -s -d' ' -f 4-`

    echo $branch | grep -q '\.'
    if [ $? -eq 0 ]; then
        base=`echo $branch | cut -s -d'.' -f -1`
        version=`echo $branch | cut -s -d'.' -f 2-`
        new_branch=$base.`echo "$version + 1" | bc -q`
    else
        echo $branch | grep -q '_v'
        if [ $? -eq 0 ]; then
            new_branch=$branch".1"
        else
            new_branch=$branch"_v1.1"
        fi
    fi

    git checkout -b $new_branch
}

# Test until Fail.
function tuf()
{
    sh -c `$@`
    time sh -c 'while [ $? -eq 0 ]; do sleep 0.5; `$@`; done'
}
