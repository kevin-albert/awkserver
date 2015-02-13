#!/bin/bash

isDaemon=true
isColored=true
settingsConf=$( dirname $BASH_SOURCE )/settings.conf

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
$isColored || args="$args -v _noLogColors=true"

# get pid location
if [ ! -s $settingsConf ]
then
    echo "settings file $settingsConf not found!" 
    exit -1
fi

args="$args $settingsConf"

pidDirectory=$( grep pidDirectory <$settingsConf | 
           sed 's/pidDirectory[ \t]*//' | sed 's/\/$//' )
if ! mkdir -p $pidDirectory
then
    echo "unable to create pid directory $pidDirectory"
    echo "either change it in settings.conf or run again as root"
    exit 1
else 
    echo "using pid directory $pidDirectory"
fi
pidFile=$pidDirectory/awkserver.pid


if ($isDaemon)
then
    gawk $args >awkserver.out 2>awkserver.err &
    sleep 1
    echo "server started. pid is $( cat $pidFile )"
else
    gawk $args
fi

