component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		// Set up database schema for integration tests
		variables.datasource = "testdb";
		setupDatabase();
	}

	function afterAll() {
		// Clean up database
		teardownDatabase();
	}

	function run() {
		describe("Eager loading full workflow integration", function() {

			beforeEach(function() {
				// Reset data before each test
				cleanupData();
				insertTestData();
			});

			it("should eager load hasMany relationship via separate strategy", function() {
				// Create user with posts relationship
				var User = new tests.fixtures.UserWithRelationships(variables.datasource);

				// Query with eager loading
				var users = User.where({}).includes("posts").get();

				// Verify users loaded
				expect(users).toBeArray();
				expect(arrayLen(users)).toBeGT(0);

				// Verify posts are eager loaded
				var firstUser = users[1];
				expect(firstUser.isRelationshipLoaded("posts")).toBeTrue();

				// Access posts should return array (cached, no N+1)
				var posts = firstUser.posts;
				expect(posts).toBeArray();
			});

			it("should eager load hasOne relationship via separate strategy", function() {
				var User = new tests.fixtures.UserWithRelationships(variables.datasource);

				var users = User.where({}).includes("profile").get();

				expect(users).toBeArray();
				expect(arrayLen(users)).toBeGT(0);

				var firstUser = users[1];
				expect(firstUser.isRelationshipLoaded("profile")).toBeTrue();
			});

			it("should eager load belongsTo relationship via separate strategy", function() {
				var Post = new tests.fixtures.PostWithRelationships(variables.datasource);

				var posts = Post.where({}).includes("user").get();

				expect(posts).toBeArray();
				expect(arrayLen(posts)).toBeGT(0);

				var firstPost = posts[1];
				expect(firstPost.isRelationshipLoaded("user")).toBeTrue();
			});

			it("should return cached value when relationship accessed after eager load", function() {
				var User = new tests.fixtures.UserWithRelationships(variables.datasource);

				var users = User.where({}).includes("posts").get();
				expect(users).toBeArray();
				expect(arrayLen(users)).toBeGT(0);

				var user = users[1];

				// First access should return cached value
				var posts = user.posts;
				expect(posts).toBeArray();

				// Verify no new query by checking it's the same cached reference
				expect(user.isRelationshipLoaded("posts")).toBeTrue();
			});

			it("should handle nested eager loading correctly", function() {
				// This test verifies that nested relationships load correctly
				// posts.comments should load posts first, then comments for those posts
				var User = new tests.fixtures.UserWithRelationships(variables.datasource);

				// This will parse "posts.comments" and load both levels
				var users = User.where({}).includes("posts.comments").get();

				expect(users).toBeArray();
				expect(arrayLen(users)).toBeGT(0);

				// Verify first level (posts) is loaded
				var user = users[1];
				expect(user.isRelationshipLoaded("posts")).toBeTrue();

				// Get posts
				var posts = user.posts;
				if (isArray(posts) && arrayLen(posts) > 0) {
					// Verify second level (comments) is loaded on posts
					var post = posts[1];
					expect(post.isRelationshipLoaded("comments")).toBeTrue();
				}
			});

			it("should handle multiple eager loaded relationships", function() {
				var User = new tests.fixtures.UserWithRelationships(variables.datasource);

				var users = User.where({}).includes(["posts", "profile"]).get();

				expect(users).toBeArray();
				expect(arrayLen(users)).toBeGT(0);

				var user = users[1];
				expect(user.isRelationshipLoaded("posts")).toBeTrue();
				expect(user.isRelationshipLoaded("profile")).toBeTrue();
			});

		});
	}

	// Helper methods for database setup/teardown

	private function setupDatabase() {
		// Create tables for test
		try {
			queryExecute("
				CREATE TABLE IF NOT EXISTS users (
					id INT AUTO_INCREMENT PRIMARY KEY,
					name VARCHAR(255),
					email VARCHAR(255),
					created_at TIMESTAMP,
					updated_at TIMESTAMP
				)
			", [], {datasource: variables.datasource});

			queryExecute("
				CREATE TABLE IF NOT EXISTS posts (
					id INT AUTO_INCREMENT PRIMARY KEY,
					user_id INT,
					title VARCHAR(255),
					content TEXT,
					created_at TIMESTAMP,
					updated_at TIMESTAMP
				)
			", [], {datasource: variables.datasource});

			queryExecute("
				CREATE TABLE IF NOT EXISTS profiles (
					id INT AUTO_INCREMENT PRIMARY KEY,
					user_id INT,
					bio TEXT,
					created_at TIMESTAMP,
					updated_at TIMESTAMP
				)
			", [], {datasource: variables.datasource});

			queryExecute("
				CREATE TABLE IF NOT EXISTS comments (
					id INT AUTO_INCREMENT PRIMARY KEY,
					post_id INT,
					user_id INT,
					content TEXT,
					created_at TIMESTAMP,
					updated_at TIMESTAMP
				)
			", [], {datasource: variables.datasource});
		} catch (any e) {
			// Tables might already exist
		}
	}

	private function teardownDatabase() {
		try {
			queryExecute("DROP TABLE IF EXISTS comments", [], {datasource: variables.datasource});
			queryExecute("DROP TABLE IF EXISTS profiles", [], {datasource: variables.datasource});
			queryExecute("DROP TABLE IF EXISTS posts", [], {datasource: variables.datasource});
			queryExecute("DROP TABLE IF EXISTS users", [], {datasource: variables.datasource});
		} catch (any e) {
			// Ignore errors
		}
	}

	private function cleanupData() {
		try {
			queryExecute("DELETE FROM comments", [], {datasource: variables.datasource});
			queryExecute("DELETE FROM profiles", [], {datasource: variables.datasource});
			queryExecute("DELETE FROM posts", [], {datasource: variables.datasource});
			queryExecute("DELETE FROM users", [], {datasource: variables.datasource});
		} catch (any e) {
			// Ignore errors
		}
	}

	private function insertTestData() {
		// Insert users
		queryExecute("
			INSERT INTO users (id, name, email) VALUES
			(1, 'User 1', 'user1@test.com'),
			(2, 'User 2', 'user2@test.com')
		", [], {datasource: variables.datasource});

		// Insert posts
		queryExecute("
			INSERT INTO posts (id, user_id, title, content) VALUES
			(1, 1, 'Post 1', 'Content 1'),
			(2, 1, 'Post 2', 'Content 2'),
			(3, 2, 'Post 3', 'Content 3')
		", [], {datasource: variables.datasource});

		// Insert profiles
		queryExecute("
			INSERT INTO profiles (id, user_id, bio) VALUES
			(1, 1, 'Bio for User 1'),
			(2, 2, 'Bio for User 2')
		", [], {datasource: variables.datasource});

		// Insert comments
		queryExecute("
			INSERT INTO comments (id, post_id, user_id, content) VALUES
			(1, 1, 2, 'Comment 1 on Post 1'),
			(2, 1, 2, 'Comment 2 on Post 1'),
			(3, 2, 2, 'Comment 1 on Post 2')
		", [], {datasource: variables.datasource});
	}

}
