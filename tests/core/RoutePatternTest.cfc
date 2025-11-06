component extends="testbox.system.BaseSpec" {

	function run() {
		describe("RoutePattern matching", function() {

			it("should match static segment pattern", function() {
				var pattern = new fuse.core.RoutePattern("/about");
				var result = pattern.match("/about");

				expect(result).toBeStruct();
				expect(result.matched).toBeTrue();
			});

			it("should not match different static path", function() {
				var pattern = new fuse.core.RoutePattern("/about");
				var result = pattern.match("/contact");

				expect(result.matched).toBeFalse();
			});

			it("should extract named parameter from path", function() {
				var pattern = new fuse.core.RoutePattern("/users/:id");
				var result = pattern.match("/users/123");

				expect(result.matched).toBeTrue();
				expect(result.id).toBe("123");
			});

			it("should extract multiple named parameters", function() {
				var pattern = new fuse.core.RoutePattern("/posts/:postId/comments/:id");
				var result = pattern.match("/posts/42/comments/99");

				expect(result.matched).toBeTrue();
				expect(result.postId).toBe("42");
				expect(result.id).toBe("99");
			});

			it("should capture wildcard path segment", function() {
				var pattern = new fuse.core.RoutePattern("/files/*path");
				var result = pattern.match("/files/docs/readme.pdf");

				expect(result.matched).toBeTrue();
				expect(result.path).toBe("docs/readme.pdf");
			});

			it("should handle trailing slashes consistently", function() {
				var pattern = new fuse.core.RoutePattern("/about");

				var result1 = pattern.match("/about");
				var result2 = pattern.match("/about/");

				expect(result1.matched).toBeTrue();
				expect(result2.matched).toBeTrue();
			});

			it("should return false for non-matching pattern", function() {
				var pattern = new fuse.core.RoutePattern("/users/:id");
				var result = pattern.match("/posts/123");

				expect(result.matched).toBeFalse();
			});

			it("should match complex mixed pattern", function() {
				var pattern = new fuse.core.RoutePattern("/api/:version/users/:id/*action");
				var result = pattern.match("/api/v1/users/123/profile/edit");

				expect(result.matched).toBeTrue();
				expect(result.version).toBe("v1");
				expect(result.id).toBe("123");
				expect(result.action).toBe("profile/edit");
			});

		});
	}

}
