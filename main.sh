#!/bin/bash

GITHUB_ORG=${1:?first argument - github organisation - is required}
GITHUB_ACCESS_TOKEN=${2:?second argument - github token - is required}

# tmp folder where repos will be cloned to
TMP=tmp/git_history
# output of this script
LOGFILE=history.log
# author pattern
AUTHOR=${3:?third argument - author pattern to pass into git log is required, ie usernam}
# ISO timestamp
SINCE=${4:?fourth argument - date since (inclusive) - is required, ISO timestamp ie 2018-12-12}
# ISO timestamp
UNTIL=${5:-(date -v+1d "+%Y-%m-%d")}

loop=0
index=1
PER_PAGE=100

# git repositories to read commits from
# eg: git@github.com:foo/bar.git
REPOS_ARRAY=()

rm -rf ${TMP}
rm -f tmp/${LOGFILE}
mkdir -p ${TMP}
cd ${TMP}

while [ "${loop}" -ne 1 ]
do
	api_uri="https://api.github.com/orgs/${GITHUB_ORG}/repos?access_token=${GITHUB_ACCESS_TOKEN}&page=${index}&per_page=$PER_PAGE"
    api_response=$(curl -s "${api_uri}")
    check_error=`echo "${api_response}"  | jq 'type!="array"'`
    if [ "${check_error}" == "true" ]; then
        echo "access token is invalid"
        exit 1
    fi

    # extract timestamp and put each on new line
	repos_timestamp=$(echo "${api_response}" | jq -r '.[].pushed_at')
	# extract repo and put each on new line
	repos_url=$(echo "${api_response}" | jq -r '.[].clone_url')
	# count extracted lines
	size=$(wc -l <<< "${repos_timestamp}")

	# iterate over each line
	for N in $(seq 1 $size); do
		# extract timestamp having line index
		t=$(echo "${repos_timestamp}" | sed -n "${N}"p)
		# check if timestamp is newer than argument SINCE
		if [[ "${t}" > "${SINCE}" ]] && [[ "${t}" < "${UNTIL}" ]]; then
			# select repos that match SINCE argument
			repo_url=$(echo "${repos_url}" | sed -n "${N}"p)
			# add token to url
			https_prefix="https://"
			https_token_prefix="${https_prefix}${GITHUB_ACCESS_TOKEN}@"
			repo_url=${repo_url/$https_prefix/$https_token_prefix}
			REPOS_ARRAY+=("${repo_url}")
		fi
	done

	# if only one line then response is most likely empty
    if [[ $((size)) > 1 ]]; then
        echo "${index} page - fetched ${size} repositories of which ${#REPOS_ARRAY[@]} had been pushed to since ${SINCE}"
        index=$((index+1))
    else
    	echo "${index} page response is empty ${api_response}"
        loop=1
    fi
done

# iterate over each repository in array
for REPO_IDX in ${!REPOS_ARRAY[@]};
do
	REPO=${REPOS_ARRAY[$REPO_IDX]}
	PROJECT_NAME=$(basename "${REPO}")
	FOLDER_NAME="repo${REPO_IDX}-${PROJECT_NAME}"
	# clone repository contents for a given time period
	echo "Cloning ${PROJECT_NAME}"
	git clone --no-single-branch --shallow-since=${SINCE} $REPO $FOLDER_NAME

	# store all single line commits in a variable
	COMMITS=$(git --git-dir=${FOLDER_NAME}/.git log --all --since=${SINCE} --until=${UNTIL} --author=${AUTHOR} --pretty=format:'%aD %ar, branch: %d message: %s' 2>&1)
	# count commits. be aware that it will return 1 for empty string
	LINE_COUNT=$(wc -l <<< "${COMMITS}")
	# need to set IFS to split variable by new line instead of white space
	# otherwise will not retrieve correct amount of commit messages
	IFS_BAK=$IFS
	IFS=$'\n'
	# print output only if there were any commits for a given period
	# $(()) is necessary to convert string to integer
	if [[ $((LINE_COUNT)) > 1 ]]; then
		echo "Found commits ${LINE_COUNT}"
		echo "---------------------------------------------------------------" >> ../${LOGFILE}
		echo "${REPO}" >> ../${LOGFILE}
		echo "---------------------------------------------------------------" >> ../${LOGFILE}
	 	# print commit messages
		for line in $COMMITS; do
 			echo "${line}" >> ../${LOGFILE}
		done
		echo >> ../${LOGFILE}
	else
		echo "No commits"
	fi
	# # reset IFS
	IFS=$IFS_BAK
	IFS_BAK=

done

cd ..

echo "Now '$ cat tmp/history.log'"
