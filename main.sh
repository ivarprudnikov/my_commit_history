#!/usr/bin/env bash

# tmp folder where repos will be cloned to
TMP_ROOT=/tmp/
OUR_TMP_FOLDER=git_history
LOGFILE=history.log

# author pattern
AUTHOR=ivar
# ISO timestamp
SINCE=2015-11-16T00:00:00.000Z
# git repo
REPOS=(
 git@github.com:lookinglocal/whitelisting-admin-webclient.git
 git@github.com:lookinglocal/whitelisting-daemon.git
 git@github.com:lookinglocal/kerp-webclient.git
 git@github.com:lookinglocal/kerp-grails.git
 git@github.com:lookinglocal/directory.my-coach-org.uk.git
 git@github.com:lookinglocal/myrenfrewshire.org.git
 git@github.com:lookinglocal/self-care-hub-grails.git
 git@github.com:lookinglocal/self-care-hub-webclient.git
 git@github.com:lookinglocal/lewishamlocaloffer.org.uk.git
 git@github.com:lookinglocal/kirkleeslocaloffer-2.git
)

cd ${TMP_ROOT}
rm -rf ${OUR_TMP_FOLDER}
mkdir ${OUR_TMP_FOLDER}
cd ${OUR_TMP_FOLDER}
touch ${LOGFILE}

position=1
for i in "${REPOS[@]}"
do
	git clone $i repo${position}
	cd repo${position}
	echo >> ../${LOGFILE}
	echo "-------------------------------------" >> ../${LOGFILE}
	echo "${i}\n\n" >> ../${LOGFILE}
	echo "-------------------------------------" >> ../${LOGFILE}
	echo >> ../${LOGFILE}
	echo >> ../${LOGFILE}
	git log --since=${SINCE} --author=${AUTHOR} --pretty=format:'%aD %ar, message: %s' >> ../${LOGFILE}
	$((position++)) > /dev/null 2>&1
	echo >> ../${LOGFILE}
	cd ..
done

cd ..