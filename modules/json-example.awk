#
# Example of parsing a JSON file
# to run:
# gawk -f json-example.awk
#

@include "json-parser.awk"

BEGIN {
    
    json = "{\n\
    \"dests\": [\"AUDIT\",\"DEFAULT\"],\n\
    \"host\": \"fooserver0x.onezork.frobozz\",\n\
    \"level\": \"INFO\",\n\
    \"date\": \"2015-02-11 00:12:35\",\n\
    \"ver\": \"1.1\",\n\
    \"msg\": {\n\
        \"bolt_consumer\": \"hotlog_v1\",\n\
        \"raw_change_data\": null,\n\
        \"account_ids\": [\"3505330\", \"825e3778-9b81-4727-967c-df541a11e0aa\"],\n\
        \"action\": [\"updateAccount\", \"updateRelation\"],\n\
        \"requestid\": \"0144f79d-b1b4-4f9e-a771-63199466f87f\",\n\
        \"success\":true,\n\
        \"tstamp_usec\": 1423613555714003\n\
    }\n\
}"
    print "Parsing transaction from: " json
    error = parseJson(json, tx, keys)
    if (error) {
        print error
        print "Unable to parse JSON"
    } else {
        print ""
        print "================================================================================"
        print "ID:                  " tx["msg.requestid"]
        print "Host:                " tx["host"]
        print "Date:                " tx["date"]

        i = 0
        print "Actions:"
        while (action = tx["msg.action[" i++ "]"]) { print "                     " action }

        i = 0
        print "Affected Accounts:"
        while (acct = tx["msg.account_ids[" i++ "]"]) { print "                     " acct }

        print "Transaction " (tx["msg.success"] == "true" ? "succeeded" : "failed")

        print "================================================================================"
        print ""
    }
}
