component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		variables.container = new fuse.core.Container();
		variables.testViewsPath = expandPath("/tests/fixtures/views");
		variables.testLayoutsPath = expandPath("/tests/fixtures/views/layouts");
	}

	function run() {
		describe("ViewRenderer component", function() {

			beforeEach(function() {
				// Setup container with config
				variables.container = new fuse.core.Container();
				container.singleton("config", function(c) {
					return {
						views: {
							path: "/tests/fixtures/views",
							layoutPath: "/tests/fixtures/views/layouts",
							defaultLayout: "application"
						}
					};
				});

				variables.renderer = new fuse.views.ViewRenderer(container.resolve("config"));
			});

			it("should render view with locals", function() {
				var html = renderer.render("simple", {name: "Alice"}, false);

				expect(html).toInclude("Hello, Alice!");
			});

			it("should wrap view with layout when layout exists", function() {
				var html = renderer.render("simple", {name: "Bob"}, "application");

				expect(html).toInclude("<html>");
				expect(html).toInclude("Hello, Bob!");
				expect(html).toInclude("</html>");
			});

			it("should return unwrapped view when layout is false", function() {
				var html = renderer.render("simple", {name: "Charlie"}, false);

				expect(html).notToInclude("<html>");
				expect(html).toInclude("Hello, Charlie!");
			});

			it("should fallback to unwrapped view when layout does not exist", function() {
				var html = renderer.render("simple", {name: "Dana"}, "nonexistent");

				expect(html).notToInclude("<html>");
				expect(html).toInclude("Hello, Dana!");
			});

			it("should throw MissingTemplateException when view not found", function() {
				expect(function() {
					renderer.render("nonexistent", {}, false);
				}).toThrow("MissingTemplateException");
			});

			it("should inject registered helpers into view scope", function() {
				renderer.addHelper("uppercase", function(str) {
					return uCase(arguments.str);
				});

				var html = renderer.render("with_helper", {text: "hello"}, false);

				expect(html).toInclude("HELLO");
			});

			it("should resolve convention-based view paths correctly", function() {
				// Test: "users/index" -> "/tests/fixtures/views/users/index.cfm"
				var html = renderer.render("users/index", {username: "Eve"}, false);

				expect(html).toInclude("User: Eve");
			});

			it("should provide MissingTemplateException with attempted path", function() {
				try {
					renderer.render("missing/view", {}, false);
					fail("Should have thrown MissingTemplateException");
				} catch (any e) {
					expect(e.type).toBe("MissingTemplateException");
					expect(e.message).toInclude("missing/view");
				}
			});

		});
	}

}
