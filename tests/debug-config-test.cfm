<cfsetting showdebugoutput="false">
<cfscript>
	try {
		// Test 1: Load routes.cfm and pass router to scope
		writeOutput("Test 1: Load routes.cfm and pass router to scope" & chr(10));
		config = new fuse.core.Config();
		router = new fuse.core.Router();

		tempPath = expandPath("/tests/fixtures/config/routes_basic.cfm");
		directoryCreate(expandPath("/tests/fixtures/config"), true, true);

		fileWrite(tempPath, '
			variables.router.get("/test-route", "Test.index", {name: "test"});
		');

		config.loadRoutes(router, "/tests/fixtures/config");

		namedRoute = router.getNamedRoute("test");
		if (!structKeyExists(variables, "namedRoute") || isNull(namedRoute)) {
			writeOutput("FAIL: Named route 'test' not found" & chr(10));
		} else {
			writeOutput("PASS: Named route found" & chr(10));
			writeOutput("  Pattern: " & namedRoute.pattern & chr(10));
			writeOutput("  Handler: " & namedRoute.handler & chr(10));
		}

		// Cleanup
		if (fileExists(tempPath)) {
			fileDelete(tempPath);
		}

	} catch (any e) {
		writeOutput("ERROR in Test 1: " & e.message & chr(10));
		writeOutput("  Detail: " & e.detail & chr(10));
		writeOutput("  Type: " & e.type & chr(10));
		if (structKeyExists(e, "tagContext") && arrayLen(e.tagContext)) {
			writeOutput("  Line: " & e.tagContext[1].line & chr(10));
		}
	}

	writeOutput(chr(10) & "---" & chr(10) & chr(10));

	try {
		// Test 2: Handle missing routes.cfm gracefully
		writeOutput("Test 2: Handle missing routes.cfm gracefully" & chr(10));
		config2 = new fuse.core.Config();
		router2 = new fuse.core.Router();

		config2.loadRoutes(router2, "/nonexistent/path");
		writeOutput("PASS: No error thrown for missing routes.cfm" & chr(10));

	} catch (any e) {
		writeOutput("FAIL: Error thrown for missing routes.cfm" & chr(10));
		writeOutput("  " & e.message & chr(10));
	}
</cfscript>
