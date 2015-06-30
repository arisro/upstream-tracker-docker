#!/bin/bash

HOSTS_FILE="/etc/hosts"

BACKUP_FILENAME="hosts.$(date +%s)"
echo "Creating file backup in /tmp/hosts/$BACKUP_FILENAME."
mkdir -p /tmp/hosts && cp /etc/hosts /tmp/hosts/"$BACKUP_FILENAME"

for cid in $(docker ps | grep -v STATUS | awk '{print $1}'); do
    IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${cid})
    ENVVARS=$(docker inspect --format '{{ .Config.Env }}' ${cid})
    if [[ $ENVVARS =~ .*HOSTNAMES.* ]]; then
        HOSTNAMES=$(echo $ENVVARS | grep -Po "HOSTNAMES=([a-zA-Z0-9\-\.,]+)")
        HOSTNAMES=${HOSTNAMES/HOSTNAMES=/}

        WFNAME=$(echo $ENVVARS | grep -Po "WFNAME=([a-zA-Z0-9\-\.]+)")
        WFNAME=${WFNAME/WFNAME=/}

        IMAGE_ID=$(docker inspect --format '{{ .Image }}' ${cid})

        # check if image hosts are already present
        HOSTS_ENTRY="### docker-start: $WFNAME\n$IP\t${HOSTNAMES/,/ }\n### docker-end"

        if grep -q ": $WFNAME" "$HOSTS_FILE"; then
            echo "- Updating hosts entry for $HOSTNAMES"
            sed -i ':a;N;$!ba;s/### docker-start: '"$WFNAME"'\n[^#]*### docker-end/'"$HOSTS_ENTRY"'/g' $HOSTS_FILE
        else
            echo "- Adding hosts entry for $HOSTNAMES"
            printf "\n$HOSTS_ENTRY\n" >> $HOSTS_FILE
        fi
    fi
done
