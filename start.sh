#!/bin/bash

cd $( dirname $BASH_SOURCE )
gawk -f server.awk settings.conf

