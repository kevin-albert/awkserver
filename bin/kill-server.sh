#!/bin/bash
# kill the locally running instance of awkserver

pidFile=$(dirname $BASH_SOURCE)/../awkserver.pid

if [ -s $pidFile ]
then
    pid=$( cat $pidFile )
    echo "attempting to kill server running with pid $pid"
    kill $pid
    rm $pidFile
else
    echo "nothing to stop ($pidFile not found)"
    exit -1
fi
