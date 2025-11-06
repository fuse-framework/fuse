component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		setupDatabase();
	}

	function afterAll() {
		teardownDatabase();
	}

	function run() {
		describe("ActiveRecord relationship query integration", function() {

			it("should query hasMany relationship and return array via get()", function() {
				// Create user and posts
				var userId = insertUser("Test User", "test@example.com");
				insertPost(userId, "Post 1", "published");
				insertPost(userId, "Post 2", "draft");

				// Query relationship
				var user = new tests.fixtures.UserWithRelationships("testdb");
				user.populate({id: userId, name: "Test User", email: "test@example.com"});

				var posts = user.posts().get();
				expect(arrayLen(posts)).toBe(2);
			});

			it("should query belongsTo relationship and return instance via first()", function() {
				// Create user and post
				var userId = insertUser("Author", "author@example.com");
				var postId = insertPost(userId, "Test Post", "published");

				// Query relationship
				var post = new tests.fixtures.PostWithRelationships("testdb");
				post.populate({id: postId, user_id: userId, title: "Test Post", status: "published"});

				var user = post.user().first();
				expect(user).notToBeNull();
				expect(user.name).toBe("Author");
			});

			it("should allow chaining where() before get()", function() {
				// Create user with multiple posts
				var userId = insertUser("Author", "author@example.com");
				insertPost(userId, "Published Post", "published");
				insertPost(userId, "Draft Post", "draft");

				// Query with chaining
				var user = new tests.fixtures.UserWithRelationships("testdb");
				user.populate({id: userId, name: "Author", email: "author@example.com"});

				var publishedPosts = user.posts().where({status: "published"}).get();
				expect(arrayLen(publishedPosts)).toBe(1);
				expect(publishedPosts[1].title).toBe("Published Post");
			});

			it("should return count via count() method", function() {
				// Create user with posts
				var userId = insertUser("Counter", "count@example.com");
				insertPost(userId, "Post 1", "published");
				insertPost(userId, "Post 2", "published");
				insertPost(userId, "Post 3", "draft");

				// Query count
				var user = new tests.fixtures.UserWithRelationships("testdb");
				user.populate({id: userId, name: "Counter", email: "count@example.com"});

				var totalCount = user.posts().count();
				expect(totalCount).toBe(3);

				var publishedCount = user.posts().where({status: "published"}).count();
				expect(publishedCount).toBe(2);
			});

		});
	}

	// Helper functions
	private function setupDatabase() {
		try {
			queryExecute("DROP TABLE IF EXISTS posts", [], {datasource: "testdb"});
			queryExecute("DROP TABLE IF EXISTS users", [], {datasource: "testdb"});

			queryExecute("
				CREATE TABLE users (
					id INTEGER PRIMARY KEY AUTO_INCREMENT,
					name VARCHAR(255),
					email VARCHAR(255)
				)
			", [], {datasource: "testdb"});

			queryExecute("
				CREATE TABLE posts (
					id INTEGER PRIMARY KEY AUTO_INCREMENT,
					user_id INTEGER,
					title VARCHAR(255),
					status VARCHAR(50)
				)
			", [], {datasource: "testdb"});
		} catch (any e) {
			// Tables may already exist
		}
	}

	private function teardownDatabase() {
		try {
			queryExecute("DROP TABLE IF EXISTS posts", [], {datasource: "testdb"});
			queryExecute("DROP TABLE IF EXISTS users", [], {datasource: "testdb"});
		} catch (any e) {
			// Ignore
		}
	}

	private numeric function insertUser(required string name, required string email) {
		var result = queryExecute("
			INSERT INTO users (name, email) VALUES (?, ?)
		", [arguments.name, arguments.email], {datasource: "testdb", result: "insertResult"});

		return insertResult.generatedKey;
	}

	private numeric function insertPost(required numeric userId, required string title, required string status) {
		var result = queryExecute("
			INSERT INTO posts (user_id, title, status) VALUES (?, ?, ?)
		", [arguments.userId, arguments.title, arguments.status], {datasource: "testdb", result: "insertResult"});

		return insertResult.generatedKey;
	}

}
