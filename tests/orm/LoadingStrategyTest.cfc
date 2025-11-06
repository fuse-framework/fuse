component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Loading strategy execution", function() {

			beforeEach(function() {
				variables.datasource = "testdb";
			});

			it("should add JOIN clause for belongsTo relationship", function() {
				var post = new tests.fixtures.PostWithRelationships(variables.datasource);
				var qb = post.select("posts.*");

				var relationshipConfig = {
					type: "belongsTo",
					foreignKey: "user_id",
					className: "User",
					relatedTable: "users"
				};

				var strategy = new fuse.orm.strategies.JoinStrategy();
				strategy.execute(qb, relationshipConfig, "user");

				// Verify JOIN clause was added
				var scope = qb.getVariablesScope();
				expect(scope.joinClauses).toBeArray();
				expect(arrayLen(scope.joinClauses)).toBe(1);
			});

			it("should add JOIN clause for hasOne relationship", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);
				var qb = user.select("users.*");

				var relationshipConfig = {
					type: "hasOne",
					foreignKey: "user_id",
					className: "Profile",
					relatedTable: "profiles"
				};

				var strategy = new fuse.orm.strategies.JoinStrategy();
				strategy.execute(qb, relationshipConfig, "profile");

				// Verify JOIN clause was added
				var scope = qb.getVariablesScope();
				expect(scope.joinClauses).toBeArray();
				expect(arrayLen(scope.joinClauses)).toBe(1);
			});

			it("should collect foreign key values for hasMany relationship", function() {
				var users = [
					{id: 10, name: "User 1"},
					{id: 20, name: "User 2"}
				];

				var relationshipConfig = {
					type: "hasMany",
					foreignKey: "user_id",
					className: "Post",
					relatedTable: "posts"
				};

				var strategy = new fuse.orm.strategies.SeparateQueryStrategy();
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);

				// Convert users to model instances
				var userInstances = [];
				for (var userData in users) {
					var instance = new tests.fixtures.UserWithRelationships(variables.datasource);
					instance.populate(userData);
					arrayAppend(userInstances, instance);
				}

				// Execute strategy
				var result = strategy.execute(user, relationshipConfig, userInstances, "posts");

				// Result should contain foreign key values collected
				expect(result).toBeStruct();
				expect(structKeyExists(result, "foreignKeyValues")).toBeTrue();
				expect(arrayLen(result.foreignKeyValues)).toBe(2);
			});

			it("should populate loadedRelationships after hydration", function() {
				var user = new tests.fixtures.UserWithRelationships(variables.datasource);
				user.populate({id: 10, name: "Test User"});

				// Create related posts as model instances
				var posts = [];
				var post1 = new tests.fixtures.PostWithRelationships(variables.datasource);
				post1.populate({id: 1, title: "Post 1", user_id: 10});
				arrayAppend(posts, post1);

				var post2 = new tests.fixtures.PostWithRelationships(variables.datasource);
				post2.populate({id: 2, title: "Post 2", user_id: 10});
				arrayAppend(posts, post2);

				var relationshipConfig = {
					type: "hasMany",
					foreignKey: "user_id",
					className: "Post"
				};

				var eagerLoader = new fuse.orm.EagerLoader();

				// Hydrate relationships
				eagerLoader.hydrateRelationships([user], posts, "posts", relationshipConfig);

				// Check loaded relationships
				expect(user.isRelationshipLoaded("posts")).toBeTrue();

				// Verify posts are populated
				var scope = user.getVariablesScope();
				expect(scope.loadedRelationships.posts).toBeArray();
				expect(arrayLen(scope.loadedRelationships.posts)).toBe(2);
			});

		});
	}

}
