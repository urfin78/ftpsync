#!/bin/bash
# script to copy files from ftp to local target dir and delete files afterwards

RUNFILE='' #pid
FTPBIN='' #ftp binary
LOGFILE='' #logfile
TARGETDIR='' #target directory
SOURCEDIR='' #source directory
TEMPDIR='' #tempdir
FTPSERVER='' #ftp server
FTPUSER='' #ftp user
FTPPASS='' #ftp password

function logging (){
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> ${LOGFILE}
}

function checkexit (){
	if [ $? -ne 0 ];then
		logging "error on $1"
		exit 1
	fi
}

function deleteftp (){
${FTPBIN} -i -n ${FTPSERVER} <<FTPDEL_END
  user ${FTPUSER} ${FTPPASS}
	delete "$1"
  quit
FTPDEL_END
}

if [ -f ${RUNFILE} ]; then
    logging "ftpsync seems to be running or is not exited cleanly"
    exit 1
else
    touch ${RUNFILE}
fi

if [ ! -d ${TEMPDIR} ]; then
	mkdir ${TEMPDIR}
	checkexit "creating tempdir"
fi

if [ ! -d ${TARGETDIR} ]; then
  checkexit "target dir not available"
fi

cd ${TEMPDIR}
checkexit "changing to temp dir"

wget --quiet -r -nH --cut-dirs=1 --no-remove-listing --spider ftp://${FTPSERVER}/${SOURCEDIR}/ --user=${FTPUSER} --password=${FTPPASS}
checkexit "getting filelisting"

FILELIST=`find . -name '.listing' -type f -print0|xargs -0 grep -e '\..*$'|grep -v 'part'|sed -rs 's/(^\.\/)(.*)\.listing\:.*([[:digit:]]{2}\:[[:digit:]]{2}[[:space:]]|[[:digit:]]{4}[[:space:]])(.*)\r$/\2\4/'`
cd ${TARGETDIR}
checkexit "changing to target dir"

if [ -z "${FILELIST}" ]; then
    rm ${RUNFILE}
    exit 0
fi
while read -r FILE; do
    curl -s --create-dirs "ftp://${FTPSERVER}/${SOURCEDIR}/${FILE}" -o "${TARGETDIR}/${FILE}.part"  --user "${FTPUSER}":"${FTPPASS}"
    if [ $? -ne 0 ]; then
        logging "problem getting ${FTPSERVER}/${SOURCEDIR}/${FILE}"
    else
        mv "${TARGETDIR}/${FILE}.part" "${TARGETDIR}/${FILE}"
    	if [ $? -ne 0 ]; then
	        logging "problem move ${TARGETDIR}/${FILE}.part ${TARGETDIR}/${FILE}"
		else
	        deleteftp "/${SOURCEDIR}/${FILE}"
		fi
	fi
# never forget double quotes!!!!
    done <<< "${FILELIST}"

rm ${RUNFILE}
exit 0
