component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Dispatcher request lifecycle orchestration", function() {

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
				router.get("/users/:id", "Users.show", {name: "users_show"});
				router.post("/users", "Users.create");
				router.get("/static", "Pages.static");

				// Register transient dispatcher binding
				container.bind("dispatcher", function(c) {
					return new fuse.core.Dispatcher(
						c.resolve("router"),
						c,
						c.resolve("eventService")
					);
				});
			});

			it("should execute full request lifecycle with matching route", function() {
				var dispatcher = container.resolve("dispatcher");

				// Register handler with container
				container.bind("Users", function(c) {
					return {
						show: function(id) {
							return {success: true, id: arguments.id};
						}
					};
				});

				var result = dispatcher.dispatch("/users/123", "GET");

				expect(result).toBeStruct();
				expect(result.success).toBeTrue();
				expect(result.id).toBe("123");
			});

			it("should instantiate handler via Container as transient", function() {
				var dispatcher = container.resolve("dispatcher");
				var instanceIds = [];

				// Register handler with container that tracks instance IDs
				container.bind("Users", function(c) {
					var handlerInstanceId = createUUID();
					arrayAppend(instanceIds, handlerInstanceId);
					return {
						show: function(id) {
							return {success: true, id: arguments.id, handlerInstanceId: handlerInstanceId};
						}
					};
				});

				var result1 = dispatcher.dispatch("/users/123", "GET");
				var result2 = dispatcher.dispatch("/users/456", "GET");

				// Each dispatch should create new handler instance (transient)
				expect(result1.success).toBeTrue();
				expect(result2.success).toBeTrue();
				expect(instanceIds).toHaveLength(2);
				expect(instanceIds[1]).notToBe(instanceIds[2]);
				expect(result1.handlerInstanceId).toBe(instanceIds[1]);
				expect(result2.handlerInstanceId).toBe(instanceIds[2]);
			});

			it("should invoke handler action method with route params", function() {
				var dispatcher = container.resolve("dispatcher");
				var invocationRecord = [];

				// Register handler that records invocations
				container.bind("Users", function(c) {
					var handler = {
						show: function(id) {
							arrayAppend(invocationRecord, {method: "show", id: arguments.id});
							return {success: true, id: arguments.id};
						},
						create: function() {
							arrayAppend(invocationRecord, {method: "create"});
							return {success: true};
						}
					};
					return handler;
				});

				dispatcher.dispatch("/users/789", "GET");

				expect(invocationRecord).toHaveLength(1);
				expect(invocationRecord[1].method).toBe("show");
				expect(invocationRecord[1].id).toBe("789");
			});

			it("should return 404 for unmatched routes", function() {
				var dispatcher = container.resolve("dispatcher");

				var result = dispatcher.dispatch("/nonexistent", "GET");

				expect(result).toBeStruct();
				expect(result.status).toBe(404);
				expect(result.message).toInclude("not found");
			});

			it("should handle missing handler with descriptive error", function() {
				var dispatcher = container.resolve("dispatcher");

				// Add route but don't register handler
				router.get("/missing/:id", "MissingHandler.show");

				expect(function() {
					dispatcher.dispatch("/missing/123", "GET");
				}).toThrow(
					type = "Dispatcher.HandlerNotFound",
					regex = "MissingHandler"
				);
			});

			it("should handle missing action with descriptive error", function() {
				var dispatcher = container.resolve("dispatcher");

				// Register handler without the required action
				container.bind("Pages", function(c) {
					return {
						index: function() { return {}; }
						// Missing 'static' action
					};
				});

				expect(function() {
					dispatcher.dispatch("/static", "GET");
				}).toThrow(
					type = "Dispatcher.ActionNotFound",
					regex = "static"
				);
			});

			it("should trigger all 6 interceptor points in order", function() {
				var dispatcher = container.resolve("dispatcher");
				var eventService = container.resolve("eventService");
				var executionOrder = [];

				// Register interceptors for each point individually to avoid closure issues
				eventService.registerInterceptor("onBeforeRequest", function(event) {
					arrayAppend(executionOrder, "onBeforeRequest");
				});

				eventService.registerInterceptor("onAfterRouting", function(event) {
					arrayAppend(executionOrder, "onAfterRouting");
				});

				eventService.registerInterceptor("onBeforeHandler", function(event) {
					arrayAppend(executionOrder, "onBeforeHandler");
				});

				eventService.registerInterceptor("onAfterHandler", function(event) {
					arrayAppend(executionOrder, "onAfterHandler");
				});

				// Register simple handler
				container.bind("Users", function(c) {
					return {
						show: function(id) {
							return {success: true};
						}
					};
				});

				dispatcher.dispatch("/users/123", "GET");

				expect(executionOrder).toHaveLength(4);
				expect(executionOrder[1]).toBe("onBeforeRequest");
				expect(executionOrder[2]).toBe("onAfterRouting");
				expect(executionOrder[3]).toBe("onBeforeHandler");
				expect(executionOrder[4]).toBe("onAfterHandler");
			});

			it("should build event context with required properties", function() {
				var dispatcher = container.resolve("dispatcher");
				var eventService = container.resolve("eventService");
				var capturedEvent = {};

				// Capture event struct from interceptor
				eventService.registerInterceptor("onAfterRouting", function(event) {
					capturedEvent = duplicate(event);
				});

				// Register handler
				container.bind("Users", function(c) {
					return {
						show: function(id) {
							return {success: true};
						}
					};
				});

				dispatcher.dispatch("/users/123", "GET");

				expect(capturedEvent).toHaveKey("request");
				expect(capturedEvent).toHaveKey("response");
				expect(capturedEvent).toHaveKey("route");
				expect(capturedEvent).toHaveKey("params");
				expect(capturedEvent).toHaveKey("abort");
				expect(capturedEvent.params.id).toBe("123");
			});

		});
	}

}
