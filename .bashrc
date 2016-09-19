# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

if ip --help 2>&1 | grep -q netns \
   && [ "x$(ip netns identify $$)" != "x" ]; then
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
alias wn="watch -n 0.5"

# Disable terminal flow control
stty -ixon

# Tmux Attach
function ta() {
    if [ $# -eq 0 ]; then
        session=0;
    else
        session=$1
    fi

    # Prevent nesting
    if [ -n "$TMUX" ]; then
        echo "Thwarted an attempt to nest tmux sessions."
        return 1
    fi

    if ! tmux has-session -t ${session}; then
        tmux new-session -d -s ${session};
    fi

    # Clear unattached sessions
    idle=$(tmux ls 2>/dev/null \
           | egrep "^.*\.[0-9]{14}.*[0-9]+\)$" \
           | cut -f 1 -d:)
    for old_session_id in ${idle}; do
        tmux kill-session -t ${old_session_id}
    done

    clientid=$session+$(date +%Y%m%d%H%M%S)
    tmux new-session -d -t ${session} -s ${clientid}
    tmux attach-session -t ${clientid}
    tmux kill-session -t ${clientid}
}

# Keep trying.
function kt()
{
    while true; do
        $@;
        sleep 1;
    done
}

# Watch a file for changes and trigger builds when changes are detected.
#
# $1 = File to watch
function watchmake() {
    while true; do
        inotifywait -q -e move $1;
        make;
        sleep 1;
    done
}

# Grep recursive.
function gr()
{
    if [ "$#" == "1" ]; then
        grep -r $@ . \
        | grep -vE "(cscope|tags|.git|testsuite|_build*)" \
        | grep $@
    elif [ "$#" -ge "2" ]; then
        grep -r $@
    else
        echo $(grep)
    fi
}

# Git send email with prompt.
function gse()
{
    if [ $(git diff | wc -l) -ne 0 ] \
       || [ $(git diff --cached | wc -l) -ne 0 ]; then
        echo "There are uncommitted changes in the tree."
        return
    fi
    echo "Have you run 'make check' yet?"
    echo "What's the shape of the patch?"
    echo "Which branch is this for?"
    echo
    read -r -p "Continue? [y/N] " response
    case ${response} in
        [yY])
            git send-email $@
            ;;
        *)
            ;;
    esac
}

# Git push upstream with prompts.
function gpu()
{
    local_branch=$(git rev-parse --abbrev-ref HEAD)
    base_branch=$(echo ${local_branch} | sed 's/^core\///')

    if ! echo ${local_branch} | grep "^core" 2>&1>/dev/null; then
        echo "Branch \"${local_branch}\" is not core; stopping"
        return
    fi

    echo "Patches between upstream and local branch:"
    git log --oneline --reverse upstream/${base_branch}..core/${base_branch}
    echo
    echo "Have you run 'make check'?"
    echo "Do the patches have their Acks?"
    echo
    read -r -p "exec 'git push upstream core/${base_branch}:${base_branch}'? [y/N] " response
    case ${response} in
        [yY])
            git push upstream core/${base_branch}:${base_branch}
            ;;
        *)
            ;;
    esac
}

# Given current git branch foo.X, create and switch to branch foo.X+1.
function gcn()
{
    branch=$(git status | head -n 1 | sed 's/^# *//' | cut -s -d' ' -f 3-)

    if echo ${branch} | grep -q '\.'; then
        base=$(echo ${branch} | cut -s -d'.' -f -1)
        version=$(echo ${branch} | cut -s -d'.' -f 2-)
        new_branch=${base}.$(echo "${version} + 1" | bc -q)
    else
        if echo ${branch} | grep -q '_v'; then
            new_branch=${branch}".1"
        else
            new_branch=${branch}"_v1.1"
        fi
    fi

    git checkout -b ${new_branch}
}

#Given current git branch X, create and switch to branch 'X+$1'
function gcb()
{
    branch=$(git status | head -n 1 | sed 's/^# *//' | cut -s -d' ' -f 3-)
    suffix=$1

    if [ $# -ge 1 ]; then
        git checkout -b "${branch}+${suffix}"
    fi
}

# Test until Fail.
function tuf()
{
    time while $@; do sleep 0.5; done
}

# Make with sparse and endianness checks.
function kmake()
{
    make C=1 CF="-Wsparse-all -D__CHECKER__ -D__CHECK_ENDIAN__ -Wbitwise" $@
}

# Git log one-liner
#
# $1 = Git commit ID
function glo()
{
    git log -1 --pretty=linux-fmt $1
}

# Print the log for a commit, with a 'Fixes: xxx ("yyy")' tag added inside.
#
# $1 = Git commit ID that introduced the bug
# $2 = Git commit ID to take the log from (default: HEAD -1)
function git-fixes()
{
    log_commit=-1
    if [ $# -lt 1 ]; then
        echo "Specify the git commit ID with the original bug." && return
    fi
    if [ $# -ge 2 ]; then
        log_commit=$2
    fi

    # Place the tag immediately before the Signed-off-by lines.
    git log --format=%B -n 1 ${log_commit} | sed '/^[^ ]*-by/Q'; \
    git log -1 --pretty=fixes $1; \
    git log --format=%B -n 1 ${log_commit} | sed -n '/^[^ ]*-by/,/$a/p'
}

# Amend the latest commit with a 'Fixes: xxx ("yyy")' tag.
#
# $1 = Git commit ID that introduced the bug
function git-fixes-amend()
{
    if [ $# -lt 1 ]; then
        echo "Specify the git commit ID with the original bug." && return
    fi
    git-fixes $1 | git commit --amend -F -
}

function munge-ovs-git-commit-subject()
{
    if echo ${1} | grep -q openvswitch; then
        echo ${1} | sed -e 's/openvswitch/datapath/' -e 's/\.*$/./'
    else
        echo "compat: ${1}" | sed 's/\.*$/./'
    fi
}

# Print the log for a commit, indented to show it is a backport of an upstream
# commit. Prepend a subject derived from the original patch, and append an
# 'Upstream: xxx ("...")' tag.
#
# $1 = Git commit ID of original commit upstream
# $2 = Git commit ID to take the log from (default: HEAD -1)
function git-upstream()
{
    log_commit=-1
    if [ $# -lt 1 ]; then
        echo "Specify the git commit ID of the upstream patch." && return
    fi
    if [ $# -ge 2 ]; then
        log_commit=$2
    fi
    if [ ${#1} -lt 12 ]; then
        echo "Original commit \`$1' seems incorrect; specify 12-digit hash." \
            && return
    fi

    orig_commit=$(echo ${1} | cut -c1-12)
    title=$(git log --format=%s -n 1 ${log_commit})

    munge-ovs-git-commit-subject "${title}"
    echo
    echo "Upstream commit:"
    git log --format=%B -n 1 ${log_commit} | sed -e 's/^/    /g' -e 's/^\w$//g'
    echo "Upstream: ${orig_commit} (\"${title}\")"
}

# Amend the latest commit with "Upstream commit: ..." pretty-printing and tags.
#
# $1 = Git commit ID of original commit upstream
function git-upstream-amend()
{
    if [ $# -lt 1 ]; then
        echo "Specify the git commit ID of the upstream patch." && return
    fi
    git-upstream $1 | git commit --amend -s -F -
}

# Get the list of tags that contain the commit in a particular repository.
#
# $1 = Repository
# $2 = Git commit ID
function gtc()
{
    dir_prefix=~/git
    repo=$1
    commit=$2

    if [ $# -lt 2 ]; then
        echo "usage: gtc <repo> <commit>"
        return 1;
    fi

    git_path=${dir_prefix}/${repo}
    if [ ! -d ${git_path} ]; then
        echo "path ${git_path} does not exist."
        return 1;
    fi

    cd ${git_path}
    git tag --contains ${commit}
    cd -
}

# Specialized version of "gtc" that searches using the Linux net-next tree,
# listing the first 5 tags that contain the specific commit.
#
# $1 - Git commit ID
function gtl()
{
    gtc net-next $1 | grep -v next | head -n 5
}

# Fast forward changes to the given commit.
function gff()
{
    git merge --ff-only $1
}

# Fetch upstream changes from git.
function gfu()
{
    git fetch upstream
}

# Fetch changes from git origin.
function gfo()
{
    git fetch origin
}

# Wait for N seconds, displaying a countdown timer
#
# $1 - Time in seconds to wait
function countdown()
{
    if [ $# -lt 1 ]; then
        echo "usage: countdown <n_secs>"
        return 1;
    fi
    secs=$1
    while [ $secs -gt 0 ]; do
        echo -ne "$secs\033[0K\r"
        sleep 1
        : $((secs--))
    done
}
