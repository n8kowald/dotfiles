#!/bin/bash

#----------------------------------
# Think Finance Specific Bash
#----------------------------------

# Global variables
EXAMPLE_BRANCH="201982_branch_name_1"
MSG_USAGE="${YELLOW}Usage:"
MSG_FAIL="${RED}[FAIL]${NORMAL}"

# Source private variables
if [ -f ~/dotfiles/bashrc_modules/think-finance-private.sh ]; then
	source ~/dotfiles/bashrc_modules/think-finance-private.sh
else
	printf '[${RED}Error${NORMAL}] Required Think Finance variables not found.'
	return 0
fi

# Aliases
alias sites='cd /var/www/html/'
alias views='cd /var/www/html/application/views/scripts'
alias controllers='cd /var/www/html/application/controllers'
alias styles='cd /var/www/html/public/mobile/css'
alias images='cd /var/www/html/public/mobile/images'
alias scripts='cd /var/www/html/public/mobile/scripts'
alias comms='cd /var/www/html/public/common/lib/customer_comms'
alias tools='cd /var/www/html/public/tools'
alias layouts='cd /var/www/html/application/layouts/scripts'
alias tests='cd /var/www/html/tests'
alias sql='cd /var/www/html/sql'
alias lb='svn ls ${URL_BRANCH_ROOT} --verbose'
alias swt='cd /var/www/html && switchTrunk'
alias restart_apache='sudo service httpd start'
alias restart_mysql='sudo /sbin/service mysql restart'

# Bash function -- mostly SVN wrappers

# Get uncommitted files
function getUncommittedFiles() {
	UF=$(cd /var/www/html && svn status | wc -l)
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

# Switch SVN branch
alias sb='cd /var/www/html && switchBranch'
function switchBranch() {
	# Branch name is required
	if [ $# -eq 0 ]
	then
		printf "$MSG_FAIL Branch name required.\n$MSG_USAGE sb 191043_sunny_tips_7\n"
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
	printf "${GREEN}Successfully switched to branch: ${NORMAL}${URL_BRANCH_ROOT}$1\n"
}
export -f switchBranch

# Get the name of the current branch
alias wb='getBranchName'
function getBranchName() {
	echo $(svn info | grep 'URL:' | grep -oEi '[^/]+$')
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

# Get the Target Process URL associated with the current branch
alias wbu='getBranchURL'
function getBranchURL {
	BRANCH=$(getBranchName)
	BRANCH_NO=$(getBranchNumberFromName $BRANCH)
	echo ${URL_TICKET_ROOT}${BRANCH_NO}
}
export -f getBranchURL

# Commit code
alias commit='cd /var/www/html && commitCode'
function commitCode() {
	BRANCH=$(getBranchName)
	STATUS=$(svn status)
	# If there are no files to commit, say so and exit
	if [[ -z  $STATUS ]]
	then
		printf "There's nothing to commit.\n"
		return 0
	fi

	svn status

	printf "\n"
	read -p "Commit the above files to ${YELLOW}$BRANCH${NORMAL}? (y/n) " -n 1

	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		BRANCH_NO=$(getBranchNumberFromName $BRANCH)
		printf "\n"
		read -p "Enter your commit comment: " COMMENT
		COMMIT_COMMENT="#$BRANCH_NO comment: $COMMENT" 
		printf "\n$COMMIT_COMMENT\n\n"

		read -p "Is this comment okay? (y/n) " -n 1
		if [[ $REPLY =~ ^[Yy]$ ]]
		then 
			printf "\n\n"
			OUTPUT=$(svn commit -m "$COMMIT_COMMENT" | tee /dev/tty)
			printf "\n${GREEN}Success!${NORMAL} Make sure you update the TP ticket:\n${URL_TICKET_ROOT}${BRANCH_NO}\n\n"
			printf "TP ticket comment:\n"
			# Branch URL
			printf "Branch: $(svn info | grep 'URL: ' | grep -oEi 'http.+')\n"
			# Revision Number
			REV_NO=$(echo $OUTPUT | grep 'Committed revision' | grep -oEi '[0-9]{5,}')
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

# Create new SVN branch based on Trunk
alias nb='cd /var/www/html && newBranch'
function newBranch() {

	MSG_FORCE="${CYAN}Hint: To create a branch named '$1', add the --force flag: 'nb $1 --force'\n"

	# Check for branch name
	if [ $# -eq 0 ]
	then
		printf "$MSG_FAIL New branch name is required.\n$MSG_USAGE nb $EXAMPLE_BRANCH\n"
		return 0
	fi

	if [[ $2 && $2 = --force ]]
	then
		svn copy ${URL_TRUNK_ROOT} ${URL_BRANCH_ROOT}$1
		svn info;
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

	BRANCH_NO=$(echo $1 | grep -oEi ^[0-9]+)
	read -p "Enter a description of this branch: " DESCRIPTION
	BRANCH_COMMENT="#$BRANCH_NO comment: $DESCRIPTION"
	printf "\n$BRANCH_COMMENT\n\n"

	read -p "Create a new branch with this commit comment? (y/n) " -n 1
	if [[ $REPLY =~ ^[Yy]$ ]]
	then 
		# Create the branch
		svn copy ${URL_TRUNK_ROOT} ${URL_BRANCH_ROOT}$1 -m "$BRANCH_COMMENT"
		printf "\n\n${GREEN}Branch${NORMAL} ${CYAN}$1${NORMAL} ${GREEN}created successfully.${NORMAL}\n";
		printf "${URL_BRANCH_ROOT}$1\n\n"

		#CURRENT_BRANCH=$(getBranchName)

		read -p "Switch to ${CYAN}$1${NORMAL} now? (y/n) " -n 1
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

export PATH=$PATH:/lib/:/lib/node_modules/npm/bin/:/usr/bin/phpunit
export SVN_EDITOR=vim

# source custom bash autocompletions
if [ -f /etc/bash_completion.d/sb ]; then
	. /etc/bash_completion.d/sb
fi
