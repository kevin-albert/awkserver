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
    name = getFormParam("name")
    email = getFormParam("email")
    complaint = getFormParam("complaint")
    info("handing complaint from " email ": \"" complaint "\"")
    print complaint > issueDept
    close(issueDept)
    setResponseBody("Thank you, " name ".\r\nThis issue has been filed.\r\nYour feedback is valuable.")
}
