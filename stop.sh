#!/bin/bash

if [ -s awkserver.pid ]
then
    kill $( cat awkserver.pid )
    rm awkserver.pid
else
    echo "awkserver.pid not found"
    exit -1
fi
