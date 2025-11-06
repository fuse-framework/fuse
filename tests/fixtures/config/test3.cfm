<cfscript>
variables.router.get("/", "Home.index", {name: "home"});
variables.router.resource("users");
variables.router.get("/posts/:id", "Posts.show");
</cfscript>