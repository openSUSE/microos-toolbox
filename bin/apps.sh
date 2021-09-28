#!/bin/bash

#Create user applications directory if needed
[ ! -d ${HOME}/.local/share/applications ] && mkdir -p ${HOME}/.local/share/applications

#if it's marked as removed, delete desktop file. if it's a new rpm, search and replace.

declare -a REMOVED_RPMS
declare -a ADDED_RPMS

if [ -e ${HOME}/.config/toolbox/rpms-${HOSTNAME} ]; then
    REMOVED_RPMS=( $(diff --changed-group-format='%>' \
        --unchanged-group-format='' \
        - ${HOME}/.config/toolbox/rpms-${HOSTNAME} <<< `rpm -qa`) )
    ADDED_RPMS=( $(diff --changed-group-format='%<' \
        --unchanged-group-format='' \
        - ${HOME}/.config/toolbox/rpms-${HOSTNAME} <<< `rpm -qa`) )
else
    [ ! -d ${HOME}/.config/toolbox ] && mkdir -p ${HOME}/.config/toolbox
    ADDED_RPMS=( $(rpm -qa) )
fi
rpm -qa > ${HOME}/.config/toolbox/rpms-${HOSTNAME}

for ADDED_RPM in "${ADDED_RPMS[@]}"
do
    echo "ADDED RPM: ${ADDED_RPM}"
    RPM_FILES=( $(rpm -ql ${ADDED_RPM}) )
    for RPM_FILE in "${RPM_FILES[@]}"
    do
        if [[ "$RPM_FILE" =~ .*\.desktop$ ]]
        then
            APPLICATION_NAME=`basename ${RPM_FILE}`
            APPLICATION_NAME=`sed "s/.desktop$//" <<< ${APPLICATION_NAME}`
            APPLICATION_NAME="${APPLICATION_NAME}-on-${HOSTNAME}.desktop"

            sed "s/Exec=/Exec=toolbox -u -c ${HOSTNAME} /g" $RPM_FILE | sed '/^TryExec/d' | \
                sed "s/^Name=.*/& on ${HOSTNAME}/g" | \
                sed "s/^Icon=/Icon=${HOSTNAME}-${ADDED_RPM}-/g" \
                > ${HOME}/.local/share/applications/${APPLICATION_NAME}

            echo "#${ADDED_RPM}" >> ${HOME}/.local/share/applications/${APPLICATION_NAME}
            echo "ADDED DESKTOP FILE: ${HOME}/.local/share/applications/${APPLICATION_NAME}"
        elif [[ "$RPM_FILE" =~ ^.*\/icons\/.*\..*$ ]]
        then
            ICON_NAME=`basename ${RPM_FILE}`
            ICON_PATH=`dirname ${RPM_FILE}`
            LOCAL_ICON_PATH=`dirname ${RPM_FILE} | sed "s|^.*icons|${HOME}/.local/share/icons|"`
            LOCAL_ICON_NAME=${HOSTNAME}-${ADDED_RPM}-${ICON_NAME}
            [ ! -d $LOCAL_ICON_PATH ] && mkdir -p $LOCAL_ICON_PATH
            cp ${ICON_PATH}/${ICON_NAME} ${LOCAL_ICON_PATH}/${LOCAL_ICON_NAME}
        fi
    done
done

for REMOVED_RPM in "${REMOVED_RPMS[@]}"
do
    echo "REMOVED RPM: ${REMOVED_RPM}"
    APPLICATIONS=( $(grep -Ilr ${REMOVED_RPM} ${HOME}/.local/share/applications/) )
    for APPLICATION in "${APPLICATIONS[@]}"
    do
        echo "REMOVED DESKTOP FILE: ${APPLICATION}"
        rm $APPLICATION
    done
    find ${HOME}/.local/share/icons -iname "*${HOSTNAME}-${REMOVED_RPM}-*" -delete
done

exit 0
