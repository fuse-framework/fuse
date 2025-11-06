<cfsetting showdebugoutput="false">
<cfscript>
	try {
		writeOutput("Creating router and config..." & chr(10));
		config = new fuse.core.Config();
		router = new fuse.core.Router();

		writeOutput("Creating temp file..." & chr(10));
		tempPath = expandPath("/tests/fixtures/config/routes_basic.cfm");
		directoryCreate(expandPath("/tests/fixtures/config"), true, true);

		fileWrite(tempPath, '
			variables.router.get("/test-route", "Test.index", {name: "test"});
		');

		writeOutput("Loading routes..." & chr(10));
		config.loadRoutes(router, "/tests/fixtures/config");

		writeOutput("Finding route..." & chr(10));
		matchResult = router.findRoute("/test-route", "GET");
		writeOutput("Match result matched: " & matchResult.matched & chr(10));

		if (matchResult.matched) {
			writeOutput("Route found!" & chr(10));
			writeOutput("  Handler: " & matchResult.route.handler & chr(10));
			if (structKeyExists(matchResult.route, "name")) {
				writeOutput("  Name: " & matchResult.route.name & chr(10));
			}
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
