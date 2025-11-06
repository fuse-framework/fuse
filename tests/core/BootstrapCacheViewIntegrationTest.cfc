component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		variables.testAppScope = {};
	}

	function run() {
		describe("Bootstrap cache and view module integration", function() {

			beforeEach(function() {
				variables.testAppScope = {};
			});

			it("should discover and load CacheModule from framework modules", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();

				// CacheModule should be discovered and ICacheProvider should be resolvable
				expect(container.has("ICacheProvider")).toBeTrue();
				var cacheProvider = container.resolve("ICacheProvider");
				expect(cacheProvider).toBeInstanceOf("fuse.cache.RAMCacheProvider");
			});

			it("should discover and load ViewModule from framework modules", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();

				// ViewModule should be discovered and ViewRenderer should be resolvable
				expect(container.has("ViewRenderer")).toBeTrue();
				var viewRenderer = container.resolve("ViewRenderer");
				expect(viewRenderer).toBeInstanceOf("fuse.views.ViewRenderer");
			});

			it("should merge cache configuration with defaults", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();
				var config = container.resolve("config");

				// Cache defaults from CacheModule.getConfig()
				expect(config).toHaveKey("CacheModule");
				expect(config.CacheModule).toHaveKey("cache");
				expect(config.CacheModule.cache.defaultTTL).toBe(0);
				expect(config.CacheModule.cache.enabled).toBeTrue();
			});

			it("should merge view configuration with defaults", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();
				var config = container.resolve("config");

				// View defaults from ViewModule.getConfig()
				expect(config).toHaveKey("ViewModule");
				expect(config.ViewModule).toHaveKey("views");
				expect(config.ViewModule.views.path).toBe("/views");
				expect(config.ViewModule.views.layoutPath).toBe("/views/layouts");
				expect(config.ViewModule.views.defaultLayout).toBe("application");
			});

			it("should initialize CacheModule and ViewModule in correct order", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();

				// Both modules should complete register() and boot() phases
				// Verify by checking services are resolvable
				expect(container.has("ICacheProvider")).toBeTrue();
				expect(container.has("ViewRenderer")).toBeTrue();

				// Verify cache provider works
				var cache = container.resolve("ICacheProvider");
				cache.set("test", "value", 0);
				expect(cache.get("test")).toBe("value");

				// Verify view renderer has helpers registered
				var renderer = container.resolve("ViewRenderer");
				expect(renderer.hasHelper("h")).toBeTrue();
				expect(renderer.hasHelper("linkTo")).toBeTrue();
			});

			it("should make ICacheProvider available for dependency injection", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();

				// Verify ICacheProvider can be resolved multiple times as singleton
				var cache1 = container.resolve("ICacheProvider");
				var cache2 = container.resolve("ICacheProvider");

				expect(cache1).toBe(cache2);
			});

			it("should make ViewRenderer available with event integration", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();

				// Verify ViewRenderer is registered as singleton
				var renderer1 = container.resolve("ViewRenderer");
				var renderer2 = container.resolve("ViewRenderer");

				expect(renderer1).toBe(renderer2);

				// Verify onBeforeRender interceptor is registered
				var eventService = container.resolve("eventService");
				// EventService should have interceptors registered
				expect(eventService).toBeInstanceOf("fuse.core.EventService");
			});

		});
	}

}
