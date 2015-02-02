#!/bin/bash

isDaemon=true
isColored=true
arg=0

while (( ++arg <= $# ))
do
    case ${!arg} in
        --help)
            echo "usage: $BASH_SOURCE -Dm --help"
            echo "-D: Do not start daemon process; run inline"
            echo "-m: Monochrome - do not color log output"
            exit -1
            ;;
        -D)
            isDaemon=false
            ;;
        -m)
            isColored=false
            ;;
        -Dm|-mD)
            isDaemon=false
            isColored=false
            ;;
        *) 
            echo "usage: $BASH_SOURCE -Dm --help"
            exit -1
            ;;
    esac
done

# cd to the current directory so that awk include paths work
cd $( dirname $BASH_SOURCE )

args="-f src/main.awk "
$isColored || args="$args -v noLogColors=true"
args="$args settings.conf"

# get pid location
[ ! -s settings.conf ] && echo "settings.conf not found!" && exit -1

if ($isDaemon)
then
    pid_dir=$( grep PidDirectory <$( dirname $BASH_SOURCE )/settings.conf | 
               sed 's/PidDirectory[ \t]*//' | sed 's/\/$//' )
    mkdir -p $pid_dir
    pid_file=$pid_dir/awkserver.pid

    gawk $args >awkserver.out 2>awkserver.err &
    sleep 1
    echo "server started. pid is $( cat $pid_file )"
else
    gawk $args
fi

