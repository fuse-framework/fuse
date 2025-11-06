component extends="testbox.system.BaseSpec" {

	function run() {
		describe("ActiveRecord relationship definition", function() {

			beforeEach(function() {
				variables.datasource = "testdb";
			});

			it("should store hasMany relationship metadata", function() {
				var user = new tests.fixtures.User(variables.datasource);
				user.hasMany("posts");

				var scope = user.getVariablesScope();
				expect(scope).toHaveKey("relationships");
				expect(scope.relationships).toHaveKey("posts");
				expect(scope.relationships.posts.type).toBe("hasMany");
				expect(scope.relationships.posts.foreignKey).toBe("user_id");
				expect(scope.relationships.posts.className).toBe("Post");
			});

			it("should store belongsTo relationship metadata with correct foreign key", function() {
				var post = new tests.fixtures.Post(variables.datasource);
				post.belongsTo("user");

				var scope = post.getVariablesScope();
				expect(scope.relationships).toHaveKey("user");
				expect(scope.relationships.user.type).toBe("belongsTo");
				expect(scope.relationships.user.foreignKey).toBe("user_id");
				expect(scope.relationships.user.className).toBe("User");
			});

			it("should store hasOne relationship metadata", function() {
				var user = new tests.fixtures.User(variables.datasource);
				user.hasOne("profile");

				var scope = user.getVariablesScope();
				expect(scope.relationships).toHaveKey("profile");
				expect(scope.relationships.profile.type).toBe("hasOne");
				expect(scope.relationships.profile.foreignKey).toBe("user_id");
				expect(scope.relationships.profile.className).toBe("Profile");
			});

			it("should support foreignKey option override", function() {
				var post = new tests.fixtures.Post(variables.datasource);
				post.belongsTo("author", {foreignKey: "created_by_id"});

				var scope = post.getVariablesScope();
				expect(scope.relationships.author.foreignKey).toBe("created_by_id");
			});

			it("should support className option override", function() {
				var user = new tests.fixtures.User(variables.datasource);
				user.hasMany("articles", {className: "BlogPost"});

				var scope = user.getVariablesScope();
				expect(scope.relationships.articles.className).toBe("BlogPost");
			});

			it("should persist metadata across multiple instances", function() {
				var user1 = new tests.fixtures.UserWithPosts(variables.datasource);
				var user2 = new tests.fixtures.UserWithPosts(variables.datasource);

				var scope1 = user1.getVariablesScope();
				var scope2 = user2.getVariablesScope();

				expect(scope1.relationships).toHaveKey("posts");
				expect(scope2.relationships).toHaveKey("posts");
				expect(scope1.relationships.posts.type).toBe("hasMany");
				expect(scope2.relationships.posts.type).toBe("hasMany");
			});

			it("should infer className from camelCase relationship names", function() {
				var user = new tests.fixtures.User(variables.datasource);
				user.hasMany("blogPosts");

				var scope = user.getVariablesScope();
				expect(scope.relationships.blogPosts.className).toBe("BlogPost");
			});

			it("should return this for chaining", function() {
				var user = new tests.fixtures.User(variables.datasource);
				var result = user.hasMany("posts");

				expect(result).toBe(user);
			});

		});
	}

}
