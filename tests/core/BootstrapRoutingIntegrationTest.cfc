component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		variables.testAppScope = {};
	}

	function run() {
		describe("Bootstrap routing integration", function() {

			beforeEach(function() {
				variables.testAppScope = {};
			});

			it("should register Router as singleton in container", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();

				expect(container.has("router")).toBeTrue();
				var router = container.resolve("router");
				expect(router).toBeInstanceOf("fuse.core.Router");
			});

			it("should register EventService as singleton in container", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();

				expect(container.has("eventService")).toBeTrue();
				var eventService = container.resolve("eventService");
				expect(eventService).toBeInstanceOf("fuse.core.EventService");
			});

			it("should register Dispatcher as transient binding in container", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();

				expect(container.has("dispatcher")).toBeTrue();
				var dispatcher = container.resolve("dispatcher");
				expect(dispatcher).toBeInstanceOf("fuse.core.Dispatcher");
			});

			it("should return same Router instance on multiple resolves (singleton)", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();

				var router1 = container.resolve("router");
				var router2 = container.resolve("router");

				expect(router1).toBe(router2);
			});

			it("should return same EventService instance on multiple resolves (singleton)", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();

				var eventService1 = container.resolve("eventService");
				var eventService2 = container.resolve("eventService");

				expect(eventService1).toBe(eventService2);
			});

			it("should return different Dispatcher instances on multiple resolves (transient)", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();

				var dispatcher1 = container.resolve("dispatcher");
				var dispatcher2 = container.resolve("dispatcher");

				// Both should be Dispatcher instances
				expect(dispatcher1).toBeInstanceOf("fuse.core.Dispatcher");
				expect(dispatcher2).toBeInstanceOf("fuse.core.Dispatcher");

				// Add a property to first instance to verify they are separate
				dispatcher1.testMarker = "instance1";

				// Second instance should not have the marker (different object)
				expect(structKeyExists(dispatcher2, "testMarker")).toBeFalse();
			});

			it("should initialize routing services only once (thread-safe)", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();

				var router = container.resolve("router");
				router.get("/test", "Test.index", {name: "test_route"});

				// Initialize again with same app scope
				var framework2 = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container2 = framework2.getContainer();
				var router2 = container2.resolve("router");

				// Should be same router instance with same routes
				expect(router2).toBe(router);
				expect(router2.getNamedRoute("test_route")).notToBeNull();
			});

			it("should inject router, container, and eventService into Dispatcher", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();

				// Dispatcher should successfully resolve with dependencies
				var dispatcher = container.resolve("dispatcher");

				// Verify it's properly constructed by attempting a dispatch
				// This would fail if dependencies weren't injected
				expect(function() {
					dispatcher.dispatch("/nonexistent", "GET");
				}).notToThrow(type: "Container.MissingDependency");
			});

		});
	}

}
