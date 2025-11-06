component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Router DSL", function() {

			beforeEach(function() {
				router = new fuse.core.Router();
			});

			it("should register GET route with pattern and handler", function() {
				router.get("/users", "Users.index");

				var result = router.findRoute("/users", "GET");

				expect(result).toBeStruct();
				expect(result.matched).toBeTrue();
				expect(result.route).toBeStruct();
				expect(result.route.pattern).toBe("/users");
				expect(result.route.handler).toBe("Users.index");
				expect(result.route.method).toBe("GET");
			});

			it("should register POST route", function() {
				router.post("/users", "Users.create");

				var result = router.findRoute("/users", "POST");

				expect(result.matched).toBeTrue();
				expect(result.route.method).toBe("POST");
				expect(result.route.handler).toBe("Users.create");
			});

			it("should register PUT, PATCH, DELETE routes", function() {
				router.put("/users/:id", "Users.update");
				router.patch("/users/:id", "Users.update");
				router.delete("/users/:id", "Users.destroy");

				var putResult = router.findRoute("/users/123", "PUT");
				var patchResult = router.findRoute("/users/123", "PATCH");
				var deleteResult = router.findRoute("/users/123", "DELETE");

				expect(putResult.route.method).toBe("PUT");
				expect(patchResult.route.method).toBe("PATCH");
				expect(deleteResult.route.method).toBe("DELETE");
			});

			it("should maintain registration order when matching", function() {
				router.get("/posts/:id", "Posts.show");
				router.get("/posts/new", "Posts.new");

				// First registered route should match
				var result = router.findRoute("/posts/123", "GET");
				expect(result.route.handler).toBe("Posts.show");

				// Static route registered second won't match if first matches
				var result2 = router.findRoute("/posts/new", "GET");
				expect(result2.route.handler).toBe("Posts.show");
			});

			it("should return first matching route", function() {
				router.get("/users/:id", "Users.show");
				router.get("/users/:id", "Users.duplicate");

				var result = router.findRoute("/users/123", "GET");
				expect(result.route.handler).toBe("Users.show");
			});

			it("should return matched=false when no route matches", function() {
				router.get("/users", "Users.index");

				var result = router.findRoute("/posts", "GET");
				expect(result.matched).toBeFalse();
			});

			it("should return matched=false when HTTP method does not match", function() {
				router.get("/users", "Users.index");

				var result = router.findRoute("/users", "POST");
				expect(result.matched).toBeFalse();
			});

			it("should register named route via options", function() {
				router.get("/about", "Pages.about", {name: "about_page"});

				var result = router.findRoute("/about", "GET");
				expect(result.route.name).toBe("about_page");

				// Verify named route can be looked up
				var namedRoute = router.getNamedRoute("about_page");
				expect(namedRoute).toBeStruct();
				expect(namedRoute.pattern).toBe("/about");
			});

			it("should extract route parameters", function() {
				router.get("/users/:id", "Users.show");

				var result = router.findRoute("/users/123", "GET");
				expect(result.params).toBeStruct();
				expect(result.params.id).toBe("123");
			});

		});

		describe("RESTful Resource Routes", function() {

			beforeEach(function() {
				router = new fuse.core.Router();
			});

			it("should generate 7 standard routes for resource", function() {
				router.resource("users");

				// Test all 7 routes exist
				var indexResult = router.findRoute("/users", "GET");
				expect(indexResult.matched).toBeTrue();
				expect(indexResult.route.handler).toBe("Users.index");

				var newResult = router.findRoute("/users/new", "GET");
				expect(newResult.matched).toBeTrue();
				expect(newResult.route.handler).toBe("Users.new");

				var createResult = router.findRoute("/users", "POST");
				expect(createResult.matched).toBeTrue();
				expect(createResult.route.handler).toBe("Users.create");

				var showResult = router.findRoute("/users/123", "GET");
				expect(showResult.matched).toBeTrue();
				expect(showResult.route.handler).toBe("Users.show");
				expect(showResult.params.id).toBe("123");

				var editResult = router.findRoute("/users/123/edit", "GET");
				expect(editResult.matched).toBeTrue();
				expect(editResult.route.handler).toBe("Users.edit");
				expect(editResult.params.id).toBe("123");

				var updateResult = router.findRoute("/users/123", "PUT");
				expect(updateResult.matched).toBeTrue();
				expect(updateResult.route.handler).toBe("Users.update");
				expect(updateResult.params.id).toBe("123");

				var deleteResult = router.findRoute("/users/123", "DELETE");
				expect(deleteResult.matched).toBeTrue();
				expect(deleteResult.route.handler).toBe("Users.destroy");
				expect(deleteResult.params.id).toBe("123");
			});

			it("should generate named routes for resource", function() {
				router.resource("users");

				// Check named route lookups
				expect(router.getNamedRoute("users_index")).toBeStruct();
				expect(router.getNamedRoute("users_new")).toBeStruct();
				expect(router.getNamedRoute("users_create")).toBeStruct();
				expect(router.getNamedRoute("users_show")).toBeStruct();
				expect(router.getNamedRoute("users_edit")).toBeStruct();
				expect(router.getNamedRoute("users_update")).toBeStruct();
				expect(router.getNamedRoute("users_destroy")).toBeStruct();
			});

			it("should limit routes with only option", function() {
				router.resource("posts", {only: ["index", "show"]});

				// Should match only specified routes
				var indexResult = router.findRoute("/posts", "GET");
				expect(indexResult.matched).toBeTrue();
				expect(indexResult.route.handler).toBe("Posts.index");

				var showResult = router.findRoute("/posts/123", "GET");
				expect(showResult.matched).toBeTrue();
				expect(showResult.route.handler).toBe("Posts.show");

				// Routes not in 'only' list should not be registered
				// Note: /posts/new will match /posts/:id (show route) with id="new"
				// This is correct router behavior - the handler must validate the id
				var newResult = router.findRoute("/posts/new", "GET");
				expect(newResult.matched).toBeTrue();
				expect(newResult.route.handler).toBe("Posts.show");
				expect(newResult.params.id).toBe("new");

				// POST should not match since 'create' not in only list
				var createResult = router.findRoute("/posts", "POST");
				expect(createResult.matched).toBeFalse();
			});

			it("should exclude routes with except option", function() {
				router.resource("comments", {except: ["new", "edit"]});

				// Should match non-excluded routes
				var indexResult = router.findRoute("/comments", "GET");
				expect(indexResult.matched).toBeTrue();
				expect(indexResult.route.handler).toBe("Comments.index");

				var createResult = router.findRoute("/comments", "POST");
				expect(createResult.matched).toBeTrue();
				expect(createResult.route.handler).toBe("Comments.create");

				// Excluded routes not registered, but /comments/new matches /comments/:id
				var newResult = router.findRoute("/comments/new", "GET");
				expect(newResult.matched).toBeTrue();
				expect(newResult.route.handler).toBe("Comments.show");
				expect(newResult.params.id).toBe("new");

				// /comments/123/edit won't match because 'edit' route not registered
				// and there's no catch-all for this pattern
				var editResult = router.findRoute("/comments/123/edit", "GET");
				expect(editResult.matched).toBeFalse();
			});

			it("should derive handler name from resource name with proper casing", function() {
				router.resource("blog_posts");

				var result = router.findRoute("/blog_posts", "GET");
				expect(result.route.handler).toBe("BlogPosts.index");
			});

			it("should support PATCH method for update action", function() {
				router.resource("users");

				var patchResult = router.findRoute("/users/123", "PATCH");
				expect(patchResult.matched).toBeTrue();
				expect(patchResult.route.handler).toBe("Users.update");
				expect(patchResult.params.id).toBe("123");
			});

		});

		describe("Named Routes and URL Generation", function() {

			beforeEach(function() {
				router = new fuse.core.Router();
			});

			it("should generate URL for basic named route", function() {
				router.get("/about", "Pages.about", {name: "about_page"});

				var generatedUrl = router.urlFor("about_page");
				expect(generatedUrl).toBe("/about");
			});

			it("should generate URL with single parameter replacement", function() {
				router.get("/users/:id", "Users.show", {name: "users_show"});

				var generatedUrl = router.urlFor("users_show", {id: 123});
				expect(generatedUrl).toBe("/users/123");
			});

			it("should generate URL with multiple parameters", function() {
				router.get("/posts/:post_id/comments/:id", "Comments.show", {name: "post_comments"});

				var generatedUrl = router.urlFor("post_comments", {post_id: 1, id: 5});
				expect(generatedUrl).toBe("/posts/1/comments/5");
			});

			it("should throw error when route name not found", function() {
				expect(function() {
					router.urlFor("nonexistent_route");
				}).toThrow(type = "RouteNotFoundException");
			});

			it("should throw error when required parameter missing", function() {
				router.get("/users/:id", "Users.show", {name: "users_show"});

				expect(function() {
					router.urlFor("users_show", {});
				}).toThrow(type = "MissingParameterException");
			});

			it("should work with resource-generated routes", function() {
				router.resource("users");

				expect(router.urlFor("users_index")).toBe("/users");
				expect(router.urlFor("users_show", {id: 42})).toBe("/users/42");
				expect(router.urlFor("users_edit", {id: 99})).toBe("/users/99/edit");
			});

		});
	}

}
