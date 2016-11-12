#!/bin/bash

#----------------------------------
# Elevate Specific Bash
#----------------------------------

#TODO: install this https://github.com/sstephenson/bats and create tests.

# Colours
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

# Global variables
CURRENT_DIR="${BASH_SOURCE%/*}"
EXAMPLE_BRANCH="123456_branch_name_1"
MSG_FAIL="\a${RED}[FAIL]${NORMAL}"
MSG_USAGE="${YELLOW}Usage:${NORMAL}"

# Source private variables
if [ -f ~/think-finance/think-finance-private.sh ]; then
    source ~/think-finance/think-finance-private.sh
else
    printf '$MSG_FAIL Required Think Finance variables not found.'
    return 1
fi

#------------------------- Aliases -----------------------------#
# Directory changing
alias sites='cd /var/www/html/'
alias views='cd /var/www/html/application/views/scripts'
alias view_helpers='cd /var/www/html/application/views/helpers'
alias controllers='cd /var/www/html/application/controllers'
alias action_helpers='cd /var/www/html/application/controllers/helpers'
alias services='cd /var/www/html/application/services'
alias models='cd /var/www/html/application/models/DbTable'
alias css='cd /var/www/html/public/mobile/css'
alias static='cd /var/www/html/public/static'
alias scss='cd /var/www/html/public/static/src/sass'
alias js='cd /var/www/html/public/mobile/scripts'
alias images='cd /var/www/html/public/mobile/images'
alias comms='cd /var/www/html/public/common/lib/customer_comms'
alias tools='cd /var/www/html/public/tools'
alias layouts='cd /var/www/html/application/layouts/scripts'
alias tests='cd /var/www/html/tests'
alias sql='cd /var/www/html/sql'
alias cronjobs='cd /var/www/html/public/Cronjobs/'

# Utilities
alias lb='svn ls ${URL_BRANCH_ROOT} --verbose'
alias mb='lb | grep $USER'
alias restart_apache='sudo /etc/init.d/crond stop && sudo service httpd stop && sudo service httpd start && sudo /etc/init.d/crond start'
alias restart_mysql='sudo /sbin/service mysql restart'
alias ephpi='sudo $EDITOR /etc/php.ini'
alias eac='sudo $EDITOR /etc/httpd/conf/httpd.conf'
alias zend_log='sudo tail -F /var/log/messages |while read -r line;do printf "\e[38;5;%dm%s\e[0m\n" $(($RANDOM%255)) "$line";done'
alias clear_cache='sudo rm -rf /var/www/html/public/mobile/cache/*'
alias env_switch_dev='sudo cp /etc/httpd/conf/httpd-dev.conf /etc/httpd/conf/httpd.conf && restart_apache && echo Environment switched to ${CYAN}development${NORMAL}'
alias env_switch_prod='sudo cp /etc/httpd/conf/httpd-prod.conf /etc/httpd/conf/httpd.conf && clear_cache && restart_apache && echo Environment switched to ${RED}production${NORMAL}'
alias rm-kenshoo='sudo rm -rf ./public/Cronjobs/kenshoo/csv_reports/csv_*'
alias rm-uploaded-docs='sudo rm -rf ./public/members/uploadeddocs/*'

# SVN helpers
alias svn-add-unstaged="svn st | grep '^?' | awk '{print $2}' | xargs svn add"
alias svn-remove-unstaged="svn st | grep '^?' | awk '{print $2}' | xargs rm -rf"
alias svn-revert-all="svn st | grep -e '^M' | awk '{print $2}' | xargs svn revert"
alias svn-make-patch="svn diff > $1"
alias svn-apply-patch="patch -p0 -i $1"

# a better up/down arrow key behaviour - thanks Adam!
bind '"\e[A"':history-search-backward
bind '"\e[B"':history-search-forward

export LC_ALL=C

# Bash functions -- mostly SVN wrappers

# Get uncommitted files
#: @depencies: getRootFromDir
function hasUncommittedFiles()
{
    local DIR_ROOT=$(getRootFromDir)
    local UF=$(cd $DIR_ROOT && svn status | wc -l)
    if [ $UF -gt 0 ]
    then
        return 0
    else
        return 1
    fi
}
export -f hasUncommittedFiles

# Switch to trunk
#: @depencies: hasUncommittedFiles
function switchTrunk()
{
    # Check for uncommitted files
    if hasUncommittedFiles
    then
        printf "$MSG_FAIL You have uncommitted files. You must commit these files before switching:\n\n"
        svn status
        echo
        return 1
    fi

    svn switch ${URL_TRUNK_ROOT}
}
export -f switchTrunk
alias swt='sites && switchTrunk'

# Switch to develop
# @dependencies: hasUncommittedFiles
function switchDevelop()
{
    # Check for uncommitted files
    if hasUncommittedFiles
    then
        printf "$MSG_FAIL You have uncommitted files. You must commit these files before switching:\n\n"
        svn status
        echo
        return 1
    fi

    svn switch ${URL_DEVELOP_ROOT}
}
export -f switchDevelop
alias swd='sites && switchDevelop'

# Switch SVN branch
# @dependencies: doesSVNPathExist, hasUncommittedFiles
function switchBranch()
{
    # Branch name is required
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL Branch name required.\n$MSG_USAGE sb $EXAMPLE_BRANCH\n"
        return 1
    fi

    # Check branch exists
    if ! $(doesSVNPathExist $1)
    then
        printf "$MSG_FAIL branch '${URL_BRANCH_ROOT}$1' does not exist\n"
        return 1
    fi

    # Check for uncommitted files
    if hasUncommittedFiles
    then
        printf "$MSG_FAIL You have uncommitted files. You must commit these files before switching:\n\n"
        svn status
        echo
        return 1
    fi

    svn switch ${URL_BRANCH_ROOT}$1;
    printf "${GREEN}Successfully switched to branch:\n${NORMAL}${URL_BRANCH_ROOT}$1\n"
}
export -f switchBranch
alias sb='sites && switchBranch'

# Get the name of the current branch
# @dependencies: getRootFromDir
function getBranchName()
{
    local DIR_ROOT=$(getRootFromDir)
    echo $(
        cd $DIR_ROOT \
        && svn info \
        | grep 'URL:' \
        | grep -oEi '[^/]+$'
    )
}
export -f getBranchName
alias wb='getBranchName'

function getBranchNumberFromName()
{
    # Check for branch name
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL Branch name is required.\n$MSG_USAGE getBranchNumberFromName $EXAMPLE_BRANCH\n"
        return 1
    fi
    local BRANCH=$1
    local BRANCH_NO=$(echo $BRANCH | grep -oEi '^[^_]+')

    echo $BRANCH_NO
}
export -f getBranchNumberFromName

# Get Branch URL
# @dependencies: getRootFromDir
function getBranchURL()
{
    local DIR_ROOT=$(getRootFromDir)
    echo $(
        cd $DIR_ROOT \
        && svn info \
        | grep 'URL: ' \
        | awk '{print $2}'
    )
}
export -f getBranchURL
alias wbu=getBranchURL

# Get the Target Process URL associated with the current branch
# @dependencies: getBranchName, getBranchNumberFromName
function getTPURL
{
    local BRANCH=$(getBranchName)
    local BRANCH_NO=$(getBranchNumberFromName $BRANCH)

    echo ${URL_TP_TICKET_ROOT}${BRANCH_NO}
}
export -f getTPURL

# Removes periods from commit comments that get info added to them
function removePeriodFromEndOfString()
{
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL String required.\n$MSG_USAGE removePeriodFromEndOfString \"This is a comment.\"\n"
        return 1
    fi

    local CLEANED=${1/%./}

    echo $CLEANED
}
export -f removePeriodFromEndOfString


# Commit code
#
# @dependencies: getRootFromDir, getBranchName, getBranchNumberFromName,
#                removePeriodFromEndOfString, getTPURL, getBranchURL,
#                addCommentToTP
function commitCode()
{
    # Switch to branch root
    local DIR_ROOT=$(getRootFromDir)
    cd $DIR_ROOT

    local BRANCH=$(getBranchName)
    local STATUS=$(svn status | grep -Eo '[a-z].*')

    # If there are no files to commit, say so and exit
    if [[ -z  $STATUS ]]
    then
        printf "There's nothing to commit.\n"
        return 1
    fi

    local QUIET=0
    if [[ $2 && $2 = --quiet ]]
    then
        QUIET=1
    fi

    # Prompt about PHP Code Sniffing the committed PHP files, if that exists
    if [[ $QUIET -eq 0 ]] && type -p phpcs > /dev/null;
    then
        local PHP_FILES=$(echo $STATUS | tr ' ' '\n' | grep -E '*.php')
        local NO_FILES=$(echo $PHP_FILES | grep -v '^\s*$' | wc -l)
        if [[ $NO_FILES -gt 0 && $PHP_FILES ]]
        then
            printf "${CYAN}${PHP_FILES}${NORMAL}\n"
            read -p "Run PHP Code Sniffer on these PHP files? (y/n) "

            if [[ $REPLY =~ ^[Yy]$ ]]
            then
                # Convert newlines to spaces
                local SSV=$(echo $PHP_FILES | tr '\n' ' ')
                local FAILED=0
                for f in $SSV
                do
                    local OUTPUT=$(phpcs $f | tee /dev/tty)
                    local ERRORS=$(echo $OUTPUT | grep 'ERROR')
                    if [[ $ERRORS ]]
                    then
                        local FAILED=1
                    fi
                done

                # Success
                if [[ $FAILED -eq 1 ]]
                then
                    printf "$MSG_FAIL Code failed coding standards check. Fix, then recommit.\n"
                    return 1
                else
                    printf "${GREEN}Success! Code meets the coding standard.${NORMAL}\n\n"
                fi

            fi
        fi
    fi

    svn status

    echo
    read -p "Commit these changes to ${YELLOW}$BRANCH${NORMAL}? (y/n) "

    if [[ $REPLY =~ ^[Yy]$ ]]
    then

        local DEVELOPER_NAME=""
        local REVIEWBOARD_ID=""

        read -p "Has this commit been peer reviewed? (y/n) "
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            # Ask for reviewer name
            local NUM=1
            for dev in ${!TF_DEVS[@]}; do
                echo "($NUM) ${CYAN}${TF_DEVS[dev]}${NORMAL}"
                ((NUM++))
            done

            printf "\nChoose the developer who reviewed this commit, or (0) to quit: ";

            read chosen_dev
            if [ $chosen_dev -eq 0 ]
            then
                return 1
            else
                local DEVELOPER_NAME="${TF_DEVS[chosen_dev]}"
                printf "${YELLOW}${DEVELOPER_NAME}${NORMAL} chosen.\n"
            fi

            # Enter review board id
            read -p "Enter the Review Board ID: " RBID
            local REVIEWBOARD_ID=$RBID
        fi

        local BRANCH_NO=$(getBranchNumberFromName $BRANCH)
        echo
        if [ $# -eq 0 ]
        then
            read -p "Enter your commit comment (if defect: add ticket no.): " COMMENT

            local COMMIT_COMMENT="#$BRANCH_NO comment: $COMMENT"
            # If Developer name and reviewboard id is not blank add it to the commit message
            if [ ! -z "$DEVELOPER_NAME" ] && [ ! -z "$REVIEWBOARD_ID" ]
            then
                # Remove trailing period, if we're attaching info.
                local COMMIT_COMMENT=$(removePeriodFromEndOfString "$COMMIT_COMMENT")
                COMMIT_COMMENT+=". Reviewed by $DEVELOPER_NAME (RBID: $REVIEWBOARD_ID)."
            fi
        else
            local COMMIT_COMMENT=$1
            # TP ticket comment
            local COMMENT=$1
        fi

        printf "${CYAN}\n$COMMIT_COMMENT${NORMAL}\n\n"

        read -p "Commit with the following comment? (y/n) "
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo
            local OUTPUT=$(svn commit -m "$COMMIT_COMMENT" | tee /dev/tty)

            # Save svn commit output to a folder for analysing bugs
            # Make dir if it doesn't exist
            mkdir -p ~/think-finance/svn-commit-log
            LOGFILE_NAME=$(wb)-$(date +'%F_%H-%M-%p').log
            # Save log file
            echo -e $OUTPUT > ~/think-finance/svn-commit-log/$LOGFILE_NAME

            local TP_URL=$(getTPURL)
            # TODO detect success
            printf "\n${GREEN}Success!${NORMAL}\n"

            # Branch URL
            local BRANCH_URL=$(getBranchURL)
            # Revision Number
            local REV_NO=$(echo $OUTPUT | grep 'Committed revision' | grep -oEi '[0-9]{5,}' | sed -n '$p')

            local TP_COMMENT="$COMMENT<br><br>"
            TP_COMMENT+="<strong>Branch:</strong> $BRANCH_URL<br>"
            TP_COMMENT+="<strong>Revision:</strong> $REV_NO<br>"
            TP_COMMENT+="<strong>Changeset:</strong> ${URL_CHANGESET_ROOT}${REV_NO}<br>"
            # Add reviewboard info if not blank
            if [ ! -z "$REVIEWBOARD_ID" ]
            then
                TP_COMMENT+="<strong>Code review by:</strong> $DEVELOPER_NAME http://reviewboard.uk.paydayone.com/r/$REVIEWBOARD_ID/"
            fi

            # Append Apply/Revert comment if SQL changed
            # TODO - Omit deleted SQL files
            local SQL_FILES=$(echo $STATUS | tr ' ' '\n' | grep -E '*.sql' | grep -Ev 'Deleting|schemas')
            local NO_FILES=$(echo $SQL_FILES | grep -v '^\s*$' | wc -l)
            if [[ $NO_FILES -gt 0 && $SQL_FILES ]]
            then
                local SQL_APPLY=$(getSQLApplyURLs $SQL_FILES)
                local SQL_ROLLBACK=$(getSQLRollbackURLs $SQL_FILES)

                local SQL_APPLY_HTML=$(join "<br>" ${SQL_APPLY[@]})
                local SQL_ROLLBACK_HTML=$(join "<br>" ${SQL_ROLLBACK[@]})

                TP_COMMENT+="<br><br>Contains SQL changes:<br>"

                if [ ! -z "$SQL_ROLLBACK_HTML" ]
                then
                    TP_COMMENT+="<br>"
                    TP_COMMENT+="<strong>Rollback:</strong> $SQL_ROLLBACK_HTML"
                fi
                if [ ! -z "$SQL_APPLY_HTML" ]
                then
                    TP_COMMENT+="<br>"
                    TP_COMMENT+="<strong>Apply:</strong> $SQL_APPLY_HTML"
                fi

                # Blank line
                echo

                # Multiple SQL files are joined with ';'
                local SQL_APPLY_TP=$(join ";" ${SQL_APPLY[@]})

                # Update TP custom field: SQL Script
                local TP_SQL_SCRIPT_RESULT=$(updateCustomField $BRANCH_NO "SQL Script" "True")
                echo -e $TP_SQL_SCRIPT_RESULT

                # Update TP custom field: SQL Script Linke
                # Strip <br>
                local TP_SQL_SCRIPT_LINK_RESULT=$(updateCustomField $BRANCH_NO "SQL Script Link" "$SQL_APPLY_TP")
                echo -e $TP_SQL_SCRIPT_LINK_RESULT
            fi

            # Update TP custom field: SVN Branch Name
            local TP_SVN_BRANCH_NAME_RESULT=$(updateCustomField $BRANCH_NO "SVN Branch Name" "$BRANCH_URL")
            echo -e $TP_SVN_BRANCH_NAME_RESULT

            # Add comment to Target Process ticket
            local TP_COMMENT_RESULT=$(addCommentToTP $BRANCH_NO "$TP_COMMENT")

            echo -e $TP_COMMENT_RESULT

        else
            echo
            return 1
        fi
    else
        echo
        return 1
    fi
}
export -f commitCode
alias commit='commitCode'

function getSQLApplyURLs()
{
    # Check SQL files provided
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL SQL changes required.\n$MSG_USAGE getSQLApplyURLs sql/123456_test_update.sql\n"
        return 1
    fi

    # Get svn branch URL
    local SQL_ROOT=$(getBranchURL)
    local SQL_APPLY=()
    local SQL_FILES=$(echo $SQL_FILES | tr ' ' '\n')

    for sql in $SQL_FILES
    do
        # Skip item if this is a revert/rollback script
        local FOUND=$(echo $sql | grep -oEi *rollback\|revert*)
        if [ -n "$FOUND" ]
        then
            continue
        fi
        SQL_APPLY+=("${SQL_ROOT}/$sql")
    done

    echo ${SQL_APPLY[@]}
}
export -f getSQLApplyURLs

# @return array of rollback URLs
function getSQLRollbackURLs()
{
    # Check SQL files provided
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL SQL changes required.\n$MSG_USAGE getSQLRollbackURLs sql/123456_test_update.sql\n"
        return 1
    fi

    local SQL_ROLLBACK=()

    # Get branch root
    local BRANCH_ROOT=$(wbu)/
    local SQL_FILES=$(echo $1 | tr ' ' '\n')

    for sql in $SQL_FILES
    do
        # Skip item if this is a revert/rollback script
        local FOUND=$(echo $sql | grep -oEi *rollback\|revert*)
        if [ -n "$FOUND" ]
        then
            SQL_ROLLBACK+=("${BRANCH_ROOT}${sql}")
        fi
    done

    echo ${SQL_ROLLBACK[@]}
}
export -f getSQLRollbackURLs

function doesFileContainString()
{
    # Check file provided
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL File and string required.\n$MSG_USAGE fileContainsString 'sql/123456_test_update.sql' 'turtle'\n"
        return 1
    fi

    # Search not given
    if [[ -z "$2" ]]
    then
        printf "$MSG_FAIL Search string required.\n$MSG_USAGE fileContainsString 'sql/123456_test_update.sql' 'turtle'n"
        return 1
    fi

    local SEARCH_RESULT=$(grep $2 $1)
    if [[ -z "$SEARCH_RESULT" ]]
    then
        # Not found
        return 1
    else
        # Found
        return 0
    fi

}
export -f doesFileContainString
alias fileContainsString='doesFileContainString'

function doesFileContainRegexMatch()
{
    # Check file provided
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL File and string required.\n$MSG_USAGE fileContainsRegexMatch '123456_test_update.sql' 'USE .?Core_DB.?'\n"
        return 1
    fi

    # Search not given
    if [[ -z "$2" ]]
    then
        printf "$MSG_FAIL Search string required.\n$MSG_USAGE fileContainsRegexMatch '123456_test_update.sql' 'USE .?Core_DB.?'\n"
        return 1
    fi

    local SEARCH_RESULT=$(grep -Eo "$2" $1)
    if [[ -z "$SEARCH_RESULT" ]]
    then
        # Not found
        return 1
    else
        # Found
        return 0
    fi
}
export -f doesFileContainRegexMatch
alias fileContainsRegexMatch='doesFileContainRegexMatch'

function addCommentToTP()
{
    # Check branch number (TPID) and comment given
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL Branch number and TP comment required.\n$MSG_USAGE addCommentToTP 123456 \"TP comment\"\n"
        return 1
    fi

    if [[ -z "$1" ]]
    then
        printf "$MSG_FAIL Branch number is required.\n$MSG_USAGE addCommentToTP 123456 \"TP comment\"\n"
        return 1
    fi

    if [[ -z "$2" ]]
    then
        printf "$MSG_FAIL Target Process comment (quoted) is required. HTML allowed.\n$MSG_USAGE addCommentToTP 123456 \"TP comment\"\n"
        return 1
    fi

    # TP_AUTH_TOKEN stored in ~/think-finance/think-finance-private.sh
    local TP_COMMENT_RESULT=$(php $HOME/think-finance/tools/helpers/tp-add-comment.php $TP_AUTH_TOKEN $1 "$2")

    echo -e $TP_COMMENT_RESULT
}
export -f addCommentToTP
alias addTpComment='addCommentToTP'

function updateTPCustomField()
{
    local USAGE="updateTPCustomField 123456 \"SQL Script Link\" \"https://123456-aztec-translations.sql\"\n"

    # Check branch number (TPID) and comment given
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL Branch number, TP custom field and TP custom field value are required.\n$MSG_USAGE $USAGE"
        return 1
    fi

    if [[ -z "$1" ]]
    then
        printf "$MSG_FAIL Branch number is required.\n$MSG_USAGE $USAGE"
        return 1
    fi

    if [[ -z "$2" ]]
    then
        printf "$MSG_FAIL Target Process custom field name (quoted) is required. \n$MSG_USAGE $USAGE"
        return 1
    fi

    if [[ -z "$3" ]]
    then
        printf "$MSG_FAIL Target Process custom field name value (quoted) is required. \n$MSG_USAGE $USAGE"
        return 1
    fi

    local TP_CUSTOM_FIELD_UPDATE_RESULT=$(php $HOME/think-finance/tools/helpers/tp-update-custom-field.php $TP_AUTH_TOKEN $1 "$2" "$3")

    echo -e $TP_CUSTOM_FIELD_UPDATE_RESULT
}
export -f updateTPCustomField
alias updateCustomField='updateTPCustomField'

function doesRevisionExist()
{
    # Check for revision URL
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL Revision URL is required.\n$MSG_USAGE dre $URL_BRANCH_ROOT@12345\n"
        return 1
    fi

    # Send stdout and stderr to /dev/null
    if svn info $1 &> /dev/null
    then
        return 0
    else
        return 1
    fi
}
export -f doesRevisionExist
alias dre='doesRevisionExist'

function getHeadRevisionFromBranch()
{
    # Check for revision URL
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL Branch URL is required.\n$MSG_USAGE ghr $URL_BRANCH_ROOT\n"
        return 1
    fi

    local HEAD_REVISION="$(svn info $1 | grep 'Revision' | awk '{print $2}')"

    echo $HEAD_REVISION
}
export -f getHeadRevisionFromBranch
alias ghr='getHeadRevisionFromBranch'

# Create new SVN branch based on Trunk
function newBranch()
{
    # Check for branch name
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL New branch name is required.\n"
        printf "$MSG_USAGE nb $EXAMPLE_BRANCH\n";
        return 1
    fi

    # Check branch name starts with [0-9]_
    if ! [[ $1 =~ [0-9]_.+ ]]
    then
        printf "$MSG_FAIL Branch names need to start with their Target Process number.\n"
        printf "$MSG_USAGE nb $EXAMPLE_BRANCH\n";
        return 1
    fi

    # Check branch name ends in _[1-9]
    if ! [[ $1 =~ .+_[0-9]{1,2}$ ]]
    then
        printf "$MSG_FAIL Branch names need to end in a version number _1.\n"
        printf "$MSG_USAGE nb $EXAMPLE_BRANCH\n";
        return 1
    fi

    # Check branch exists
    if $(doesSVNPathExist $1)
    then
        printf "$MSG_FAIL Branch ${YELLOW}$1${NORMAL} already exists!\n"
        return 1
    fi

    # Develop is most common
    local COPY_ROOT=${URL_DEVELOP_ROOT}
    local COPY_ROOT_NAME="DEVELOP (HEAD)"

    read -p "Choose branch base: (1) Develop, (2) Trunk, (3) Branch: "
    if [[ $REPLY =~ ^[1]$ ]]
    then
        read -p "Enter revision number of Develop to branch from, OR (0) for HEAD: " REVISION
        if [[ $REVISION -eq 0 ]]
        then
            local COPY_ROOT=${URL_DEVELOP_ROOT}
            local COPY_ROOT_NAME="DEVELOP (HEAD)"
            printf "${GREEN}${COPY_ROOT_NAME}${NORMAL} chosen (${YELLOW}${URL_DEVELOP_ROOT}${NORMAL})\n"
        else
            # Validate revision number
            local COPY_ROOT=${URL_DEVELOP_ROOT}@${REVISION}
            if ! $(doesRevisionExist ${COPY_ROOT})
            then
                printf "$MSG_FAIL Revision '${YELLOW}${COPY_ROOT}${NORMAL}' does not exist\n"
                return 0
            fi
            local COPY_ROOT_NAME="DEVELOP @ r${REVISION}"
            printf "${GREEN}${COPY_ROOT_NAME}${NORMAL} chosen (${YELLOW}${COPY_ROOT}${NORMAL})\n"
        fi

    elif [[ $REPLY =~ ^[2]$ ]]
    then
        local COPY_ROOT=${URL_TRUNK_ROOT}
        local COPY_ROOT_NAME="TRUNK"
        printf "${GREEN}${COPY_ROOT_NAME}${NORMAL} chosen (${YELLOW}${COPY_ROOT}${NORMAL})\n"

    elif [[ $REPLY =~ ^[3]$ ]]
    then
        read -p "Enter branch name to copy from: " BRANCH_NAME
        # Check branch exists
        if ! $(doesSVNPathExist $BRANCH_NAME)
        then
            printf "$MSG_FAIL branch '${URL_BRANCH_ROOT}$BRANCH_NAME' does not exist\n"
            return 1
        fi

        local COPY_ROOT=${URL_BRANCH_ROOT}$BRANCH_NAME
        local COPY_ROOT_NAME=$BRANCH_NAME
        printf "${GREEN}${COPY_ROOT_NAME}${NORMAL} chosen (${YELLOW}${COPY_ROOT}${NORMAL})\n"

    fi

    # Get the latest revision of the branch we're copying from
    local REVISION=$(getHeadRevisionFromBranch $COPY_ROOT)
    local CREATED_FROM="Branch copied from $COPY_ROOT_NAME [r$REVISION]"

    # Check comment is passed in the second parameter
    if [[ -z "$2" ]]
    then
        local BRANCH_NO=$(echo $1 | grep -oEi ^[0-9]+)
        read -p "Enter a description of this branch: " DESCRIPTION

        # Remove trailing period, if that exists
        local DESCRIPTION=$(removePeriodFromEndOfString "$DESCRIPTION")
        local BRANCH_COMMENT="#$BRANCH_NO comment: $DESCRIPTION. $CREATED_FROM"
    else
        local BRANCH_COMMENT="${2/ROOT_BRANCH/$COPY_ROOT_NAME} [r$REVISION]"
    fi

    printf "${CYAN}$BRANCH_COMMENT${NORMAL}\n"

    read -p "Create a new branch from ${GREEN}${COPY_ROOT_NAME}${NORMAL} with this commit comment? (y/n) "
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # Create the branch
        svn copy ${COPY_ROOT} ${URL_BRANCH_ROOT}$1 -m "$BRANCH_COMMENT"
        printf "${GREEN}Branch ${CYAN}$1${NORMAL} ${GREEN}created successfully.${NORMAL}\n";
        printf "${URL_BRANCH_ROOT}$1\n\n"

        local NEW_BRANCH_REV=$(getHeadRevisionFromBranch ${URL_BRANCH_ROOT}$1)

        local TP_COMMENT="$BRANCH_COMMENT<br><br>"
        TP_COMMENT+="<strong>Branch created:</strong> ${URL_BRANCH_ROOT}$1<br>"
        TP_COMMENT+="<strong>Origin:</strong> $CREATED_FROM<br>"
        TP_COMMENT+="<strong>Revision:</strong> $NEW_BRANCH_REV"

        # Add branch created to Target Process ticket
        local TP_COMMENT_RESULT=$(addCommentToTP $BRANCH_NO "$TP_COMMENT")

        echo $TP_COMMENT_RESULT
        echo

        # Change - if comment is passed, it's probably a 'rebaseline': skip the switch ask
        if [[ -z "$2" ]]
        then
            read -p "Switch to ${YELLOW}$1${NORMAL} now? (y/n) "
            if [[ $REPLY =~ ^[Yy]$ ]]
            then
                echo
                switchBranch $1
                return 0
            else
                echo
                return 1
            fi
        else
            echo
            return 1
        fi
    else
        echo
        return 1
    fi
}
export -f newBranch
alias nb='sites && newBranch'

# Gets the dir root for the given branch (e.g. /var/www/html)
function getRootFromDir()
{
    # Default
    local ROOT='/var/www/html'

    # If we're inside /tools
    if [[ $(pwd | grep '/tools') ]]
    then
        local ROOT='/var/www/html/public/tools'
    fi

    # If we're in /var/www/loans
    if [[ $(pwd | grep '/www/loans') ]]
    then
        local ROOT='/var/www/loans/public'
    fi

    # If we're in /var/www/loans
    if [[ $(pwd | grep '/www/compare') ]]
    then
        local ROOT='/var/www/compare/public'
    fi

    echo $ROOT
}
export -f getRootFromDir

function doesSVNPathExist()
{
    # Check for branch name given
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL Branch name is required.\n$MSG_USAGE be $EXAMPLE_BRANCH\n"
        return 1
    fi

    # Send stdout and stderr to /dev/null
    if svn ls ${URL_BRANCH_ROOT}$1 &> /dev/null
    then
        # Exists!
        return 0
    else
        # Does not exist
        return 1
    fi
}
export -f doesSVNPathExist
alias be='sites && doesSVNPathExist'

function getVersionNumber()
{
    local VERSION_NUM=$(getBranchName | grep -o '[0-9]*$')
    if [[ -z $VERSION_NUM ]]
    then
        echo 1
    else
        echo $VERSION_NUM
    fi
}
export -f getVersionNumber

function getNextVersionNumber()
{
    local NEXT_VERSION_NUM=$(getVersionNumber)
    ((NEXT_VERSION_NUM++))
    echo $NEXT_VERSION_NUM
}
export -f getNextVersionNumber

function getAllRevisionsFromBranch()
{
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL Branch name is required.\n$MSG_USAGE getAllRevisionsFromBranch $EXAMPLE_BRANCH\n"
        return 1
    fi
    local BRANCH=$1
    echo $(svn log --stop-on-copy "${URL_BRANCH_ROOT}${BRANCH}" | grep -Po '^r[^ ]+')
}

function getRevisionRange()
{
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL Branch name is required.\n$MSG_USAGE getFirstLastRevision $EXAMPLE_BRANCH\n"
        return 1
    fi
    local BRANCH=$1
    local ALL_REVS=$(getAllRevisionsFromBranch $1)
    # Replace spaces with newlines
    local REV_LINES=$(echo $ALL_REVS | tr ' ' '\n' | sed -n '1p;$p' | sort | uniq | tr -d 'r')
    echo $REV_LINES
}
export -f getRevisionRange

function getRevisionCMD()
{
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL Branch name is required.\n$MSG_USAGE getRevisionCMD $EXAMPLE_BRANCH\n"
        return 1
    fi
    local BRANCH=$1

    local REV_RANGE=$(getRevisionRange $BRANCH)
    local REV_ARRAY=($REV_RANGE)
    if [[ ${#REV_ARRAY[@]} -eq 2 ]]
    then
        # You have to specify REV-1 if you want that REV to be merged.
        local FIRST_REV=${REV_ARRAY[0]}
        ((FIRST_REV--))
        local REV_RANGE=$FIRST_REV:${REV_ARRAY[1]}
    else
        local REV_RANGE="-c ${REV_ARRAY[0]}"
    fi

    echo $REV_RANGE
}
export -f getRevisionCMD

function getRevisionRangeForComment()
{
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL Branch name is required.\n$MSG_USAGE getRevisionCMD $EXAMPLE_BRANCH\n"
        return 1
    fi
    local BRANCH=$1

    local REV_RANGE=$(getRevisionRange $BRANCH)
    local REV_ARRAY=($REV_RANGE)
    if [[ ${#REV_ARRAY[@]} -eq 2 ]]
    then
        local FIRST_REV=${REV_ARRAY[0]}
        ((FIRST_REV--))
        local REV_RANGE=${REV_ARRAY[0]}-${REV_ARRAY[1]}
    else
        local REV_RANGE="${REV_ARRAY[0]}"
    fi

    echo $REV_RANGE
}
export -f getRevisionRangeForComment

function getCommitInfoFromBranch()
{
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL Branch name is required.\n$MSG_USAGE getFirstLastRevision $EXAMPLE_BRANCH\n"
        return 1
    fi
    local BRANCH=$1
    echo $(svn log --stop-on-copy "${URL_BRANCH_ROOT}${BRANCH}" | grep -Po '^r[^ ]+')
}
export -f getCommitInfoFromBranch

function viewHistory()
{
    local BRANCH_NAME=$(getBranchName)
    svn log -v --stop-on-copy ${URL_BRANCH_ROOT}${BRANCH_NAME}
}
export -f viewHistory
alias vh='viewHistory'

function getNextBranchName()
{
    local NEXT_VERSION_NUM=$(getNextVersionNumber)
    local BRANCH_NAME=$(getBranchName)
    local BRANCH_WITH_VERSION_NUM=$(echo $BRANCH_NAME | grep -o '.*_[0-9]$')
    if [[ -z $BRANCH_WITH_VERSION_NUM ]]
    then
        local NEXT_BRANCH_NAME=$(getBranchName)_${NEXT_VERSION_NUM}
    else
        local NEXT_BRANCH_NAME=$(getBranchName | grep -o '.*_')${NEXT_VERSION_NUM}
    fi
    echo $NEXT_BRANCH_NAME
}
export -f getNextBranchName

function rebaseline()
{
    local THIS_BRANCH=$(getBranchName)
    local BRANCH_NO=$(getBranchNumberFromName ${THIS_BRANCH})
    local NEXT_BRANCH_NAME=$(getNextBranchName)

    # Show nice summary of changes
    printf "${GREEN}Commit log:${NORMAL} ${THIS_BRANCH}\n"
    echo ${URL_BRANCH_ROOT}${THIS_BRANCH}
    svn log -v --stop-on-copy ${URL_BRANCH_ROOT}${THIS_BRANCH}
    echo
    read -p "Create ${YELLOW}${NEXT_BRANCH_NAME}${NORMAL} and merge ${GREEN}all commits${NORMAL} from '${CYAN}${THIS_BRANCH}${NORMAL}'? (y/n) "
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # Create new branch
        local BRANCH_COMMENT="#${BRANCH_NO} comment: Rebaseline ${THIS_BRANCH} with ROOT_BRANCH."
        nb ${NEXT_BRANCH_NAME} "$BRANCH_COMMENT"

        # Switch to new branch
        printf "Switching to ${YELLOW}${NEXT_BRANCH_NAME}${NORMAL}...\n"
        sb $NEXT_BRANCH_NAME

        # Test merge with previous version
        local REVISIONS_TO_MERGE=$(getRevisionCMD $THIS_BRANCH)

        printf "\n${GREEN}Test merge:${NORMAL}\n"
        printf "${BOLD}U${NORMAL}:Updated, ${BOLD}G${NORMAL}:Changes merged, ${BOLD}M${NORMAL}:Modified, ${BOLD}I${NORMAL}:Ignored, ${BOLD}A${NORMAL}:Added, ${BOLD}D${NORMAL}:Deleted\n\n"
        printf "${MAGENTA}Running:${NORMAL} svn merge --dry-run -r $REVISIONS_TO_MERGE ${URL_BRANCH_ROOT}${THIS_BRANCH}\n"

        svn merge --dry-run -r $REVISIONS_TO_MERGE ${URL_BRANCH_ROOT}${THIS_BRANCH}

        # Merge for good
        echo
        read -p "Merge and commit? (y/n) "
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            printf "\n${GREEN}Merging:${NORMAL}\n"
            # Merge it so!
            svn merge -r $REVISIONS_TO_MERGE ${URL_BRANCH_ROOT}${THIS_BRANCH}

            echo
            # Commit!
            local BRANCH_NUM=$(getBranchNumberFromName ${THIS_BRANCH})
            local REVISIONS_FOR_COMMENT=$(getRevisionRangeForComment $THIS_BRANCH)
            local COMMIT_MSG="#${BRANCH_NUM} comment: Merged revisions [${REVISIONS_FOR_COMMENT}] from ${THIS_BRANCH}"
            echo
            commit "$COMMIT_MSG" --quiet
        else
            return 1
        fi
    else
        return 1
    fi
}
export -f rebaseline
alias rb='rebaseline'

# Thanks to Adam Atkins for this sexy function
function findBranch()
{
    if [ $# -ge 1 ]
    then
        sites
        local BRANCH_ARR=($(svn ls ${URL_BRANCH_ROOT} | grep "$1"))
        NUM=0
        for branch in ${!BRANCH_ARR[@]}; do
            ((NUM++))
            echo "($NUM) ${CYAN}${BRANCH_ARR[branch]}${NORMAL}"
        done
        printf "\nChoose a branch to switch to, or (0) to quit: ";
        read BRANCH_NUM
        if [ $BRANCH_NUM -eq 0 ]
        then
            return 1
        else
            ((BRANCH_NUM--))
            printf "Switching to: ${CYAN}${BRANCH_ARR[BRANCH_NUM]}${NORMAL}\n"
            sb ${BRANCH_ARR[BRANCH_NUM]}
            return 0
        fi
    else
        printf "$MSG_FAIL Search pattern required.\n$MSG_USAGE fb hotfix.\n"
    fi
}
export -f findBranch
alias fb='findBranch'

# Check if string is a palindrome (for Fish trophy message)
function isPalindrome()
{
    if [ $# -ge 1 ]
    then
        if [ "$(echo $1 | rev)" = "$1" ]
        then
            return 0
        else
            return 1
        fi
    fi
}

function getPalindromeMessage()
{
    if [ $# -ge 1 ]
    then
        if $(isPalindrome $1)
        then
            printf "${GREEN}Congratulations!${NORMAL} You won a Fish trophy for your palindromic ReviewBoard ID: ${YELLOW}$1${NORMAL}\n"
        else
            # Look at the 10 next RBIDs to see if these will be fish trophies
            local RBID=$(( $1 + 1 ))
            local END_RBID=$(( $1 + 10 ))
            while [  $RBID -lt $END_RBID ]; do
                if $(isPalindrome $RBID)
                then
                    # How many reviews until a fish?
                    local UNTIL=$(( $RBID - $1 ))
                    printf "${YELLOW}$UNTIL more review(s) until a fish trophy (for ${RBID})!${NORMAL}\n"
                    return 0
                fi
                let RBID=RBID+1 
            done
            
            return 0
        fi
    fi
}

function getBranchHistory()
{
    echo $(
        grep 'nb\|sb' ~/.bash_history \
            | awk '{print $2}' \
            | grep -v 'grep\|nb\|sb' \
            | grep -oE '^[0-9]{6,}_.*_[0-9]{1,2}$' \
            | uniq \
            | sort
    )
}
export -f getBranchHistory
alias bh='getBranchHistory | tr " " "\n"'

function createPostReviewWithInfo()
{
    # Switch to branch root
    local DIR_ROOT=$(getRootFromDir)
    cd $DIR_ROOT

    local BRANCH_URL=$(getBranchURL)
    local BRANCH=$(getBranchName)
    local BRANCH_NO=$(getBranchNumberFromName $BRANCH)

    read -p "Enter a Review Board summary: " SUMMARY
    local RB_SUMMARY="#${BRANCH_NO} - $SUMMARY"
    printf "Summary: ${CYAN}${RB_SUMMARY}${NORMAL}\n\n"

    read -p "Enter a Review Board description: " DESCRIPTION
    printf "Description: ${CYAN}${DESCRIPTION}${NORMAL}\n\n"

    read -p "Create code review with the following comment? (y/n) "
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # Capture ouput while displaying it 
        local OUTPUT=$(rbt post --branch=$BRANCH_URL --bugs-closed="$BRANCH_NO" --summary="$RB_SUMMARY" --description="$DESCRIPTION" | tee /dev/tty)
        local REVIEWBOARD_ID=$(echo $OUTPUT | grep 'paydayone' | grep -Eo '[0-9]{4,}')

        # Check for a fish trophy or an upcoming one
        getPalindromeMessage $REVIEWBOARD_ID
    else
        echo
        return 1
    fi

}
export -f createPostReviewWithInfo
alias ccr='createPostReviewWithInfo'

# Convert arrays to a string separated by the separator provided in the first argument
function join { 
    ARR=($@)
    echo ${ARR[@]:1} | sed "s/ /$1/g"
}
export -f join

# For the lulz
function seizure
{
    yes "$(seq 231 -1 16)" | while read i; do printf "\x1b[48;5;${i}m\n"; sleep .02; done
}

# Make a beep sound
function beep
{
    echo -e "\a"
}
export -f beep

# source custom bash autocompletions
if [ -f /etc/bash_completion.d/sb ]; then
    . /etc/bash_completion.d/sb
fi
if [ -f /etc/bash_completion.d/nb ]; then
    . /etc/bash_completion.d/nb
fi
