<cfsetting showdebugoutput="false">
<cfscript>
	passed = 0;
	failed = 0;

	function test(name, fn) {
		try {
			fn();
			passed++;
			writeOutput("[PASS] " & name & chr(10));
		} catch (any e) {
			failed++;
			writeOutput("[FAIL] " & name & chr(10));
			writeOutput("  Error: " & e.message & chr(10));
			if (structKeyExists(e, "detail") && len(e.detail)) {
				writeOutput("  Detail: " & e.detail & chr(10));
			}
		}
	}

	writeOutput("=== Config Routes Loading Verification ===" & chr(10) & chr(10));

	// Test 1: Load routes from file
	test("Load routes.cfm and register routes", function() {
		var config = new fuse.core.Config();
		var router = new fuse.core.Router();
		var tempPath = expandPath("/tests/fixtures/config/test1.cfm");

		directoryCreate(expandPath("/tests/fixtures/config"), true, true);
		fileWrite(tempPath, '<cfscript>
variables.router.get("/test-route", "Test.index", {name: "test"});
</cfscript>');

		config.loadRoutes(router, tempPath);

		// Verify route was added
		var matchResult = router.findRoute("/test-route", "GET");
		if (!matchResult.matched) {
			throw(message="Route not found");
		}

		// Cleanup
		fileDelete(tempPath);
	});

	// Test 2: Handle missing file gracefully
	test("Handle missing routes.cfm gracefully", function() {
		var config = new fuse.core.Config();
		var router = new fuse.core.Router();

		// Should not throw
		config.loadRoutes(router, "/nonexistent/path/routes.cfm");
	});

	// Test 3: Load multiple route types
	test("Register multiple route types", function() {
		var config = new fuse.core.Config();
		var router = new fuse.core.Router();
		var tempPath = expandPath("/tests/fixtures/config/test3.cfm");

		directoryCreate(expandPath("/tests/fixtures/config"), true, true);
		fileWrite(tempPath, '<cfscript>
variables.router.get("/", "Home.index", {name: "home"});
variables.router.resource("users");
variables.router.get("/posts/:id", "Posts.show");
</cfscript>');

		config.loadRoutes(router, tempPath);

		// Verify routes
		var homeMatch = router.findRoute("/", "GET");
		if (!homeMatch.matched) throw(message="Home route not found");

		var usersMatch = router.findRoute("/users", "GET");
		if (!usersMatch.matched) throw(message="Users index route not found");

		var postMatch = router.findRoute("/posts/123", "GET");
		if (!postMatch.matched) throw(message="Post show route not found");

		// Cleanup
		fileDelete(tempPath);
	});

	// Test 4: Bootstrap integration
	test("Load routes during bootstrap", function() {
		var bootstrap = new fuse.core.Bootstrap();
		var testAppScope = {};
		var framework = bootstrap.initFramework(testAppScope, "fuse_test", 30);
		var container = framework.getContainer();
		var testRouter = container.resolve("router");

		// Create temp routes.cfm
		var tempPath = expandPath("/config/routes.cfm");
		directoryCreate(expandPath("/config"), true, true);
		fileWrite(tempPath, '<cfscript>
variables.router.get("/bootstrap-test", "Test.bootstrap", {name: "bootstrap_route"});
</cfscript>');

		// Load routes through config
		var configLoader = new fuse.core.Config();
		configLoader.loadRoutes(testRouter);

		// Verify route
		var matchResult = testRouter.findRoute("/bootstrap-test", "GET");
		if (!matchResult.matched) throw(message="Bootstrap route not found");

		// Cleanup
		fileDelete(tempPath);
		directoryDelete(expandPath("/config"));
	});

	// Test 5: Error handling for invalid syntax
	test("Throw error for invalid routes.cfm syntax", function() {
		var config = new fuse.core.Config();
		var router = new fuse.core.Router();
		var tempPath = expandPath("/tests/fixtures/config/test5.cfm");

		directoryCreate(expandPath("/tests/fixtures/config"), true, true);
		fileWrite(tempPath, '<cfscript>
variables.router.get("/test", "Test.index");
thisWillCauseError;
</cfscript>');

		try {
			config.loadRoutes(router, tempPath);
			throw(message="Expected error was not thrown");
		} catch (RouteConfigurationException e) {
			// Expected
		}

		// Cleanup
		fileDelete(tempPath);
	});

	writeOutput(chr(10) & "=== Summary ===" & chr(10));
	writeOutput("Passed: " & passed & chr(10));
	writeOutput("Failed: " & failed & chr(10));
	writeOutput(chr(10));

	if (failed > 0) {
		writeOutput("TESTS FAILED" & chr(10));
	} else {
		writeOutput("ALL TESTS PASSED" & chr(10));
	}
</cfscript>
