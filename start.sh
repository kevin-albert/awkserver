#!/bin/bash

isDaemon=true
isColored=true

function print_help() {
    echo "usage: $0 -Dmch"
    echo "-D  Do not run as Daemon (logs will print to stdout)"
    echo "-m  (monochrome) do not color log output"
    echo "-c  (colored) color log output (default)"
    echo "-h  (help) print this message"
}

while getopts ":Dmch" OPT
do
    case $OPT in
        D)
            isDaemon=false
            ;;
        m)
            isColored=false
            ;;
        c)
            isColored=true
            ;;
        h)
            print_help
            exit -2
            ;;
        *) 
            echo "unknown option: $OPTARG"
            print_help
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

