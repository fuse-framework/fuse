component extends="testbox.system.BaseSpec" {

	function run() {
		describe("EagerLoader strategy selection", function() {

			beforeEach(function() {
				variables.datasource = "testdb";
				variables.eagerLoader = new fuse.orm.EagerLoader();
			});

			it("should select JOIN strategy for belongsTo relationships", function() {
				var metadata = {
					type: "belongsTo",
					foreignKey: "user_id",
					className: "User"
				};

				var strategy = variables.eagerLoader.selectStrategy("user", metadata);

				expect(strategy).toBe("join");
			});

			it("should select JOIN strategy for hasOne relationships", function() {
				var metadata = {
					type: "hasOne",
					foreignKey: "user_id",
					className: "Profile"
				};

				var strategy = variables.eagerLoader.selectStrategy("profile", metadata);

				expect(strategy).toBe("join");
			});

			it("should select separate query strategy for hasMany relationships", function() {
				var metadata = {
					type: "hasMany",
					foreignKey: "user_id",
					className: "Post"
				};

				var strategy = variables.eagerLoader.selectStrategy("posts", metadata);

				expect(strategy).toBe("separate");
			});

			it("should parse single-level relationship path", function() {
				var path = variables.eagerLoader.parseRelationshipPath("posts");

				expect(path).toBeArray();
				expect(arrayLen(path)).toBe(1);
				expect(path[1]).toBe("posts");
			});

			it("should parse nested relationship path with dot notation", function() {
				var path = variables.eagerLoader.parseRelationshipPath("posts.comments");

				expect(path).toBeArray();
				expect(arrayLen(path)).toBe(2);
				expect(path[1]).toBe("posts");
				expect(path[2]).toBe("comments");
			});

			it("should parse deeply nested relationship path", function() {
				var path = variables.eagerLoader.parseRelationshipPath("posts.comments.author");

				expect(path).toBeArray();
				expect(arrayLen(path)).toBe(3);
				expect(path[1]).toBe("posts");
				expect(path[2]).toBe("comments");
				expect(path[3]).toBe("author");
			});

			it("should throw error for invalid relationship name", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);

				expect(function() {
					variables.eagerLoader.validateRelationship(user, "invalidRelation");
				}).toThrow(type="ActiveRecord.InvalidRelationship");
			});

			it("should validate correct relationship name without throwing", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);

				// Should not throw
				variables.eagerLoader.validateRelationship(user, "posts");
			});

		});
	}

}
