#!/bin/bash
# kill the locally running instance of awkserver

pidFile=awkserver.pid

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
