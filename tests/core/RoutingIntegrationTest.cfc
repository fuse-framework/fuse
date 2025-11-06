/**
 * Routing & Event System Integration Tests
 *
 * Strategic integration tests covering critical end-to-end workflows.
 * These tests verify the complete routing feature works correctly
 * from route definition through handler execution to response.
 */
component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		variables.testAppScope = {};
	}

	function run() {
		describe("Complete request lifecycle integration", function() {

			beforeEach(function() {
				// Setup full framework stack
				container = new fuse.core.Container();
				router = new fuse.core.Router();
				eventService = new fuse.core.EventService();

				container.singleton("router", function(c) { return router; });
				container.singleton("eventService", function(c) { return eventService; });
				container.bind("dispatcher", function(c) {
					return new fuse.core.Dispatcher(
						c.resolve("router"),
						c,
						c.resolve("eventService")
					);
				});
			});

			it("should execute full end-to-end request: route definition -> dispatch -> handler -> response", function() {
				// Define route
				router.get("/products/:id", "Products.show", {name: "product_detail"});

				// Register handler
				container.bind("Products", function(c) {
					return {
						show: function(id) {
							return {
								success: true,
								product_id: arguments.id,
								type: "product_detail"
							};
						}
					};
				});

				// Execute full request lifecycle
				var dispatcher = container.resolve("dispatcher");
				var result = dispatcher.dispatch("/products/42", "GET");

				// Verify complete workflow
				expect(result).toBeStruct();
				expect(result.success).toBeTrue();
				expect(result.product_id).toBe("42");
				expect(result.type).toBe("product_detail");
			});

			it("should handle RESTful resource CRUD workflow through all 7 actions", function() {
				// Define RESTful resource
				router.resource("articles");

				// Register handler with all CRUD actions
				container.bind("Articles", function(c) {
					return {
						index: function() {
							return {action: "index", articles: []};
						},
						new: function() {
							return {action: "new", form: "create"};
						},
						create: function() {
							return {action: "create", created: true, id: 1};
						},
						show: function(id) {
							return {action: "show", id: arguments.id};
						},
						edit: function(id) {
							return {action: "edit", id: arguments.id, form: "update"};
						},
						update: function(id) {
							return {action: "update", id: arguments.id, updated: true};
						},
						destroy: function(id) {
							return {action: "destroy", id: arguments.id, deleted: true};
						}
					};
				});

				var dispatcher = container.resolve("dispatcher");

				// Test complete CRUD workflow
				var indexResult = dispatcher.dispatch("/articles", "GET");
				expect(indexResult.action).toBe("index");

				var newResult = dispatcher.dispatch("/articles/new", "GET");
				expect(newResult.action).toBe("new");
				expect(newResult.form).toBe("create");

				var createResult = dispatcher.dispatch("/articles", "POST");
				expect(createResult.action).toBe("create");
				expect(createResult.created).toBeTrue();

				var showResult = dispatcher.dispatch("/articles/99", "GET");
				expect(showResult.action).toBe("show");
				expect(showResult.id).toBe("99");

				var editResult = dispatcher.dispatch("/articles/99/edit", "GET");
				expect(editResult.action).toBe("edit");
				expect(editResult.id).toBe("99");

				var updateResult = dispatcher.dispatch("/articles/99", "PUT");
				expect(updateResult.action).toBe("update");
				expect(updateResult.updated).toBeTrue();

				var destroyResult = dispatcher.dispatch("/articles/99", "DELETE");
				expect(destroyResult.action).toBe("destroy");
				expect(destroyResult.deleted).toBeTrue();
			});

			it("should execute multiple interceptors across complete request lifecycle", function() {
				var executionLog = [];

				// Register interceptors across all lifecycle points
				eventService.registerInterceptor("onBeforeRequest", function(event) {
					arrayAppend(executionLog, "beforeRequest");
					event.request.logged = true;
				});

				eventService.registerInterceptor("onAfterRouting", function(event) {
					arrayAppend(executionLog, "afterRouting");
					event.route.validated = true;
				});

				eventService.registerInterceptor("onBeforeHandler", function(event) {
					arrayAppend(executionLog, "beforeHandler");
					event.handler.prepared = true;
				});

				eventService.registerInterceptor("onAfterHandler", function(event) {
					arrayAppend(executionLog, "afterHandler");
					event.result.processed = true;
				});

				// Add second interceptor to same point to verify chaining
				eventService.registerInterceptor("onAfterHandler", function(event) {
					arrayAppend(executionLog, "afterHandler2");
					event.result.enhanced = true;
				});

				// Setup route and handler
				router.get("/test", "Test.index");
				container.bind("Test", function(c) {
					return {
						index: function() {
							arrayAppend(executionLog, "handler_executed");
							return {success: true};
						}
					};
				});

				// Execute request
				var dispatcher = container.resolve("dispatcher");
				var result = dispatcher.dispatch("/test", "GET");

				// Verify complete interceptor chain executed in order
				expect(executionLog).toHaveLength(6);
				expect(executionLog[1]).toBe("beforeRequest");
				expect(executionLog[2]).toBe("afterRouting");
				expect(executionLog[3]).toBe("beforeHandler");
				expect(executionLog[4]).toBe("handler_executed");
				expect(executionLog[5]).toBe("afterHandler");
				expect(executionLog[6]).toBe("afterHandler2");

				// Verify interceptors modified result
				expect(result.processed).toBeTrue();
				expect(result.enhanced).toBeTrue();
			});

			it("should handle 404 error workflow when route not found", function() {
				router.get("/existing", "Pages.existing");

				container.bind("Pages", function(c) {
					return {
						existing: function() {
							return {success: true};
						}
					};
				});

				var dispatcher = container.resolve("dispatcher");

				// Request non-existent route
				var result = dispatcher.dispatch("/nonexistent", "GET");

				expect(result).toBeStruct();
				expect(result.status).toBe(404);
				expect(result.message).toInclude("not found");
			});

			it("should handle missing handler error with descriptive message", function() {
				// Define route but don't register handler
				router.get("/orphan", "OrphanHandler.action");

				var dispatcher = container.resolve("dispatcher");

				expect(function() {
					dispatcher.dispatch("/orphan", "GET");
				}).toThrow(
					type = "Dispatcher.HandlerNotFound",
					regex = "OrphanHandler"
				);
			});

			it("should provide URL generation in handler context through interceptor", function() {
				// Setup routes
				router.get("/dashboard", "Dashboard.index", {name: "dashboard"});
				router.resource("users");

				// Inject urlFor helper via interceptor
				eventService.registerInterceptor("onBeforeHandler", function(event) {
					var routerRef = router;
					event.handler.urlFor = function(name, params = {}) {
						return routerRef.urlFor(name, params);
					};
				});

				// Handler that uses urlFor
				container.bind("Dashboard", function(c) {
					return {
						index: function() {
							// Use injected urlFor helper
							return {
								success: true,
								links: {
									dashboard: this.urlFor("dashboard"),
									users: this.urlFor("users_index"),
									user_detail: this.urlFor("users_show", {id: 5})
								}
							};
						}
					};
				});

				var dispatcher = container.resolve("dispatcher");
				var result = dispatcher.dispatch("/dashboard", "GET");

				expect(result.success).toBeTrue();
				expect(result.links.dashboard).toBe("/dashboard");
				expect(result.links.users).toBe("/users");
				expect(result.links.user_detail).toBe("/users/5");
			});

			it("should support module-style interceptor registration pattern", function() {
				var moduleLog = [];

				// Simulate module registration phase
				// In real app, modules call this during register() method
				eventService.registerInterceptor("onBeforeRequest", function(event) {
					arrayAppend(moduleLog, "module_auth_check");
					event.authenticated = true;
				});

				eventService.registerInterceptor("onAfterHandler", function(event) {
					arrayAppend(moduleLog, "module_response_transform");
					event.result.transformed = true;
				});

				// Setup route and handler
				router.get("/secure", "Secure.data");
				container.bind("Secure", function(c) {
					return {
						data: function() {
							return {success: true, data: "sensitive"};
						}
					};
				});

				// Execute request
				var dispatcher = container.resolve("dispatcher");
				var result = dispatcher.dispatch("/secure", "GET");

				// Verify module interceptors executed
				expect(moduleLog).toHaveLength(2);
				expect(moduleLog[1]).toBe("module_auth_check");
				expect(moduleLog[2]).toBe("module_response_transform");
				expect(result.transformed).toBeTrue();
			});

			it("should load configuration and execute route from routes.cfm", function() {
				var config = new fuse.core.Config();

				// Create temp routes.cfm
				var tempPath = expandPath("/tests/fixtures/config/routes_integration.cfm");
				directoryCreate(expandPath("/tests/fixtures/config"), true, true);

				fileWrite(tempPath, '<cfscript>
// Static route
variables.router.get("/integration-test", "Integration.test", {name: "integration_test"});

// Resource route
variables.router.resource("posts", {only: ["index", "show"]});

// Param route
variables.router.get("/api/:version/status", "Api.status", {name: "api_status"});
</cfscript>');

				try {
					// Load routes from config
					config.loadRoutes(router, "/tests/fixtures/config/routes_integration.cfm");

					// Register handlers
					container.bind("Integration", function(c) {
						return {
							test: function() {
								return {success: true, route: "integration"};
							}
						};
					});

					container.bind("Posts", function(c) {
						return {
							index: function() {
								return {action: "index"};
							},
							show: function(id) {
								return {action: "show", id: arguments.id};
							}
						};
					});

					container.bind("Api", function(c) {
						return {
							status: function(version) {
								return {status: "ok", version: arguments.version};
							}
						};
					});

					var dispatcher = container.resolve("dispatcher");

					// Test routes loaded from config
					var testResult = dispatcher.dispatch("/integration-test", "GET");
					expect(testResult.success).toBeTrue();
					expect(testResult.route).toBe("integration");

					var postsResult = dispatcher.dispatch("/posts", "GET");
					expect(postsResult.action).toBe("index");

					var apiResult = dispatcher.dispatch("/api/v2/status", "GET");
					expect(apiResult.status).toBe("ok");
					expect(apiResult.version).toBe("v2");

					// Verify named routes work
					var url = router.urlFor("integration_test");
					expect(url).toBe("/integration-test");

					var apiUrl = router.urlFor("api_status", {version: "v3"});
					expect(apiUrl).toBe("/api/v3/status");

				} finally {
					// Cleanup
					if (fileExists(tempPath)) {
						fileDelete(tempPath);
					}
				}
			});

			it("should integrate with Bootstrap initialization for complete framework startup", function() {
				// Full framework initialization
				var bootstrap = new fuse.core.Bootstrap();
				var testAppScope = {};
				var framework = bootstrap.initFramework(testAppScope, "fuse", 30);
				var frameworkContainer = framework.getContainer();

				// Resolve routing services
				var frameworkRouter = frameworkContainer.resolve("router");
				var frameworkEventService = frameworkContainer.resolve("eventService");
				var frameworkDispatcher = frameworkContainer.resolve("dispatcher");

				// Verify all services registered and working
				expect(frameworkRouter).toBeInstanceOf("fuse.core.Router");
				expect(frameworkEventService).toBeInstanceOf("fuse.core.EventService");
				expect(frameworkDispatcher).toBeInstanceOf("fuse.core.Dispatcher");

				// Add route to initialized router
				frameworkRouter.get("/bootstrap-test", "BootstrapTest.index", {name: "bootstrap_test"});

				// Register handler
				frameworkContainer.bind("BootstrapTest", function(c) {
					return {
						index: function() {
							return {success: true, initialized: true};
						}
					};
				});

				// Execute request through framework dispatcher
				var result = frameworkDispatcher.dispatch("/bootstrap-test", "GET");

				expect(result.success).toBeTrue();
				expect(result.initialized).toBeTrue();

				// Verify URL generation works
				var url = frameworkRouter.urlFor("bootstrap_test");
				expect(url).toBe("/bootstrap-test");
			});

			it("should handle interceptor abort workflow to short-circuit request", function() {
				var executionLog = [];

				// First interceptor aborts the request
				eventService.registerInterceptor("onBeforeHandler", function(event) {
					arrayAppend(executionLog, "interceptor1");
					event.abort = true;
					event.abortReason = "unauthorized";
				});

				// Second interceptor should not execute
				eventService.registerInterceptor("onBeforeHandler", function(event) {
					arrayAppend(executionLog, "interceptor2");
				});

				router.get("/protected", "Protected.data");
				container.bind("Protected", function(c) {
					return {
						data: function() {
							arrayAppend(executionLog, "handler_executed");
							return {success: true};
						}
					};
				});

				var dispatcher = container.resolve("dispatcher");
				var result = dispatcher.dispatch("/protected", "GET");

				// Handler should not execute due to abort
				expect(executionLog).toHaveLength(1);
				expect(executionLog[1]).toBe("interceptor1");

				// Verify result reflects abort (dispatcher returns empty/null on abort)
				// In real implementation, this might return 401/403 response
			});

		});
	}

}
