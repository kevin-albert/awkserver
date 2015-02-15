#!/bin/bash

cd $(dirname $BASH_SOURCE)/../../
gawk -f samples/issue-tracker/tracker.awk

