<cfsetting showdebugoutput="false">
<cfscript>
	try {
		writeOutput("Creating router..." & chr(10));
		router = new fuse.core.Router();

		writeOutput("Creating temp file..." & chr(10));
		tempPath = expandPath("/tests/fixtures/config/routes_test.cfm");
		directoryCreate(expandPath("/tests/fixtures/config"), true, true);

		routesContent = '<cfscript>
writeOutput("In routes.cfm, router exists: " & structKeyExists(variables, "router") & chr(10));
if (structKeyExists(variables, "router")) {
	writeOutput("Adding route in routes.cfm..." & chr(10));
	variables.router.get("/test-route", "Test.index", {name: "test"});
	writeOutput("Route added in routes.cfm" & chr(10));
}
</cfscript>';

		fileWrite(tempPath, routesContent);

		writeOutput("Including file with router in variables..." & chr(10));
		variables.router = router;
		include template="/tests/fixtures/config/routes_test.cfm";

		writeOutput("After include, finding route..." & chr(10));
		matchResult = router.findRoute("/test-route", "GET");
		writeOutput("Match result matched: " & matchResult.matched & chr(10));

		// Cleanup
		if (fileExists(tempPath)) {
			fileDelete(tempPath);
		}

	} catch (any e) {
		writeOutput("ERROR: " & e.message & chr(10));
		writeOutput("  Detail: " & e.detail & chr(10));
		writeOutput("  Type: " & e.type & chr(10));
		if (structKeyExists(e, "tagContext") && arrayLen(e.tagContext)) {
			writeOutput("  File: " & e.tagContext[1].template & chr(10));
			writeOutput("  Line: " & e.tagContext[1].line & chr(10));
		}
	}
</cfscript>
