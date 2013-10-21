#!/bin/bash

#----------------------------------
# Think Finance Specific Bash
#----------------------------------

# Global variables
EXAMPLE_BRANCH="201982_branch_name_1"
MSG_USAGE="${YELLOW}Usage:${NORMAL}"
MSG_FAIL="${RED}[FAIL]${NORMAL}"
CURRENT_DIR="${BASH_SOURCE%/*}"

# Source private variables
if [ -f ${CURRENT_DIR}/think-finance-private.sh ]; then
	source ${CURRENT_DIR}/think-finance-private.sh
else
	printf '[Error] Required Think Finance variables not found.'
	return 0
fi

# Aliases
alias sites='cd /var/www/html/'
alias views='cd /var/www/html/application/views/scripts'
alias controllers='cd /var/www/html/application/controllers'
alias services='cd /var/www/html/application/services'
alias models='cd /var/www/html/application/models/DbTable'
alias styles='cd /var/www/html/public/mobile/css'
alias images='cd /var/www/html/public/mobile/images'
alias scripts='cd /var/www/html/public/mobile/scripts'
alias comms='cd /var/www/html/public/common/lib/customer_comms'
alias tools='cd /var/www/html/public/tools'
alias layouts='cd /var/www/html/application/layouts/scripts'
alias tests='cd /var/www/html/tests'
alias sql='cd /var/www/html/sql'
alias lb='svn ls ${URL_BRANCH_ROOT} --verbose'
alias mb='lb | grep nkowald'
alias restart_apache='sudo /etc/init.d/crond stop && sudo service httpd stop && sudo service httpd start && sudo /etc/init.d/crond start'
alias restart_mysql='sudo /sbin/service mysql restart'
alias ephpi='sudo vim /etc/php.ini'
alias eac='sudo vim /etc/httpd/conf/httpd.conf'

# tmux aliases
# Attach to the 1st available session and show a selector for the rest
alias ts="tmux attach-session -t `tmux list-sessions -F '#{session_name}' | tail -n 1` \; choose-session"
alias tls="tmux list-sessions"

# Removal shortcut aliases
alias rm-kenshoo='sudo rm -rf ./public/Cronjobs/kenshoo/csv_reports/csv_*'
alias rm-uploaded-docs='sudo rm -rf ./public/members/uploadeddocs/*'

# Svn shotcut aliases
alias svn-add-unstaged="svn st | grep '^?' | awk '{print $2}' | xargs svn add"
alias svn-remove-unstaged="svn st | grep '^?' | awk '{print $2}' | xargs rm -rf"
alias svn-revert-all="svn st | grep -e '^M' | awk '{print $2}' | xargs svn revert"
alias svn-make-patch="svn diff > $1"
alias svn-apply-patch="patch -p0 -i $1" 

export LC_ALL=C
# Bash functions -- mostly SVN wrappers

# Get uncommitted files
function getUncommittedFiles() {
	DIR_ROOT=$(getRootFromDir)
	UF=$(cd $DIR_ROOT && svn status | wc -l)
	if [ $UF -gt 0 ]
	then
		return 0
	else 
		return 1
	fi
}
export -f getUncommittedFiles

# Switch to trunk
function switchTrunk() {
	# Check for uncommitted files
	if getUncommittedFiles
	then
		printf "$MSG_FAIL You have uncommitted files. You must commit these files before switching:\n\n"
		svn status
		printf "\n"
		return 0
	fi

	svn switch ${URL_TRUNK_ROOT}
}
export -f switchTrunk
alias swt='sites && switchTrunk'

# Switch to develop
function switchDevelop() {
	# Check for uncommitted files
	if getUncommittedFiles
	then
		printf "$MSG_FAIL You have uncommitted files. You must commit these files before switching:\n\n"
		svn status
		printf "\n"
		return 0
	fi

	svn switch ${URL_DEVELOP_ROOT}
}
export -f switchDevelop
# Switch SVN branch
alias swd='sites && switchDevelop'

# Switch SVN branch
function switchBranch() {
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
	if getUncommittedFiles
	then
		printf "$MSG_FAIL You have uncommitted files. You must commit these files before switching:\n\n"
		svn status
		printf "\n"
		return 0
	fi

	svn switch ${URL_BRANCH_ROOT}$1;
	printf "${GREEN}Successfully switched to branch:\n${NORMAL}${URL_BRANCH_ROOT}$1\n"
}
export -f switchBranch
alias sb='sites && switchBranch'

# Get the name of the current branch
alias wb='getBranchName'
function getBranchName() {
	DIR_ROOT=$(getRootFromDir)
	echo $(cd $DIR_ROOT && svn info | grep 'URL:' | grep -oEi '[^/]+$')
}
export -f getBranchName

function getBranchNumberFromName() {
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
function getBranchURL() {
	DIR_ROOT=$(getRootFromDir)
	echo $(cd $DIR_ROOT && svn info | grep 'URL: ' | grep -oEi 'http.+')
}
export -f getBranchURL
alias wbu=getBranchURL

# Get the Target Process URL associated with the current branch
function getTPURL {
	BRANCH=$(getBranchName)
	BRANCH_NO=$(getBranchNumberFromName $BRANCH)

	echo ${URL_TP_TICKET_ROOT}${BRANCH_NO}
}
export -f getTPURL

# Commit code
function commitCode() {
	# Switch to branch root 
	DIR_ROOT=$(getRootFromDir)
	cd $DIR_ROOT

	BRANCH=$(getBranchName)
	STATUS=$(svn status | grep -Eo '[a-z].*')
	# If there are no files to commit, say so and exit
	if [[ -z  $STATUS ]]
	then
		printf "There's nothing to commit.\n"
		return 0
	fi

    QUIET=0
	if [[ $2 && $2 = --quiet ]]
	then
        QUIET=1
	fi

	# Prompt about PHP Code Sniffer if that exists
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
						return 0
					else
						printf "${GREEN}Success! Code meets the coding standard.${NORMAL}\n\n"
					fi

				fi
		fi
	fi

	svn status

	printf "\n"
	read -p "Commit theses files to ${YELLOW}$BRANCH${NORMAL}? (y/n) "

	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		BRANCH_NO=$(getBranchNumberFromName $BRANCH)
		printf "\n"
	    if [ $# -eq 0 ]
        then 
		    read -p "Enter your commit comment: " COMMENT
		    COMMIT_COMMENT="#$BRANCH_NO comment: $COMMENT" 
        else
            COMMIT_COMMENT=$1
        fi

		printf "${CYAN}\n$COMMIT_COMMENT${NORMAL}\n\n"

		read -p "Commit with the following comment? (y/n) "
		if [[ $REPLY =~ ^[Yy]$ ]]
		then 
			printf "\n"
			OUTPUT=$(svn commit -m "$COMMIT_COMMENT" | tee /dev/tty)
			TP_URL=$(getTPURL)
			printf "\n${GREEN}Success!${NORMAL} Make sure you update the TP ticket:\n$TP_URL\n\n"
			printf "TP ticket comment:\n"
			# Branch URL
			BRANCH_URL=$(getBranchURL)
			printf "Branch: $BRANCH_URL\n"
			# Revision Number
			REV_NO=$(echo $OUTPUT | grep 'Committed revision' | grep -oEi '[0-9]{5,}' | sed -n '$p')
			printf "Revision: $REV_NO\n"
			# Revision URL
			printf "Changeset: ${URL_CHANGESET_ROOT}${REV_NO}\n\n"
		else
			printf "\n"
			return 0
		fi
	else
		printf "\n"
		return 0
	fi
}
export -f commitCode
alias commit='commitCode'

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

# Create new SVN branch based on Trunk
function newBranch() {

	MSG_FORCE="${CYAN}Hint:${NORMAL} To create a branch named '$1', add the --force flag: 'nb $1 --force'\n"

	# Check for branch name
	if [ $# -eq 0 ]
	then
		printf "$MSG_FAIL New branch name is required.\n$MSG_USAGE nb $EXAMPLE_BRANCH\n"
		return 0
	fi

    # Check branch exists
    if [[ $(doesBranchExist $1) == 'yes' ]]
    then
        printf "$MSG_FAIL Branch ${YELLOW}$1${NORMAL} already exists!\n"
        return 0
    fi

	# Check branch name starts with [0-9]_
	if ! [[ $1 =~ [0-9]_.+ ]]
	then
		printf "$MSG_FAIL Branch names need to start with their associated Target Process number.\n$MSG_USAGE nb $EXAMPLE_BRANCH\n$MSG_FORCE"
		return 0
	fi

	# Check branch name ends in _[1-9]
	if ! [[ $1 =~ .+_[1-9]$ ]]
	then
		printf "$MSG_FAIL Branch names need to end in a version number _1.\n$MSG_USAGE nb $EXAMPLE_BRANCH\n$MSG_FORCE"
		return 0
	fi

    # Develop is most common
    COPY_ROOT=${URL_DEVELOP_ROOT}
    COPY_ROOT_NAME="${GREEN}DEVELOP${NORMAL}"

    printf "\n"
    read -p "Choose branch base (1) Develop, (2) Trunk: "
    if [[ $REPLY =~ ^[1]$ ]]
    then
        read -p "Enter revision number of Develop to branch from, OR (0) for HEAD: " REVISION
        if [[ $REVISION -eq 0 ]]
        then
            COPY_ROOT=${URL_DEVELOP_ROOT}
            COPY_ROOT_NAME="${GREEN}DEVELOP${NORMAL}"
            printf "${COPY_ROOT_NAME} chosen (${YELLOW}${URL_DEVELOP_ROOT}${NORMAL})\n"
        else
            # Validate revision number
            COPY_ROOT=${URL_DEVELOP_ROOT}@${REVISION}
            if [[ $(doesRevisionExist ${COPY_ROOT}) != 'yes' ]]
            then
                printf "$MSG_FAIL Revision '${YELLOW}${COPY_ROOT}${NORMAL}' doesn't exist\n"
                return 0
            fi
            COPY_ROOT_NAME="${GREEN}DEVELOP @ r${REVISION}${NORMAL}"
            printf "${COPY_ROOT_NAME} chosen (${YELLOW}${COPY_ROOT}${NORMAL})\n"
        fi
    elif [[ $REPLY =~ ^[2]$ ]]
    then
        COPY_ROOT=${URL_TRUNK_ROOT}
        COPY_ROOT_NAME="${GREEN}TRUNK${NORMAL}"
        printf "${COPY_ROOT_NAME} chosen (${YELLOW}${COPY_ROOT}${NORMAL})\n"
    fi

	if [[ $2 && $2 = --force ]]
	then
		svn copy ${COPY_ROOT} ${URL_BRANCH_ROOT}$1
		svn info;
		return 0
	fi


	BRANCH_NO=$(echo $1 | grep -oEi ^[0-9]+)
	read -p "Enter a description of this branch: " DESCRIPTION
	BRANCH_COMMENT="#$BRANCH_NO comment: $DESCRIPTION"
	printf "${CYAN}$BRANCH_COMMENT${NORMAL}\n"

	read -p "Create a new branch from ${COPY_ROOT_NAME} with this commit comment? (y/n) "
	if [[ $REPLY =~ ^[Yy]$ ]]
	then 
		# Create the branch
		svn copy ${COPY_ROOT} ${URL_BRANCH_ROOT}$1 -m "$BRANCH_COMMENT"
		printf "${GREEN}Branch ${CYAN}$1${NORMAL} ${GREEN}created successfully.${NORMAL}\n";
		printf "${URL_BRANCH_ROOT}$1\n\n"

		#CURRENT_BRANCH=$(getBranchName)

		read -p "Switch to ${YELLOW}$1${NORMAL} now? (y/n) "
		if [[ $REPLY =~ ^[Yy]$ ]]
		then 
			printf "\n"
			switchBranch $1
			return 0
		else 
			printf "\n"
			return 0
		fi
	else 
		printf "\n"
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
    printf "\n"
    read -p "Create ${YELLOW}${NEXT_BRANCH_NAME}${NORMAL} from ${CYAN}trunk${NORMAL} and merge ${GREEN}all commits${NORMAL} from '${CYAN}${THIS_BRANCH}${NORMAL}'? (y/n) "
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # Create new branch
        #printf "Creating ${YELLOW}${NEXT_BRANCH_NAME}${NORMAL}...\n"
        BRANCH_COMMENT="#${BRANCH_NO} comment: Rebaseline ${THIS_BRANCH} with trunk."
        svn copy ${URL_TRUNK_ROOT} ${URL_BRANCH_ROOT}${NEXT_BRANCH_NAME} -m "$BRANCH_COMMENT"
        #printf "Created ${YELLOW}${NEXT_BRANCH_NAME}${NORMAL} with branch comment: '${BRANCH_COMMENT}'\n\n"

        # Switch to new branch
        printf "Switching to ${YELLOW}${NEXT_BRANCH_NAME}${NORMAL}...\n"
        sb $NEXT_BRANCH_NAME

        # Test merge with previous version
        REVISIONS_TO_MERGE=$(getRevisionCMD $THIS_BRANCH)

        printf "\n${GREEN}Test merge:${NORMAL}\n"
        printf "${MAGENTA}Running:${NORMAL} svn merge --dry-run -r $REVISIONS_TO_MERGE ${URL_BRANCH_ROOT}${THIS_BRANCH}\n"

        svn merge --dry-run -r $REVISIONS_TO_MERGE ${URL_BRANCH_ROOT}${THIS_BRANCH}

        # Merge for good
        printf "\n"
        read -p "Merge and commit? (y/n) "
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            printf "\n${GREEN}Merge:${NORMAL}\n"
            # Merge it so!
            svn merge -r $REVISIONS_TO_MERGE ${URL_BRANCH_ROOT}${THIS_BRANCH}

            printf "\n"
            # Commit!
            BRANCH_NUM=$(getBranchNumberFromName ${THIS_BRANCH})
            REVISIONS_FOR_COMMENT=$(getRevisionRangeForComment $THIS_BRANCH)
            COMMIT_MSG="#${BRANCH_NUM} comment: Merged revisions [${REVISIONS_FOR_COMMENT}] from ${THIS_BRANCH}"
            printf "\n"
            commit "$COMMIT_MSG" --quiet
        else
            return 0
        fi
    else
        return 0
    fi
}

function findBranch() 
{
    if [ $# -ge 1 ]
    then
        sites
        branchArr=($(svn ls https://trac.fg123.co.uk/svn/elastic/branches | grep "$1"))
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
export PATH=$PATH:/lib/:/lib/node_modules/npm/bin/:/usr/bin/phpunit
export SVN_EDITOR=vim

# source custom bash autocompletions
if [ -f /etc/bash_completion.d/sb ]; then
	. /etc/bash_completion.d/sb
fi
if [ -f /etc/bash_completion.d/nb ]; then
	. /etc/bash_completion.d/nb
fi

