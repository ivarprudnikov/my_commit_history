#!/bin/bash

set -o errexit

GITHUB_ORG=${1:?first argument organisation required}
GITHUB_ACCESS_TOKEN=${2:?second argument github token required}

# tmp folder where repos will be cloned to
TMP=tmp/git_history
# output of this script
LOGFILE=history.log
# author pattern
AUTHOR=ivar
# ISO timestamp
SINCE=2018-08-01T00:00:00.000Z

loop=0
index=1
PER_PAGE=100

# git repositories to read commits from
# eg: git@github.com:foo/bar.git
REPOS_ARRAY=()

rm -rf ${TMP}
mkdir -p ${TMP}
cd ${TMP}
touch ${LOGFILE}

while [ "$loop" -ne 1 ]
do
    data=$(curl -s "https://api.github.com/orgs/$GITHUB_ORG/repos?access_token=$GITHUB_ACCESS_TOKEN&page=$index&per_page=$PER_PAGE")
    check_error=`echo "$data"  | jq 'type!="array"'`
    if [ "$check_error" == "true" ]; then
        echo "access token is invalid"
        exit 1
    fi

    repos_in_page=$(echo "${data}" | jq -r '.[].ssh_url')
    size=$(wc -l <<< "${repos_in_page}")
    if [[ $((size)) > 1 ]]; then
        for line in $repos_in_page; do
            echo "Addign repository URL $line"
            REPOS_ARRAY+=("$line")
        done
        echo "$index page - fetched $size repositories"
        index=$((index+1))
    else
        loop=1
    fi
done

# iterate over each repository in array
position=1
for REPO in "${REPOS_ARRAY[@]}"
do
	PROJECT_NAME=$(basename "${REPO}")
	FOLDER_NAME="repo${position}-${PROJECT_NAME}"
	# clone repository contents for a given time period
	git clone --shallow-since=${SINCE} $REPO $FOLDER_NAME
	cd $FOLDER_NAME
	# store all single line commits in a variable
	COMMITS=$(git log --since=${SINCE} --author=${AUTHOR} --pretty=format:'%aD %ar, message: %s' 2>&1)
	# count commits. be aware that it will return 1 for empty string
	LINE_COUNT=$(wc -l <<< "${COMMITS}")
	# need to set IFS to split variable by new line instead of white space
	# otherwise will not retrieve correct amount of commit messages
	IFS_BAK=$IFS
	IFS=$'\n'
	# print output only if there were any commits for a given period
	# $(()) is necessary to convert string to integer
	if [[ $((LINE_COUNT)) > 1 ]]; then
		echo "---------------------------------------------------------------" >> ../${LOGFILE}
		echo "${REPO}" >> ../${LOGFILE}
		echo "---------------------------------------------------------------" >> ../${LOGFILE}
		# print commit messages
		for line in $COMMITS; do
 			echo "${line}" >> ../${LOGFILE}
		done
		echo >> ../${LOGFILE}
	fi
	# reset IFS
	IFS=$IFS_BAK
	IFS_BAK=
	
	# bump up position
	$((position++)) > /dev/null 2>&1
	cd ..
done

cd ..