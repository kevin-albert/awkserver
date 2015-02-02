#!/bin/bash

pid_file=$( grep PidDirectory <$( dirname $BASH_SOURCE )/settings.conf | 
            sed 's/PidDirectory[ \t]*//' | sed 's/\/$//' )/awkserver.pid

if [ -s $pid_file ]
then
    pid=$( cat $pid_file )
    echo "killing $pid"
    kill $pid
    rm $pid_file
else
    echo "nothing to stop ($pid_file not found)"
    exit -1
fi
