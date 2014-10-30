#!/bin/bash

cd $( dirname $BASH_SOURCE )
gawk -f server.awk settings.conf

# to disable colored logs, do
#gawk -f server.awk -v noLogColors=true settings.conf

