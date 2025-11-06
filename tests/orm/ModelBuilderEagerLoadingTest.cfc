component extends="testbox.system.BaseSpec" {

	function run() {
		describe("ModelBuilder eager loading API", function() {

			beforeEach(function() {
				variables.datasource = "testdb";
			});

			it("should chain includes() with where/orderBy/limit", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);

				var chain = user.where({active: true})
					.includes("posts")
					.orderBy("name")
					.limit(10);

				expect(chain).toBeInstanceOf("fuse.orm.ModelBuilder");
			});

			it("should accept string syntax for includes()", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);

				user.includes("posts");
				var scope = user.getVariablesScope();

				expect(scope.eagerLoad).toBeArray();
				expect(arrayLen(scope.eagerLoad)).toBe(1);
				expect(scope.eagerLoad[1].name).toBe("posts");
				expect(scope.eagerLoad[1].strategy).toBe("auto");
			});

			it("should accept array syntax for includes()", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);

				user.includes(["posts", "profile"]);
				var scope = user.getVariablesScope();

				expect(scope.eagerLoad).toBeArray();
				expect(arrayLen(scope.eagerLoad)).toBe(2);
				expect(scope.eagerLoad[1].name).toBe("posts");
				expect(scope.eagerLoad[2].name).toBe("profile");
			});

			it("should accept dot notation for nested relationships", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);

				user.includes("posts.comments");
				var scope = user.getVariablesScope();

				expect(scope.eagerLoad).toBeArray();
				expect(arrayLen(scope.eagerLoad)).toBe(1);
				expect(scope.eagerLoad[1].name).toBe("posts.comments");
			});

			it("should force JOIN strategy with joins()", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);

				user.joins("posts");
				var scope = user.getVariablesScope();

				expect(scope.eagerLoad).toBeArray();
				expect(arrayLen(scope.eagerLoad)).toBe(1);
				expect(scope.eagerLoad[1].name).toBe("posts");
				expect(scope.eagerLoad[1].strategy).toBe("join");
			});

			it("should force separate query strategy with preload()", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);

				user.preload("profile");
				var scope = user.getVariablesScope();

				expect(scope.eagerLoad).toBeArray();
				expect(arrayLen(scope.eagerLoad)).toBe(1);
				expect(scope.eagerLoad[1].name).toBe("profile");
				expect(scope.eagerLoad[1].strategy).toBe("separate");
			});

			it("should throw error for invalid relationship in includes()", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);

				expect(function() {
					user.includes("invalidRelation");
				}).toThrow(type="ActiveRecord.InvalidRelationship");
			});

			it("should validate all relationships in array syntax", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);

				expect(function() {
					user.includes(["posts", "invalidRelation"]);
				}).toThrow(type="ActiveRecord.InvalidRelationship");
			});

		});
	}

}
