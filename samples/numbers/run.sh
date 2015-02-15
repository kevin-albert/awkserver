#!/bin/bash

cd $(dirname $BASH_SOURCE)/../../
gawk -f samples/numbers/numbers.awk

