#
# Sample issue / ticketing app
#

BEGIN {
    info("adding routes for sample app")
    addRoute("GET", "/", "home")
    addRoute("POST", "/issue", "issue")
}

function home()
{
    sendFile("static/index.html")
}

function issue()
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
    setResponseBody("Thank you, " name ".\r\nThis issue has been filed.\r\nYour feedback is valuable.")
}

