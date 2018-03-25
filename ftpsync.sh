#!/bin/bash
# script to copy files from ftp to local target dir and delete files afterwards
#
LOGFILE='' #logfile
SOURCEDIR='' #source directory
TARGETDIR='' #target directory
FTPSERVER='' #ftp server
FTPUSER='' #ftp user
FTPPASS='' #ftp password
FILEPATTERN='' #regex for filelist
FILELIST=`curl -s -l ftp://${FTPSERVER}/${SOURCEDIR}/ --user ${FTPUSER}:${FTPPASS}|grep -e ${FILEPATTERN}`

function logging (){
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> ${LOGFILE}
}

if [ ! -d ${TARGETDIR} ]; then
  logging "target dir not available"
  exit
fi

cd ${TARGETDIR}
for FILE in ${FILELIST}; do
    wget -q -N "ftp://${FTPUSER}:${FTPPASS}@${FTPSERVER}/${SOURCEDIR}/${FILE}"
    if [ $? -ne 0 ]; then
      logging "problem getting ${FILE}"
    else
      ftp -i -n ${FTPSERVER} <<FTPDEL_END
        user ${FTPUSER} ${FTPPASS}
        delete ${FILE}
FTPDEL_END
    fi
done
exit 0
