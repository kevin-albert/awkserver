#
# Sample ticketing / management system
# usage: cd ../../ && gawk -f samples/issue-tracker/tracker.awk
#

@include "src/awkserver.awk"


function home()
{
    sendFile("samples/issue-tracker/static/index.html")
}


function handleComplaint()
{
    issueDept = "/dev/null"
    parseForm(getRequestBody(), issueForm)
    name = issueForm["name"]
    email = issueForm["email"]
    complaint = issueForm["complaint"]
    info("handing complaint from " email ": \"" complaint "\"")
    print complaint > issueDept
    close(issueDept)
    delete issueForm
    setResponseBody("<html><head><title>TICKET CREATED</title>" \
                    "<link rel='stylesheet' type='text/css' href='/style.css' /></head>" \
                    "<body><p>Thank you, " name ". This issue has been filed.</p>"\
                    "<p>Your feedback is valuable.</p>"\
                    "</body></html>")
}


BEGIN {
    info("adding routes for sample app")
    addRoute("GET", "/", "home")
    addRoute("POST", "/complain", "handleComplaint")
    setStaticDirectory("samples/issue-tracker/static")
    startAwkServer("3001")
}
