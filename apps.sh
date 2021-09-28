#!/bin/bash

#IFS=':' read -r -a BASE_DIRS <<< "$XDG_DATA_DIRS"
#if it's marked as removed, delete desktop file. if it's a new rpm, search and replace. yeet
if [ -e .config/zypp-hist-${HOSTNAME} ]; then

else

fi

RPMS_INSTALLED=( $(sudo cat /var/log/zypp/history | \
    cut -f 2,3 -d \| | grep "^install" | sed "s/install|//") )

[ ! -d ${HOME}/.local/share/applications ] && mkdir -p ${HOME}/.local/share/applications

#remove old files
find ${HOME}/.local/share/applications/ -name *${HOSTNAME}.desktop -delete
find ${HOME}/.local/share/icons/ -name *${HOSTNAME}* -delete

xdg-desktop-menu uninstall --noupdate \
    --mode user ${HOME}/.local/share/applications/*${HOSTNAME}.desktop


#Add rpm name to desktop file.
for RPM_INSTALLED in "${RPMS_INSTALLED[@]}"
do
    APPLICATIONS=( $(rpm -ql ${RPM_INSTALLED}) )
    for APPLICATION in "${APPLICATIONS[@]}"
    do
        if [[ "$APPLICATION" =~ .*.desktop$ ]]
        then
            LICATION_NAME=`basename ${APPLICATION}`
            LICATION_NAME=`sed "s/.desktop$//" <<< ${LICATION_NAME}`
            LICATION_NAME="${LICATION_NAME}-on-${HOSTNAME}.desktop"
            sed "s/Exec=/Exec=toolbox -u -c ${HOSTNAME} /g" $APPLICATION | sed '/^TryExec/d' | \
                sed "s/^Name=.*/& on ${HOSTNAME}/g" | \
                sed "s/^Icon=/Icon=${HOSTNAME}-/g" > ${HOME}/.local/share/applications/${LICATION_NAME}
        elif [[ "$APPLICATION" =~ ^.*\/icons\/.*\..*$ ]]
        then
            ICON_NAME=`basename ${APPLICATION}`
            ICON_PATH=`dirname ${APPLICATION}`
            LOCAL_ICON_PATH=`dirname ${APPLICATION} | sed "s|^.*icons|${HOME}/.local/share/icons|"`
            LOCAL_ICON_NAME=${HOSTNAME}-${ICON_NAME}

            [ ! -d $LOCAL_ICON_PATH ] && mkdir -p $LOCAL_ICON_PATH

            cp ${ICON_PATH}/${ICON_NAME} ${LOCAL_ICON_PATH}/${LOCAL_ICON_NAME}
        fi

    done
done

xdg-desktop-menu install --mode user ${HOME}/.local/share/applications/*.desktop

exit 0
