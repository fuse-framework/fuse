component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Configuration routes loading", function() {

			beforeEach(function() {
				variables.config = new fuse.core.Config();
				variables.router = new fuse.core.Router();
			});

			it("should load routes.cfm and pass router to scope", function() {
				// Create temp routes.cfm file
				var tempPath = expandPath("/tests/fixtures/config/routes_basic.cfm");
				directoryCreate(expandPath("/tests/fixtures/config"), true, true);

				fileWrite(tempPath, '<cfscript>
variables.router.get("/test-route", "Test.index", {name: "test"});
</cfscript>');

				try {
					config.loadRoutes(router, "/tests/fixtures/config");

					// Verify route was registered via router
					var namedRoute = router.getNamedRoute("test");
					expect(namedRoute).notToBeNull();
					expect(namedRoute.pattern).toBe("/test-route");
					expect(namedRoute.handler).toBe("Test.index");
				} finally {
					// Cleanup
					if (fileExists(tempPath)) {
						fileDelete(tempPath);
					}
				}
			});

			it("should register multiple route types from routes.cfm", function() {
				// Create temp routes.cfm with various route types
				var tempPath = expandPath("/tests/fixtures/config/routes_multiple.cfm");
				directoryCreate(expandPath("/tests/fixtures/config"), true, true);

				fileWrite(tempPath, '<cfscript>
// Static route
variables.router.get("/", "Home.index", {name: "home"});

// Named route
variables.router.get("/about", "Pages.about", {name: "about_page"});

// Resource routes
variables.router.resource("users");

// Param route
variables.router.get("/posts/:id/comments/:comment_id", "Comments.show");
</cfscript>');

				try {
					config.loadRoutes(router, "/tests/fixtures/config/routes_multiple.cfm");

					// Verify static route
					var homeRoute = router.getNamedRoute("home");
					expect(homeRoute).notToBeNull();

					// Verify named route
					var aboutRoute = router.getNamedRoute("about_page");
					expect(aboutRoute).notToBeNull();

					// Verify resource routes
					var usersIndexRoute = router.getNamedRoute("users_index");
					expect(usersIndexRoute).notToBeNull();
					var usersShowRoute = router.getNamedRoute("users_show");
					expect(usersShowRoute).notToBeNull();

					// Verify param route can be found
					var matchResult = router.findRoute("/posts/123/comments/456", "GET");
					expect(matchResult.matched).toBeTrue();
					expect(matchResult.params.id).toBe("123");
					expect(matchResult.params.comment_id).toBe("456");
				} finally {
					// Cleanup
					if (fileExists(tempPath)) {
						fileDelete(tempPath);
					}
				}
			});

			it("should handle missing routes.cfm gracefully", function() {
				// Should not throw error if routes.cfm doesn't exist
				expect(function() {
					config.loadRoutes(router, "/nonexistent/path");
				}).notToThrow();
			});

			xit("should throw descriptive error for invalid routes.cfm syntax", function() {
				// SKIPPED: Lucee parser has issues with string literals containing quotes
				// This test would verify that invalid CFML syntax in routes.cfm
				// throws a RouteConfigurationException with descriptive error message
			});

			it("should load routes during bootstrap integration", function() {
				// This tests the integration point
				var bootstrap = new fuse.core.Bootstrap();
				var testAppScope = {};
				var framework = bootstrap.initFramework(testAppScope, "fuse", 30);
				var container = framework.getContainer();
				var testRouter = container.resolve("router");

				// Create temp routes.cfm
				var tempPath = expandPath("/config/routes.cfm");
				directoryCreate(expandPath("/config"), true, true);

				fileWrite(tempPath, '<cfscript>
variables.router.get("/bootstrap-test", "Test.bootstrap", {name: "bootstrap_route"});
</cfscript>');

				try {
					// Load routes through config
					var configLoader = new fuse.core.Config();
					configLoader.loadRoutes(testRouter);

					// Verify route was loaded
					var bootstrapRoute = testRouter.getNamedRoute("bootstrap_route");
					expect(bootstrapRoute).notToBeNull();
				} finally {
					// Cleanup
					if (fileExists(tempPath)) {
						fileDelete(tempPath);
					}
					if (directoryExists(expandPath("/config"))) {
						directoryDelete(expandPath("/config"));
					}
				}
			});

		});
	}

}
