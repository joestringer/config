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
PROMPT_COMMAND=__prompt_command
__prompt_command() {
    time=$(date +'%b %e %R:%S %Z')
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

            PS1='${debian_chroot:+($debian_chroot)}'
            if [[ ${EUID} == 0 ]] ; then
                    PS1+='\[\033[01;31m\]'
            else
                    PS1+='\[\033[01;32m\]\u@'
            fi
            PS1+='\h\[\033[01;33m\]${namespace} '
            PS1+='\[\033[01;90m\][${time}] '
            PS1+='\[\033[01;34m\]\W '
            # Colorize based on success/failure of previous execution
            PS1+="\$([ \$? == 0 ] && echo '\[\e[01;32m\]' || echo '\[\e[01;31m\]')"
            PS1+='\$\[\033[00m\] '

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
}

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
alias journalctl='journalctl --no-pager'
alias make='make --quiet -j $(getconf _NPROCESSORS_ONLN)'
alias ll="ls -lh"
alias ll="ls -lha"
alias nv="nano -v"
alias nt="nano -E"
alias gi="git"
alias show="git show"
alias lr="less -r"
alias :e="vim"
alias wn="watch -n 0.5"
alias tmux="tmux -2"
alias gti="git"

# Disable terminal flow control
stty -ixon

# Tmux Attach
ta() {
    if [ $# -eq 0 ]; then
        session=0;
    else
        session=$1
        shift 1
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
    tmux attach-session -t ${clientid} $@
    tmux kill-session -t ${clientid}
}

# Keep trying.
kt()
{
    while true; do
        $@;
        sleep 1;
    done
}

# Watch a file or directory for changes and trigger some action at that time.
#
# $1 = File to watch
# $2+ = Command and arguments
watchdo() {
    local FILE=$1
    shift

    local reset='\e[00m'
    local red='\e[01;31m'
    local green='\e[01;32m'
    local yellow='\e[01;33m'
    echo -e "${yellow}Running '$@' on changes to $FILE ...${reset}"
    while inotifywait -q -r -e move -e move_self $FILE; do
        eval "$@";
        if [ $? == 0 ] ; then
            echo -e "${yellow}$@${reset}: ${green}✔${reset}"
        else
            echo -e "${yellow}$@${reset}: ${red}✘${reset}"
        fi
    done
}

# Watch a file or directory for changes and trigger builds when it is modified.
#
# $1 = File to watch
watchmake() {
    watchdo $1 make
}

# Grep recursive.
gr()
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
gse()
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

# Get the current git branch, or fail out.
git-get-branch()
{
    (
        set -e
        git rev-parse --symbolic-full-name --abbrev-ref HEAD
    )
}

# Git push upstream with prompts.
gpu()
{
    local local_branch=$(git-get-branch)
    local base_branch=$(echo ${local_branch} | sed 's/^core\///')

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
gcn()
{
    local branch=$(git-get-branch)

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
gcb()
{
    local branch=$(git-get-branch)
    suffix=$1

    if [ $# -ge 1 ]; then
        git checkout -b "${branch}+${suffix}"
    fi
}

git-bd()
{
    (
        set -e

        local branch=$(git-get-branch)
        git checkout master
        git branch -D $branch
    )
}

# Test until Fail.
tuf()
{
    local iter=1

    time while $@; do sleep 0.5 $((iter++)); done
    echo "Iterated $iter times"
}

# Make with sparse and endianness checks.
kmake()
{
    make C=1 CF="-Wsparse-all -D__CHECKER__ -D__CHECK_ENDIAN__ -Wbitwise" $@
}

# Git log one-liner
#
# $1 = Git commit ID
glo()
{
    git log -1 --pretty=linux-fmt $1
}

# Print the log for a commit, with a 'Fixes: xxx ("yyy")' tag added inside.
#
# $1 = Git commit ID that introduced the bug
# $2 = Git commit ID to take the log from (default: HEAD -1)
git-fixes()
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
git-fixes-amend()
{
    if [ $# -lt 1 ]; then
        echo "Specify the git commit ID with the original bug." && return
    fi
    git-fixes $1 | git commit --amend -F -
}

munge-ovs-git-commit-subject()
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
git-upstream()
{
    log_commit=-1
    if [ $# -lt 1 ]; then
        echo "Specify the git commit ID of the upstream patch." && return
    fi
    if [ $# -ge 2 ]; then
        log_commit=$2
    fi
    if [ ${#1} -lt 20 ]; then
        echo "Original commit \`$1' seems incorrect; specify full hash." \
            && return
    fi

    orig_commit=$(echo ${1} | cut -c1-12)
    title=$(git log --format=%s -n 1 ${log_commit})

    munge-ovs-git-commit-subject "${title}"
    echo
    echo "Upstream commit:"
    echo "    commit ${1}"
    git log --format='Author: %aN <%aE>' -n 1 ${log_commit} | sed -e 's/^/    /g' -e 's/^\w$//g'
    git log --format='Date: %ad' -n 1 ${log_commit} | sed -e 's/^/    /g' -e 's/^\w$//g'
    echo ""
    git log --format=%B -n 1 ${log_commit} | sed -e 's/^/    /g' -e 's/^\w$//g'
    echo "Upstream: ${orig_commit} (\"${title}\")"
}

# Amend the latest commit with "Upstream commit: ..." pretty-printing and tags.
#
# $1 = Git commit ID of original commit upstream
git-upstream-amend()
{
    if [ $# -lt 1 ]; then
        echo "Specify the git commit ID of the upstream patch." && return
    fi
    git-upstream $1 | git commit --amend --reset-author -s -F -
}

# Print the log for a commit, with a 'Fixes: xxx ("yyy")' tag added inside.
#
# $1 = Git commit ID that introduced the bug
# $2 = Git commit ID to take the log from (default: HEAD -1)
git-backports()
{
    log_commit=-1
    if [ $# -lt 1 ]; then
        echo "Specify the git commit ID with the original bug." && return
    fi
    if [ $# -ge 2 ]; then
        log_commit=$2
    fi

    # Place the tag immediately before the Signed-off-by lines.
    git log --format=%B -n 1 ${log_commit} | sed '/^Fixes/Q'; \
    echo "From master commit $1."; echo; \
    git log --format=%B -n 1 ${log_commit} | sed -n '/^Fixes/,/$a/p'
}

# Amend the latest commit with a 'From master commit xxx.' tag.
#
# $1 = Git commit ID originally merged upstream.
git-backports-amend()
{
    if [ $# -lt 1 ]; then
        echo "Specify the git commit ID originally merged upstream." && return
    fi
    git-backports $1 | git commit --amend -F -
}

# Cherry pick the specified commit from the 'local' remote tree. Adds the line
# "From master commit xxx." into the message above the "Fixes" tag.
#
# $1 = Git commit ID originally merged upstream.
gcp()
{
    if [ $# -lt 1 ]; then
        echo "Specify the git commit ID originally merged upstream." && return
    fi

    git fetch local
    git cherry-pick $1
    git-backports-amend $1
}

# Get the list of tags that contain the commit in a particular repository.
#
# $1 = Repository
# $2 = Git commit ID
gtc()
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
    git tag --contains ${commit} | sort -V
    cd -
}

# Adds a specified string to all commits from the specified commit to HEAD.
#
# $1 - Git commit ID
# $2 - String to add as newline at end of commit message
git-amend-add()
{
    commit=$1
    string=$2

    if [ $# -lt 2 ]; then
        echo "usage: git-ack <commit> <string>"
        return 1;
    fi

    git filter-branch -f --msg-filter "sed '$ a\\$string'" $commit..HEAD
}

# Adds signoff tags to all commits from the specified commit to HEAD.
#
# $1 - Git commit ID
git-sign()
{
    commit=$1
    user="$(git config user.name) <$(git config user.email)>"

    if [ $# -lt 1 ]; then
        echo "usage: git-sign <commit>"
        return 1;
    fi

    git-amend-add $commit "Signed-off-by: $user"
}

# Adds "ack" tags to all commits from the specified commit to HEAD.
#
# $1 - Git commit ID
# $2 - Optional alternative ack string of the form "name <user@domain>"
git-ack()
{
    commit=$1
    user=${2:-"$(git config user.name) <$(git config user.email)>"}

    if [ $# -lt 1 ]; then
        echo "usage: git-ack <commit> [id]"
        return 1;
    fi

    ack="Acked-by: $user"
    if [ $# -gt 1 ]; then
        echo "Acking with \"$ack\" (CTRL+C to abort)"
        read -r -n 1
    fi

    git-amend-add $commit $ack
}

# Specialized version of "gtc" that searches using the Linux net-next tree,
# listing the first N version tags that contain the specific commit.
#
# $1 - Git commit ID
# $2 - Count of commits to check (default: 1)
gtl()
{
    count=1
    if [ $# -gt 1 ]; then
        count=$2
    fi

    gtc net-next $1 | grep -v next | grep "^v" | head -n $count
}

# Fast forward changes to the given commit.
gff()
{
    git merge --ff-only $1
}

# Fetch upstream changes from git.
gfu()
{
    git fetch upstream
}

# Fetch changes from git origin.
gfo()
{
    git fetch origin
}

# Wait for N seconds, displaying a countdown timer
#
# $1 - Time in seconds to wait
countdown()
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

# Find a kernel based on a string and load it using kexec
#
# $1 - Kernel localversion string to specify kernel
load_kernel()
{
    if [ $# -ne 1 ]; then
        echo "Usage: load_kernel <kernel>"
        echo;
        echo "Available kernels:"
        ls /boot/vmlinuz-* | cut -d'-' -f2- | sed 's/^/     /'
    else
        version=$1
        initfs=$(ls /boot/init*${version}*)

        if kexec -l /boot/vmlinuz-${version} --ramdisk=${initfs} \
           --reuse-cmdline; then
            echo "Loaded Linux-${version} Run 'kexec -e' to execute it."
        fi
    fi
}

# Shortcut for kubectl
k()
{
    kubectl "$@"
}

# Shortcut for kubectl that executes the command in kube-system namespace
ks()
{
    kubectl "$@" -n kube-system
}

# Shortcut for kubectl that executes the command in all namespaces
kan()
{
    kubectl "$@" --all-namespaces
}

# Shortcut for "git rc" alias (git rebase --continue ...)
gitrc()
{
    git rc
}

# Drop the PS1 to a basic "$" to simplify shell output for copy/paste somewhere
demo()
{
    export PROMPT_COMMAND="PS1=\"$ \""
}

# undemo reverses 'demo'.
undemo()
{
    export PROMPT_COMMAND=__prompt_command
}

# count_failures_output looks for lines with the word "pass" in them in the
# file specified, and prints a count comparing this vs the total number of
# lines with a rate.
#
# $1 - file to use for counting the failures
count_failures_output()
{
    out=$1
    success=$(grep "pass" $out | wc -l)
    total=$(cat $out | wc -l)
    rate=$(awk "BEGIN { print int(${success} / ${total} * 100) }")

    echo
    echo "Successes: ${success}/${total}; rate: ${rate}%"
}

# count_failures repeatedly runs the command specified as arguments until the
# user interrupts the test. Upon interruption, it prints the number of times
# that the command succeeded/failed.
#
# $@ - command + args to run
count_failures()
{
    local out=$(mktemp)

    trap "rm $out"
    trap "count_failures_output $out" SIGINT
    while true; do
        if "$@"; then
            echo "pass" >> $out
        else
            echo "fail" >> $out
        fi
    done
}
