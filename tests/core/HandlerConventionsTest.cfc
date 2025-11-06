component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Handler conventions and lifecycle", function() {

			beforeEach(function() {
				// Setup container with required services
				container = new fuse.core.Container();

				// Register router singleton
				container.singleton("router", function(c) {
					return new fuse.core.Router();
				});

				// Register eventService singleton
				container.singleton("eventService", function(c) {
					return new fuse.core.EventService();
				});

				// Setup test routes
				router = container.resolve("router");
				router.get("/users", "Users.index", {name: "users_index"});
				router.get("/users/:id", "Users.show", {name: "users_show"});
				router.post("/users", "Users.create", {name: "users_create"});
				router.get("/pages/about", "Pages.about", {name: "about_page"});

				// Register transient dispatcher binding
				container.bind("dispatcher", function(c) {
					return new fuse.core.Dispatcher(
						c.resolve("router"),
						c,
						c.resolve("eventService")
					);
				});
			});

			it("should load handler from transient binding", function() {
				var dispatcher = container.resolve("dispatcher");

				// Register handler as transient binding
				container.bind("Users", function(c) {
					return new tests.fixtures.handlers.Users();
				});

				var result = dispatcher.dispatch("/users", "GET");

				expect(result).toBeStruct();
				expect(result.success).toBeTrue();
				expect(result.action).toBe("index");
			});

			it("should create new handler instance per request (transient)", function() {
				var dispatcher = container.resolve("dispatcher");
				var instanceCount = 0;

				// Register handler as transient that tracks instantiation
				container.bind("Users", function(c) {
					instanceCount++;
					var handler = new tests.fixtures.handlers.Users();
					return handler;
				});

				var result1 = dispatcher.dispatch("/users", "GET");
				var result2 = dispatcher.dispatch("/users", "GET");

				// Should have instantiated twice
				expect(instanceCount).toBe(2);
				// Each result should have different instance IDs (set by handler init)
				expect(result1.instanceId).notToBe("");
				expect(result2.instanceId).notToBe("");
				expect(result1.instanceId).notToBe(result2.instanceId);
			});

			it("should auto-wire dependencies via constructor", function() {
				var dispatcher = container.resolve("dispatcher");

				// Register dependency in container
				container.singleton("logger", function(c) {
					return new tests.fixtures.Logger();
				});

				// Register handler with constructor dependency
				container.bind("Users", function(c) {
					return new tests.fixtures.handlers.Users(
						c.resolve("logger")
					);
				});

				var result = dispatcher.dispatch("/users", "GET");

				// Handler should have received logger dependency
				expect(result).toBeStruct();
				expect(result.success).toBeTrue();
				expect(result.hasLogger).toBeTrue();
			});

			it("should pass route params as method arguments to handler action", function() {
				var dispatcher = container.resolve("dispatcher");

				// Register handler
				container.bind("Users", function(c) {
					return new tests.fixtures.handlers.Users();
				});

				var result = dispatcher.dispatch("/users/42", "GET");

				// Handler action should have received id param
				expect(result).toBeStruct();
				expect(result.success).toBeTrue();
				expect(result.action).toBe("show");
				expect(result.id).toBe("42");
			});

			it("should provide urlFor helper access to handlers", function() {
				var dispatcher = container.resolve("dispatcher");
				var eventService = container.resolve("eventService");
				var routerRef = router;

				// Inject urlFor into handler via interceptor
				eventService.registerInterceptor("onBeforeHandler", function(event) {
					// Make urlFor available to handler via property injection
					event.handler.urlFor = function(name, params = {}) {
						return routerRef.urlFor(name, params);
					};
				});

				// Register handler that uses urlFor
				container.bind("Pages", function(c) {
					return new tests.fixtures.handlers.Pages();
				});

				var result = dispatcher.dispatch("/pages/about", "GET");

				// Handler should have used urlFor
				expect(result).toBeStruct();
				expect(result.success).toBeTrue();
				expect(result.usersIndexUrl).toBe("/users");
			});

			it("should handle different handler return types", function() {
				var dispatcher = container.resolve("dispatcher");

				container.bind("Users", function(c) {
					return new tests.fixtures.handlers.Users();
				});

				// Test struct return (JSON response)
				var structResult = dispatcher.dispatch("/users", "GET");
				expect(structResult).toBeStruct();
				expect(structResult.success).toBeTrue();

				// Test create action with different return
				var createResult = dispatcher.dispatch("/users", "POST");
				expect(createResult).toBeStruct();
				expect(createResult.created).toBeTrue();
			});

			it("should allow handlers to access route params from event context", function() {
				var dispatcher = container.resolve("dispatcher");
				var eventService = container.resolve("eventService");
				var capturedParams = {};

				// Capture params from handler via interceptor
				eventService.registerInterceptor("onAfterHandler", function(event) {
					capturedParams = event.params;
				});

				container.bind("Users", function(c) {
					return new tests.fixtures.handlers.Users();
				});

				dispatcher.dispatch("/users/99", "GET");

				expect(capturedParams).toHaveKey("id");
				expect(capturedParams.id).toBe("99");
			});

			it("should support handlers with multiple CRUD actions", function() {
				var dispatcher = container.resolve("dispatcher");

				container.bind("Users", function(c) {
					return new tests.fixtures.handlers.Users();
				});

				// Test index action
				var indexResult = dispatcher.dispatch("/users", "GET");
				expect(indexResult.action).toBe("index");

				// Test show action
				var showResult = dispatcher.dispatch("/users/123", "GET");
				expect(showResult.action).toBe("show");
				expect(showResult.id).toBe("123");

				// Test create action
				var createResult = dispatcher.dispatch("/users", "POST");
				expect(createResult.created).toBeTrue();
			});

		});
	}

}
