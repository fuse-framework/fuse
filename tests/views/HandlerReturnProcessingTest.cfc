component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Handler return processing and view rendering integration", function() {

			beforeEach(function() {
				// Setup container with required services
				container = new fuse.core.Container();

				// Register config
				container.singleton("config", function(c) {
					return {
						views: {
							path: "/tests/fixtures/views",
							layoutPath: "/tests/fixtures/views/layouts",
							defaultLayout: "application"
						}
					};
				});

				// Register router singleton
				container.singleton("router", function(c) {
					return new fuse.core.Router();
				});

				// Register eventService singleton
				container.singleton("eventService", function(c) {
					return new fuse.core.EventService();
				});

				// Register ViewRenderer
				container.singleton("ViewRenderer", function(c) {
					var config = c.resolve("config");
					return new fuse.views.ViewRenderer(config);
				});

				// Setup ViewModule to register interceptors
				var viewModule = new fuse.modules.ViewModule();
				viewModule.register(container);
				viewModule.boot(container);

				// Setup test routes
				router = container.resolve("router");
				router.get("/users/:id", "Users.show", {name: "users_show"});
				router.get("/users", "Users.index", {name: "users_index"});
				router.get("/posts/:id", "Posts.show", {name: "posts_show"});

				// Register dispatcher
				container.bind("dispatcher", function(c) {
					return new fuse.core.Dispatcher(
						c.resolve("router"),
						c,
						c.resolve("eventService")
					);
				});
			});

			it("should process string return as view path", function() {
				var dispatcher = container.resolve("dispatcher");

				// Handler returns string
				container.bind("Users", function(c) {
					return {
						show: function(id) {
							return "users/show";
						}
					};
				});

				var result = dispatcher.dispatch("/users/123", "GET");

				expect(result).toBeStruct();
				expect(result.body).toInclude("<h1>User ##123</h1>");
			});

			it("should process struct return with view and locals", function() {
				var dispatcher = container.resolve("dispatcher");

				// Handler returns struct with view and locals
				container.bind("Users", function(c) {
					return {
						index: function() {
							return {
								view: "users/index",
								locals: {
									users: ["Alice", "Bob", "Charlie"]
								}
							};
						}
					};
				});

				var result = dispatcher.dispatch("/users", "GET");

				expect(result).toBeStruct();
				expect(result.body).toInclude("Users List");
				expect(result.body).toInclude("Alice");
			});

			it("should derive view from route for null return", function() {
				var dispatcher = container.resolve("dispatcher");

				// Handler returns void/null
				container.bind("Posts", function(c) {
					return {
						show: function(id) {
							// No explicit return
						}
					};
				});

				var result = dispatcher.dispatch("/posts/456", "GET");

				expect(result).toBeStruct();
				expect(result.body).toInclude("Post ##456");
			});

			it("should wrap view in layout when layout specified", function() {
				var dispatcher = container.resolve("dispatcher");

				// Handler returns struct with custom layout
				container.bind("Users", function(c) {
					return {
						show: function(id) {
							return {
								view: "users/show",
								locals: {id: arguments.id},
								layout: "admin"
							};
						}
					};
				});

				var result = dispatcher.dispatch("/users/999", "GET");

				expect(result).toBeStruct();
				expect(result.body).toInclude("Admin Layout");
				expect(result.body).toInclude("<h1>User ##999</h1>");
			});

			it("should skip layout when layout: false", function() {
				var dispatcher = container.resolve("dispatcher");

				// Handler returns struct with layout: false
				container.bind("Users", function(c) {
					return {
						show: function(id) {
							return {
								view: "users/show",
								locals: {id: arguments.id},
								layout: false
							};
						}
					};
				});

				var result = dispatcher.dispatch("/users/777", "GET");

				expect(result).toBeStruct();
				expect(result.body).toInclude("<h1>User ##777</h1>");
				expect(result.body).notToInclude("Application Layout");
			});

			it("should make built-in helpers available in views", function() {
				var dispatcher = container.resolve("dispatcher");

				// Handler returns view that uses helpers
				container.bind("Users", function(c) {
					return {
						show: function(id) {
							return {
								view: "users/helpers",
								locals: {
									rawHtml: "<script>alert('xss')</script>",
									userId: arguments.id
								}
							};
						}
					};
				});

				var result = dispatcher.dispatch("/users/888", "GET");

				expect(result).toBeStruct();
				// h() helper should escape HTML
				expect(result.body).toInclude("&lt;script&gt;");
				// linkTo() helper should generate URL
				expect(result.body).toInclude("/users/888");
			});

			it("should set response.body in event context", function() {
				var dispatcher = container.resolve("dispatcher");
				var eventService = container.resolve("eventService");
				var capturedEvent = {};

				// Capture event after rendering
				eventService.registerInterceptor("onAfterRender", function(event) {
					capturedEvent = duplicate(event);
				});

				container.bind("Users", function(c) {
					return {
						show: function(id) {
							return "users/show";
						}
					};
				});

				dispatcher.dispatch("/users/555", "GET");

				expect(capturedEvent.response.body).toInclude("<h1>User ##555</h1>");
			});

		});
	}

}
