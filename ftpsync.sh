#!/bin/bash
# script to copy files from ftp to local target dir and delete files afterwards
#
LOGFILE='' #logfile
SOURCEDIR=''
TARGETDIR='' #target directory
TEMPDIR=''
FTPSERVER='' #ftp server
FTPUSER='' #ftp user
FTPPASS='' #ftp password
FILEPATTERN='' #regex for filelist

function logging (){
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> ${LOGFILE}
}
function deleteftp (){
ftp -i -n ${FTPSERVER} <<FTPDEL_END
  user ${FTPUSER} ${FTPPASS}
  delete $1
FTPDEL_END
}

if [ ! -d ${TEMPDIR} ]; then
    mkdir ${TEMPDIR}
else
#    rm -rf ${TEMPDIR}/*
fi

if [ ! -d ${TARGETDIR} ]; then
  logging "target dir not available"
  exit
fi

cd ${TEMPDIR}

wget --quiet -r -nH --no-remove-listing --spider ftp://${FTPUSER}:${FTPPASS}@${FTPSERVER}/${SOURCEDIR}/
FILELIST=`find . -name '.listing' -type f -print0|xargs -0 grep ${FILEPATTERN}|sed -rs 's/(^\.\/)(.*)\.listing\:.*([[:digit:]]{2}\:[[:digit:]]{2}[[:space:]])(.*)\\r$/\2\4/'`

cd ${TARGETDIR}

for FILE in ${FILELIST}; do
  curl -s --create-dirs ftp://${FTPUSER}:${FTPPASS}@${FTPSERVER}/${FILE} -o ${TARGETDIR}/${FILE}.PART
  if [ $? -ne 0 ]; then
    logging "problem getting ${FTPSERVER}/${FILE}"
  else
    mv ${TARGETDIR}/${FILE}.PART ${TARGETDIR}/${FILE}
    deleteftp ${FILE}
  fi
done
exit 0
