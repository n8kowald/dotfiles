#!/bin/bash

#----------------------------------
# Think Finance Specific Bash
#----------------------------------

#TODO: install this https://github.com/sstephenson/bats and create tests.

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

# Global variables
EXAMPLE_BRANCH="123456_branch_name_1"
MSG_USAGE="${YELLOW}Usage:${NORMAL}"
MSG_FAIL="\a${RED}[FAIL]${NORMAL}"
CURRENT_DIR="${BASH_SOURCE%/*}"

# Source private variables
if [ -f ${CURRENT_DIR}/think-finance-private.sh ]; then
	source ${CURRENT_DIR}/think-finance-private.sh
else
	printf '$MSG_FAIL Required Think Finance variables not found.'
	return 0
fi

#------------------------- Aliases -----------------------------#
# Directory changing
alias sites='cd /var/www/html/'
alias views='cd /var/www/html/application/views/scripts'
alias controllers='cd /var/www/html/application/controllers'
alias services='cd /var/www/html/application/services'
alias models='cd /var/www/html/application/models/DbTable'
alias styles='cd /var/www/html/public/mobile/css'
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
alias mb='lb | grep nkowald'
alias restart_apache='sudo /etc/init.d/crond stop && sudo service httpd stop && sudo service httpd start && sudo /etc/init.d/crond start'
alias restart_mysql='sudo /sbin/service mysql restart'
alias ephpi='sudo vim /etc/php.ini'
alias eac='sudo vim /etc/httpd/conf/httpd.conf'
alias zend_log='sudo tail -F /var/log/messages |while read -r line;do printf "\e[38;5;%dm%s\e[0m\n" $(($RANDOM%255)) "$line";done'
alias clear_cache='sudo rm -rf /var/www/html/public/mobile/cache/*'
alias env_switch_dev='sudo cp /etc/httpd/conf/httpd-dev.conf /etc/httpd/conf/httpd.conf && restart_apache && echo Environment switched to ${CYAN}development${NORMAL}'
alias env_switch_prod='sudo cp /etc/httpd/conf/httpd-prod.conf /etc/httpd/conf/httpd.conf && clear_cache && restart_apache && echo Environment switched to ${RED}production${NORMAL}'
alias rm-kenshoo='sudo rm -rf ./public/Cronjobs/kenshoo/csv_reports/csv_*'
alias rm-uploaded-docs='sudo rm -rf ./public/members/uploadeddocs/*'
# SVN shotcut aliases
alias svn-add-unstaged="svn st | grep '^?' | awk '{print $2}' | xargs svn add"
alias svn-remove-unstaged="svn st | grep '^?' | awk '{print $2}' | xargs rm -rf"
alias svn-revert-all="svn st | grep -e '^M' | awk '{print $2}' | xargs svn revert"
alias svn-make-patch="svn diff > $1"
alias svn-apply-patch="patch -p0 -i $1"

export LC_ALL=C

# Bash functions -- mostly SVN wrappers

# Get uncommitted files
#: @depencies: getRootFromDir
function hasUncommittedFiles()
{
	DIR_ROOT=$(getRootFromDir)
	UF=$(cd $DIR_ROOT && svn status | wc -l)
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
		return 0
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
		return 0
	fi

	svn switch ${URL_DEVELOP_ROOT}
}
export -f switchDevelop
# Switch SVN branch
alias swd='sites && switchDevelop'

# Switch SVN branch
# @dependencies: doesBranchExist, hasUncommittedFiles
function switchBranch()
{
	# Branch name is required
	if [ $# -eq 0 ]
	then
		printf "$MSG_FAIL Branch name required.\n$MSG_USAGE sb $EXAMPLE_BRANCH\n"
		return 0
	fi

    # Check branch exists
    if [[ $(doesBranchExist $1) != 'yes' ]]
    then
        printf "$MSG_FAIL branch '${URL_BRANCH_ROOT}$1' doesn't exist\n"
        return 0
    fi

	# Check for uncommitted files
	if hasUncommittedFiles
	then
		printf "$MSG_FAIL You have uncommitted files. You must commit these files before switching:\n\n"
		svn status
        echo
		return 0
	fi

	svn switch ${URL_BRANCH_ROOT}$1;
	printf "${GREEN}Successfully switched to branch:\n${NORMAL}${URL_BRANCH_ROOT}$1\n"
}
export -f switchBranch
alias sb='sites && switchBranch'

# Get the name of the current branch
# @dependencies: getRootFromDir
alias wb='getBranchName'
function getBranchName()
{
	DIR_ROOT=$(getRootFromDir)
	echo $(cd $DIR_ROOT && svn info | grep 'URL:' | grep -oEi '[^/]+$')
}
export -f getBranchName

function getBranchNumberFromName()
{
	# Check for branch name
	if [ $# -eq 0 ]
	then
		printf "$MSG_FAIL Branch name is required.\n$MSG_USAGE getBranchNumberFromName $EXAMPLE_BRANCH\n"
		return 0
	fi
	BRANCH=$1
	BRANCH_NO=$(echo $BRANCH | grep -oEi '^[^_]+')
	echo $BRANCH_NO
}
export -f getBranchNumberFromName

# Get Branch URL
# @dependencies: getRootFromDir
function getBranchURL()
{
	DIR_ROOT=$(getRootFromDir)
	echo $(cd $DIR_ROOT && svn info | grep 'URL: ' | awk '{print $2}')
}
export -f getBranchURL
alias wbu=getBranchURL

# Get the Target Process URL associated with the current branch
# @dependencies: getBranchName, getBranchNumberFromName
function getTPURL
{
	BRANCH=$(getBranchName)
	BRANCH_NO=$(getBranchNumberFromName $BRANCH)

	echo ${URL_TP_TICKET_ROOT}${BRANCH_NO}
}
export -f getTPURL

# Removes periods from commit comments that get info added to them
function removePeriodFromEndOfString()
{
	if [ $# -eq 0 ]
	then
		printf "$MSG_FAIL String required.\n$MSG_USAGE removePeriodFromEndOfString \"This is a comment.\"\n"
		return 0
	fi

    CLEANED=${1/%./}

    echo $CLEANED
}
export -f removePeriodFromEndOfString


# Commit code
#
# @dependencies: getRootFromDir, getBranchName, getBranchNumberFromName,
#                 removePeriodFromEndOfString, getTPURL, getBranchURL,
#                 addCommentToTP
function commitCode()
{
	# Switch to branch root
	DIR_ROOT=$(getRootFromDir)
	cd $DIR_ROOT

	BRANCH=$(getBranchName)
	STATUS=$(svn status | grep -Eo '[a-z].*')
	# If there are no files to commit, say so and exit
	if [[ -z  $STATUS ]]
	then
		printf "There's nothing to commit.\n"
		return 1
	fi

    QUIET=0
	if [[ $2 && $2 = --quiet ]]
	then
        QUIET=1
	fi

    # Prompt about PHP Code Sniffing the committed PHP files, if that exists
	if [[ $QUIET -eq 0 ]] && type -p phpcs > /dev/null;
	then
		PHP_FILES=$(echo $STATUS | tr ' ' '\n' | grep -E '*.php')
		NO_FILES=$(echo $PHP_FILES | grep -v '^\s*$' | wc -l)
		if [[ $NO_FILES -gt 0 && $PHP_FILES ]]
		then
			printf "${CYAN}${PHP_FILES}${NORMAL}\n"
			read -p "Run PHP Code Sniffer on these PHP files? (y/n) "

            if [[ $REPLY =~ ^[Yy]$ ]]
            then
                # Convert newlines to spaces
                ssv=$(echo $PHP_FILES | tr '\n' ' ')
                FAILED=0
                for f in $ssv
                do
                    OUTPUT=$(phpcs $f | tee /dev/tty)
                    ERRORS=$(echo $OUTPUT | grep 'ERROR')
                    if [[ $ERRORS ]]
                    then
                        FAILED=1
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

        DEVELOPER_NAME=""
        REVIEWBOARD_ID=""

        read -p "Has this commit been peer reviewed? (y/n) "
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            # Ask for reviewer name
            NUM=1
            for dev in ${!TF_DEVS[@]}; do
                echo "($NUM) ${CYAN}${TF_DEVS[dev]}${NORMAL}"
                ((NUM++))
            done

            printf "\nChoose the developer who reviewed this commit, or (0) to quit: ";

            read chosen_dev
            if [ $chosen_dev -eq 0 ]
            then
                return 0
            else
                DEVELOPER_NAME="${TF_DEVS[chosen_dev]}"
                printf "${YELLOW}${DEVELOPER_NAME}${NORMAL} chosen.\n"
            fi

            # Enter review board id
            read -p "Enter the Review Board ID: " RBID
            REVIEWBOARD_ID=$RBID
        fi

		BRANCH_NO=$(getBranchNumberFromName $BRANCH)
        echo
	    if [ $# -eq 0 ]
        then
            read -p "Enter your commit comment (if defect: add ticket no.): " COMMENT

		    COMMIT_COMMENT="#$BRANCH_NO comment: $COMMENT"
            # If Developer name and reviewboard id is not blank add it to the commit message
            if [ ! -z "$DEVELOPER_NAME" ] && [ ! -z "$REVIEWBOARD_ID" ]
            then
                # Remove trailing period, if we're attaching info.
                COMMIT_COMMENT=$(removePeriodFromEndOfString "$COMMIT_COMMENT")
                COMMIT_COMMENT="$COMMIT_COMMENT. Reviewed by $DEVELOPER_NAME (RBID: $REVIEWBOARD_ID)."
            fi
        else
            COMMIT_COMMENT=$1
            # TP ticket comment
            COMMENT=$1
        fi

		printf "${CYAN}\n$COMMIT_COMMENT${NORMAL}\n\n"

		read -p "Commit with the following comment? (y/n) "
		if [[ $REPLY =~ ^[Yy]$ ]]
		then
            echo
			OUTPUT=$(svn commit -m "$COMMIT_COMMENT" | tee /dev/tty)
			TP_URL=$(getTPURL)
			printf "\n${GREEN}Success!${NORMAL}\n"

			# Branch URL
			BRANCH_URL=$(getBranchURL)
			# Revision Number
			REV_NO=$(echo $OUTPUT | grep 'Committed revision' | grep -oEi '[0-9]{5,}' | sed -n '$p')

            TP_COMMENT="$COMMENT<br><br>"
			TP_COMMENT="${TP_COMMENT}<strong>Branch:</strong> $BRANCH_URL<br>"
			TP_COMMENT="${TP_COMMENT}<strong>Revision:</strong> $REV_NO<br>"
			TP_COMMENT="${TP_COMMENT}<strong>Changeset:</strong> ${URL_CHANGESET_ROOT}${REV_NO}<br>"
            # Add reviewboard info if not blank
            if [ ! -z "$REVIEWBOARD_ID" ]
            then
                TP_COMMENT="${TP_COMMENT}<strong>Commit reviewed by:</strong> $DEVELOPER_NAME http://reviewboard.uk.paydayone.com/r/$REVIEWBOARD_ID/"
            fi

            # Add comment to Target Process ticket
            TP_COMMENT_RESULT=$(addCommentToTP $BRANCH_NO "$TP_COMMENT")

            echo $TP_COMMENT_RESULT

		else
            echo
			return 0
		fi
	else
        echo
		return 0
	fi
}
export -f commitCode
alias commit='commitCode'

function addCommentToTP()
{
    # Check branch number (TPID) and comment given
    if [ $# -eq 0 ]
    then
        printf "$MSG_FAIL Branch number and TP comment required.\n$MSG_USAGE addCommentToTP 123456 \"TP comment\"\n"
        return 0
    fi

    if [[ -z "$1" ]]
    then
        printf "$MSG_FAIL Branch number is required.\n$MSG_USAGE addCommentToTP 123456 \"TP comment\"\n"
        return 0
    fi

    if [[ -z "$2" ]]
    then
        printf "$MSG_FAIL Target Process comment (quoted) is required. HTML allowed.\n$MSG_USAGE addCommentToTP 123456 \"TP comment\"\n"
        return 0
    fi

    # TP_AUTH_TOKEN stored in ~/think-finance/think-finance-private.sh
    TP_COMMENT_RESULT=$(php $HOME/think-finance/tools/helpers/tp-add-comment.php $TP_AUTH_TOKEN $1 "$2")

    echo -e $TP_COMMENT_RESULT
}
export -f addCommentToTP
alias addTpComment='addCommentToTP'


function doesRevisionExist()
{
	# Check for revision URL
	if [ $# -eq 0 ]
	then
		printf "$MSG_FAIL Revision URL is required.\n$MSG_USAGE dre $URL_BRANCH_ROOT@12345\n"
		return 0
	fi

    # Send stdout and stderr to /dev/null
    if svn info $1 &> /dev/null; then
        echo "yes"
    else
        echo "no"
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
		return 0
	fi

    HEAD_REVISION="$(svn info $1 | grep 'Revision' | awk '{print $2}')"

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
        return 0
	fi

	# Check branch name starts with [0-9]_
	if ! [[ $1 =~ [0-9]_.+ ]]
	then
		printf "$MSG_FAIL Branch names need to start with their Target Process number.\n"
        printf "$MSG_USAGE nb $EXAMPLE_BRANCH\n";
        return 0
	fi

	# Check branch name ends in _[1-9]
	if ! [[ $1 =~ .+_[0-9]{1,2}$ ]]
	then
		printf "$MSG_FAIL Branch names need to end in a version number _1.\n"
        printf "$MSG_USAGE nb $EXAMPLE_BRANCH\n";
        return 0
	fi

    # Check branch exists
    if [[ $(doesBranchExist $1) == 'yes' ]]
    then
        printf "$MSG_FAIL Branch ${YELLOW}$1${NORMAL} already exists!\n"
        return 0
    fi

    # Develop is most common
    COPY_ROOT=${URL_DEVELOP_ROOT}
    COPY_ROOT_NAME="DEVELOP (HEAD)"

    read -p "Choose branch base: (1) Develop, (2) Trunk, (3) Branch: "
    if [[ $REPLY =~ ^[1]$ ]]
    then
        read -p "Enter revision number of Develop to branch from, OR (0) for HEAD: " REVISION
        if [[ $REVISION -eq 0 ]]
        then
            COPY_ROOT=${URL_DEVELOP_ROOT}
            COPY_ROOT_NAME="DEVELOP (HEAD)"
            printf "${GREEN}${COPY_ROOT_NAME}${NORMAL} chosen (${YELLOW}${URL_DEVELOP_ROOT}${NORMAL})\n"
        else
            # Validate revision number
            COPY_ROOT=${URL_DEVELOP_ROOT}@${REVISION}
            if [[ $(doesRevisionExist ${COPY_ROOT}) != 'yes' ]]
            then
                printf "$MSG_FAIL Revision '${YELLOW}${COPY_ROOT}${NORMAL}' doesn't exist\n"
                return 0
            fi
            COPY_ROOT_NAME="DEVELOP @ r${REVISION}"
            printf "${GREEN}${COPY_ROOT_NAME}${NORMAL} chosen (${YELLOW}${COPY_ROOT}${NORMAL})\n"
        fi

    elif [[ $REPLY =~ ^[2]$ ]]
    then
        COPY_ROOT=${URL_TRUNK_ROOT}
        COPY_ROOT_NAME="TRUNK"
        printf "${GREEN}${COPY_ROOT_NAME}${NORMAL} chosen (${YELLOW}${COPY_ROOT}${NORMAL})\n"

    elif [[ $REPLY =~ ^[3]$ ]]
    then
        read -p "Enter branch name to copy from: " BRANCH_NAME
        # Check branch exists
        if [[ $(doesBranchExist $BRANCH_NAME) != 'yes' ]]
        then
            printf "$MSG_FAIL branch '${URL_BRANCH_ROOT}$BRANCH_NAME' doesn't exist\n"
            return 0
        fi

        COPY_ROOT=${URL_BRANCH_ROOT}$BRANCH_NAME
        COPY_ROOT_NAME=$BRANCH_NAME
        printf "${GREEN}${COPY_ROOT_NAME}${NORMAL} chosen (${YELLOW}${COPY_ROOT}${NORMAL})\n"

    fi

    # Get the latest revision of the branch we're copying from
    REVISION=$(getHeadRevisionFromBranch $COPY_ROOT)
    CREATED_FROM="Branch copied from $COPY_ROOT_NAME [r$REVISION]"

    # Check comment is passed in the second parameter
    if [[ -z "$2" ]]
    then
        BRANCH_NO=$(echo $1 | grep -oEi ^[0-9]+)
        read -p "Enter a description of this branch: " DESCRIPTION

        # Remove trailing period, if that exists
        DESCRIPTION=$(removePeriodFromEndOfString "$DESCRIPTION")
        BRANCH_COMMENT="#$BRANCH_NO comment: $DESCRIPTION. $CREATED_FROM"
    else
        BRANCH_COMMENT="${2/ROOT_BRANCH/$COPY_ROOT_NAME} [r$REVISION]"
    fi

    printf "${CYAN}$BRANCH_COMMENT${NORMAL}\n"

    read -p "Create a new branch from ${GREEN}${COPY_ROOT_NAME}${NORMAL} with this commit comment? (y/n) "
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # Create the branch
        svn copy ${COPY_ROOT} ${URL_BRANCH_ROOT}$1 -m "$BRANCH_COMMENT"
        printf "${GREEN}Branch ${CYAN}$1${NORMAL} ${GREEN}created successfully.${NORMAL}\n";
        printf "${URL_BRANCH_ROOT}$1\n\n"

        NEW_BRANCH_REV=$(getHeadRevisionFromBranch ${URL_BRANCH_ROOT}$1)

        TP_COMMENT="$BRANCH_COMMENT<br><br>"
        TP_COMMENT="$TP_COMMENT<strong>Branch created:</strong> ${URL_BRANCH_ROOT}$1<br>"
        TP_COMMENT="$TP_COMMENT<strong>Origin:</strong> $CREATED_FROM<br>"
        TP_COMMENT="$TP_COMMENT<strong>Revision:</strong> $NEW_BRANCH_REV"

        # Add branch created to Target Process ticket
        TP_COMMENT_RESULT=$(addCommentToTP $BRANCH_NO "$TP_COMMENT")

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
                return 0
            fi
        else
            echo
            return 0
        fi
    else
        echo
        return 0
    fi
}
export -f newBranch
alias nb='sites && newBranch'

# Gets the dir root for the given branch (e.g. /var/www/html)
function getRootFromDir()
{
	# Default
	ROOT='/var/www/html'

	# If we're inside /tools
	if [[ $(pwd | grep '/tools') ]]
	then
		ROOT='/var/www/html/public/tools'
	fi

    # If we're in /var/www/loans
	if [[ $(pwd | grep '/www/loans') ]]
    then
        ROOT='/var/www/loans/public'
    fi

    # If we're in /var/www/loans
	if [[ $(pwd | grep '/www/compare') ]]
    then
        ROOT='/var/www/compare/public'
    fi

	echo $ROOT
}
export -f getRootFromDir

function doesBranchExist()
{
	# Check for branch name given
	if [ $# -eq 0 ]
	then
		printf "$MSG_FAIL Branch name is required.\n$MSG_USAGE be $EXAMPLE_BRANCH\n"
		return 0
	fi

    # Send stdout and stderr to /dev/null
    if svn ls ${URL_BRANCH_ROOT}$1 &> /dev/null; then
        echo "yes"
    else
        echo "no"
    fi
}
export -f doesBranchExist
alias be='sites && doesBranchExist'

function getVersionNumber()
{
    VERSION_NUM=$(getBranchName | grep -o '[0-9]*$')
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
    NEXT_VERSION_NUM=$(getVersionNumber)
    ((NEXT_VERSION_NUM++))
    echo $NEXT_VERSION_NUM
}
export -f getNextVersionNumber

function getAllRevisionsFromBranch()
{
	if [ $# -eq 0 ]
	then
		printf "$MSG_FAIL Branch name is required.\n$MSG_USAGE getAllRevisionsFromBranch $EXAMPLE_BRANCH\n"
		return 0
	fi
	BRANCH=$1
    echo $(svn log --stop-on-copy "${URL_BRANCH_ROOT}${BRANCH}" | grep -Po '^r[^ ]+')
}

function getRevisionRange()
{
	if [ $# -eq 0 ]
	then
		printf "$MSG_FAIL Branch name is required.\n$MSG_USAGE getFirstLastRevision $EXAMPLE_BRANCH\n"
		return 0
	fi
	BRANCH=$1
    ALL_REVS=$(getAllRevisionsFromBranch $1)
    # Replace spaces with newlines
    REV_LINES=$(echo $ALL_REVS | tr ' ' '\n' | sed -n '1p;$p' | sort | uniq | tr -d 'r')
    echo $REV_LINES
}
export -f getRevisionRange

function getRevisionCMD()
{
	if [ $# -eq 0 ]
	then
		printf "$MSG_FAIL Branch name is required.\n$MSG_USAGE getRevisionCMD $EXAMPLE_BRANCH\n"
		return 0
	fi
	BRANCH=$1

    REV_RANGE=$(getRevisionRange $BRANCH)
    REV_ARRAY=($REV_RANGE)
    if [[ ${#REV_ARRAY[@]} -eq 2 ]]
    then
        # Annoyingly, you have to specify REV-1 if you want that REV to be merged.
        FIRST_REV=${REV_ARRAY[0]}
        ((FIRST_REV--))
        REV_RANGE=$FIRST_REV:${REV_ARRAY[1]}
    else
        REV_RANGE="-c ${REV_ARRAY[0]}"
    fi

    echo $REV_RANGE
}
export -f getRevisionCMD

function getRevisionRangeForComment()
{
	if [ $# -eq 0 ]
	then
		printf "$MSG_FAIL Branch name is required.\n$MSG_USAGE getRevisionCMD $EXAMPLE_BRANCH\n"
		return 0
	fi
	BRANCH=$1

    REV_RANGE=$(getRevisionRange $BRANCH)
    REV_ARRAY=($REV_RANGE)
    if [[ ${#REV_ARRAY[@]} -eq 2 ]]
    then
        FIRST_REV=${REV_ARRAY[0]}
        ((FIRST_REV--))
        REV_RANGE=${REV_ARRAY[0]}-${REV_ARRAY[1]}
    else
        REV_RANGE="${REV_ARRAY[0]}"
    fi

    echo $REV_RANGE
}
export -f getRevisionRangeForComment

function getCommitInfoFromBranch()
{
	if [ $# -eq 0 ]
	then
		printf "$MSG_FAIL Branch name is required.\n$MSG_USAGE getFirstLastRevision $EXAMPLE_BRANCH\n"
		return 0
	fi
	BRANCH=$1
    echo $(svn log --stop-on-copy "${URL_BRANCH_ROOT}${BRANCH}" | grep -Po '^r[^ ]+')
}
export -f getCommitInfoFromBranch

function viewHistory()
{
    BRANCH_NAME=$(getBranchName)
    svn log -v --stop-on-copy ${URL_BRANCH_ROOT}${BRANCH_NAME}
}
export -f viewHistory
alias vh='viewHistory'

function getNextBranchName()
{
    NEXT_VERSION_NUM=$(getNextVersionNumber)
    BRANCH_NAME=$(getBranchName)
    BRANCH_WITH_VERSION_NUM=$(echo $BRANCH_NAME | grep -o '.*_[0-9]$')
    if [[ -z $BRANCH_WITH_VERSION_NUM ]]
    then
        NEXT_BRANCH_NAME=$(getBranchName)_${NEXT_VERSION_NUM}
    else
        NEXT_BRANCH_NAME=$(getBranchName | grep -o '.*_')${NEXT_VERSION_NUM}
    fi
    echo $NEXT_BRANCH_NAME
}
export -f getNextBranchName

function rebaseline()
{
    THIS_BRANCH=$(getBranchName)
    BRANCH_NO=$(getBranchNumberFromName ${THIS_BRANCH})
    NEXT_BRANCH_NAME=$(getNextBranchName)

    # Show nice summary of changes
    printf "${GREEN}Commit log:${NORMAL} ${THIS_BRANCH}\n"
    echo ${URL_BRANCH_ROOT}${THIS_BRANCH}
    svn log -v --stop-on-copy ${URL_BRANCH_ROOT}${THIS_BRANCH}
    echo
    read -p "Create ${YELLOW}${NEXT_BRANCH_NAME}${NORMAL} and merge ${GREEN}all commits${NORMAL} from '${CYAN}${THIS_BRANCH}${NORMAL}'? (y/n) "
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # Create new branch
        BRANCH_COMMENT="#${BRANCH_NO} comment: Rebaseline ${THIS_BRANCH} with ROOT_BRANCH."
        nb ${NEXT_BRANCH_NAME} "$BRANCH_COMMENT"

        # Switch to new branch
        printf "Switching to ${YELLOW}${NEXT_BRANCH_NAME}${NORMAL}...\n"
        sb $NEXT_BRANCH_NAME

        # Test merge with previous version
        REVISIONS_TO_MERGE=$(getRevisionCMD $THIS_BRANCH)

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
            BRANCH_NUM=$(getBranchNumberFromName ${THIS_BRANCH})
            REVISIONS_FOR_COMMENT=$(getRevisionRangeForComment $THIS_BRANCH)
            COMMIT_MSG="#${BRANCH_NUM} comment: Merged revisions [${REVISIONS_FOR_COMMENT}] from ${THIS_BRANCH}"
            echo
            commit "$COMMIT_MSG" --quiet
        else
            return 0
        fi
    else
        return 0
    fi
}

# Thanks to Adam Atkins for this sexy function
function findBranch()
{
    if [ $# -ge 1 ]
    then
        sites
        branchArr=($(svn ls ${URL_BRANCH_ROOT} | grep "$1"))
        NUM=0
        for branch in ${!branchArr[@]}; do
            ((NUM++))
            echo "($NUM) ${CYAN}${branchArr[branch]}${NORMAL}"
        done
        printf "\nChoose a branch to switch to, or (0) to quit: ";
        read branchNum
        if [ $branchNum -eq 0 ]
        then
            return 0
        else
            ((branchNum--))
            printf "Switching to: ${CYAN}${branchArr[branchNum]}${NORMAL}\n"
            sb ${branchArr[branchNum]}
            return 1
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
            return 1
        else
            return 0
        fi
    fi
}

function getPalindromeMessage()
{
    MESSAGE=''
    if [ $# -ge 1 ]
    then
        if [ $(isPalindrome $1) ] 
        then
            MESSAGE='Congratulations! You just won a Fish trophy for having a palindromic ReviewBoard ID'
        fi
    fi
}

function getBranchHistory()
{
    echo $(grep 'nb\|sb' ~/.bash_history | awk '{print $2}' | grep -v 'grep\|nb\|sb' | uniq | sort)
}
export -f getBranchHistory
alias bh='getBranchHistory | tr " " "\n"'

function createPostReviewWithInfo()
{
	# Switch to branch root
	DIR_ROOT=$(getRootFromDir)
	cd $DIR_ROOT

	BRANCH_URL=$(getBranchURL)
	BRANCH=$(getBranchName)
	BRANCH_NO=$(getBranchNumberFromName $BRANCH)

    read -p "Enter a Review Board summary: " SUMMARY
    RB_SUMMARY="#${BRANCH_NO} - $SUMMARY"
	printf "Summary: ${CYAN}${RB_SUMMARY}${NORMAL}\n\n"

    read -p "Enter a Review Board description: " DESCRIPTION
	printf "Description: ${CYAN}${DESCRIPTION}${NORMAL}\n\n"

    read -p "Create code review with the following comment? (y/n) "
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        post-review --branch=$BRANCH_URL --bugs-closed="$BRANCH_NO" --summary="$RB_SUMMARY" --description="$DESCRIPTION"
    else
        echo
        return 0
    fi

}
export -f createPostReviewWithInfo
alias ccr='createPostReviewWithInfo'

export PATH=$PATH:/lib/:/lib/node_modules/npm/bin/:/usr/bin/phpunit
export SVN_EDITOR=vim

# source custom bash autocompletions
if [ -f /etc/bash_completion.d/sb ]; then
	. /etc/bash_completion.d/sb
fi
if [ -f /etc/bash_completion.d/nb ]; then
	. /etc/bash_completion.d/nb
fi
