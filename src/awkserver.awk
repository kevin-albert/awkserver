#
# main.awk
# includes the server program and its dependencies
#
# @include this from your app file 
# needs GNU awk to run
# use at your own risk
#

@include "src/log.awk"
@include "src/config.awk"
@include "src/core.awk"
@include "src/http.awk"
@include "src/routes.awk"
@include "modules/modules.awk"

BEGIN { _initLogs() }
