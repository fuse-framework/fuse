component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Cache and View rendering end-to-end integration", function() {

			beforeEach(function() {
				variables.testAppScope = {};
			});

			it("should handle complete request lifecycle from handler to rendered response", function() {
				// Bootstrap full framework
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();
				var router = container.resolve("router");
				var dispatcher = container.resolve("dispatcher");

				// Setup test route and handler
				router.get("/products/:id", "Products.show", {name: "products_show"});

				container.bind("Products", function(c) {
					return {
						show: function(id) {
							// Handler returns struct with view, locals, and layout
							return {
								view: "products/show",
								locals: {productId: arguments.id, title: "Product Details"},
								layout: "application"
							};
						}
					};
				});

				// Dispatch request
				var response = dispatcher.dispatch("/products/123", "GET");

				// Verify complete pipeline executed
				expect(response).toBeStruct();
				expect(response.body).toInclude("Product ##123");
				expect(response.body).toInclude("Product Details");
			});

			it("should cache data across multiple requests using ICacheProvider", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();
				var cache = container.resolve("ICacheProvider");

				// First request caches data
				cache.set("user:123", {name: "Alice", email: "alice@example.com"}, 10);

				// Second request retrieves from cache
				var cached = cache.get("user:123");

				expect(cached).toBeStruct();
				expect(cached.name).toBe("Alice");
				expect(cached.email).toBe("alice@example.com");
			});

			it("should render view with helpers accessible from handler to final HTML", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();
				var router = container.resolve("router");
				var dispatcher = container.resolve("dispatcher");

				router.get("/users/:id", "Users.profile", {name: "users_profile"});

				container.bind("Users", function(c) {
					return {
						profile: function(id) {
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

				var response = dispatcher.dispatch("/users/456", "GET");

				// Verify h() helper escaped HTML
				expect(response.body).toInclude("&lt;script&gt;");
				expect(response.body).notToInclude("<script>alert");

				// Verify linkTo() helper generated URL
				expect(response.body).toInclude("/users/456");
			});

		});
	}

}
