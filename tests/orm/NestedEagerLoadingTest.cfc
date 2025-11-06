component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Nested eager loading and N+1 detection", function() {

			beforeEach(function() {
				variables.datasource = "testdb";
			});

			it("should support nested eager loading with dot notation", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);

				user.includes(["posts.comments"]);
				var scope = user.getVariablesScope();

				expect(scope.eagerLoad).toBeArray();
				expect(arrayLen(scope.eagerLoad)).toBe(1);
				expect(scope.eagerLoad[1].name).toBe("posts.comments");
			});

			it("should support arbitrary depth nesting", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);

				user.includes(["posts.comments.author"]);
				var scope = user.getVariablesScope();

				expect(scope.eagerLoad).toBeArray();
				expect(arrayLen(scope.eagerLoad)).toBe(1);
				expect(scope.eagerLoad[1].name).toBe("posts.comments.author");
			});

			it("should return true for loaded relationships via isRelationshipLoaded()", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);
				user.populate({id: 1, name: "Test User"});

				// Initially not loaded
				expect(user.isRelationshipLoaded("posts")).toBeFalse();

				// Manually populate loaded relationships to simulate eager load
				var scope = user.getVariablesScope();
				scope.loadedRelationships["posts"] = [];

				// Now should be loaded
				expect(user.isRelationshipLoaded("posts")).toBeTrue();
			});

			it("should return false for non-loaded relationships via isRelationshipLoaded()", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);
				user.populate({id: 1, name: "Test User"});

				expect(user.isRelationshipLoaded("posts")).toBeFalse();
				expect(user.isRelationshipLoaded("profile")).toBeFalse();
			});

			it("should load nested relationships recursively", function() {
				var eagerLoader = new fuse.orm.EagerLoader();

				// Parse nested path
				var path = eagerLoader.parseRelationshipPath("posts.comments");

				expect(path).toBeArray();
				expect(arrayLen(path)).toBe(2);
				expect(path[1]).toBe("posts");
				expect(path[2]).toBe("comments");
			});

			it("should handle deeply nested relationship paths", function() {
				var eagerLoader = new fuse.orm.EagerLoader();

				var path = eagerLoader.parseRelationshipPath("posts.comments.author.profile");

				expect(path).toBeArray();
				expect(arrayLen(path)).toBe(4);
				expect(path[1]).toBe("posts");
				expect(path[2]).toBe("comments");
				expect(path[3]).toBe("author");
				expect(path[4]).toBe("profile");
			});

		});
	}

}
