#!/bin/bash

pidFile=$( grep pidDirectory <$( dirname $BASH_SOURCE )/settings.conf | 
            sed 's/pidDirectory[ \t]*//' | sed 's/\/$//' )/awkserver.pid

if [ -s $pidFile ]
then
    pid=$( cat $pidFile )
    echo "killing $pid"
    kill $pid
    rm $pidFile
else
    echo "nothing to stop ($pidFile not found)"
    exit -1
fi
