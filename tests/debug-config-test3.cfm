<cfsetting showdebugoutput="false">
<cfscript>
	try {
		writeOutput("Creating router..." & chr(10));
		router = new fuse.core.Router();

		writeOutput("Adding route directly..." & chr(10));
		router.get("/test-route", "Test.index", {name: "test"});

		writeOutput("Testing direct add - Finding route..." & chr(10));
		matchResult = router.findRoute("/test-route", "GET");
		writeOutput("Match result matched: " & matchResult.matched & chr(10));

		if (matchResult.matched) {
			writeOutput("Direct route found!" & chr(10));
		}

		writeOutput(chr(10) & "---" & chr(10) & chr(10));

		// Now test via loadRoutes
		writeOutput("Creating new router and config..." & chr(10));
		config = new fuse.core.Config();
		router2 = new fuse.core.Router();

		writeOutput("Creating temp file..." & chr(10));
		tempPath = expandPath("/tests/fixtures/config/routes_basic.cfm");
		directoryCreate(expandPath("/tests/fixtures/config"), true, true);

		routesContent = 'variables.router.get("/test-route", "Test.index", {name: "test"});';
		fileWrite(tempPath, routesContent);
		writeOutput("Wrote to file: " & tempPath & chr(10));
		writeOutput("File content: " & routesContent & chr(10));

		writeOutput("Loading routes via config..." & chr(10));
		config.loadRoutes(router2, "/tests/fixtures/config");

		writeOutput("Testing loaded routes - Finding route..." & chr(10));
		matchResult2 = router2.findRoute("/test-route", "GET");
		writeOutput("Match result matched: " & matchResult2.matched & chr(10));

		if (matchResult2.matched) {
			writeOutput("Loaded route found!" & chr(10));
		} else {
			writeOutput("Loaded route NOT found" & chr(10));
		}

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
