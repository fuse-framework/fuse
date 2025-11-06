component extends="testbox.system.BaseSpec" {

	function run() {
		describe("View rendering edge cases and error scenarios", function() {

			beforeEach(function() {
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

			it("should handle view with no locals (empty struct)", function() {
				var html = renderer.render("simple", {}, false);
				expect(html).toBeString();
				expect(html).toInclude("Hello");
			});

			it("should handle nested view paths correctly", function() {
				// Test deeply nested path: admin/users/settings
				var html = renderer.render("users/index", {username: "TestUser"}, false);
				expect(html).toInclude("User: TestUser");
			});

			it("should isolate helper scope and prevent global pollution", function() {
				// Register helper
				renderer.addHelper("testHelper", function() {
					return "helper output";
				});

				// Render view that uses helper
				renderer.render("with_helper", {text: "test"}, false);

				// Verify helper doesn't pollute global scope
				expect(function() {
					testHelper();
				}).toThrow();
			});

			it("should handle MissingTemplateException with detailed error info", function() {
				try {
					renderer.render("totally/nonexistent/path", {}, false);
					fail("Should have thrown MissingTemplateException");
				} catch (any e) {
					expect(e.type).toBe("MissingTemplateException");
					expect(e.message).toInclude("totally/nonexistent/path");
					expect(e.detail).toInclude("Attempted path");
				}
			});

		});
	}

}
