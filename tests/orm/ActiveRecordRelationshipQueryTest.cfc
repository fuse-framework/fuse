component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		// Set up database tables for relationship testing
		setupDatabase();
	}

	function afterAll() {
		// Clean up database
		teardownDatabase();
	}

	function run() {
		describe("ActiveRecord relationship query resolution", function() {

			beforeEach(function() {
				variables.datasource = "testdb";
			});

			it("should return ModelBuilder when calling relationship method", function() {
				var user = createUserWithPosts();
				var result = user.posts();

				expect(result).toBeComponent();
				expect(getMetadata(result).name).toInclude("ModelBuilder");
			});

			it("should construct correct WHERE clause for belongsTo", function() {
				var post = createPostWithUser(userId=5);
				var builder = post.user();

				// Access WHERE clause through SQL generation
				var sql = builder.toSQL();
				expect(sql.sql).toInclude("user_id = ?");
				expect(sql.bindings[1]).toBe(5);
			});

			it("should construct correct WHERE clause for hasMany", function() {
				var user = createUser(id=10);
				var builder = user.posts();

				var sql = builder.toSQL();
				expect(sql.sql).toInclude("user_id = ?");
				expect(sql.bindings[1]).toBe(10);
			});

			it("should construct correct WHERE clause for hasOne", function() {
				var user = createUser(id=7);
				var builder = user.profile();

				var sql = builder.toSQL();
				expect(sql.sql).toInclude("user_id = ?");
				expect(sql.bindings[1]).toBe(7);
			});

			it("should enable query chaining on relationship", function() {
				var user = createUserWithPosts();
				var builder = user.posts().where({status: "published"}).orderBy("created_at DESC");

				expect(builder).toBeComponent();
				var sql = builder.toSQL();
				expect(sql.sql).toInclude("user_id = ?");
				expect(sql.sql).toInclude("status = ?");
				expect(sql.sql).toInclude("ORDER BY");
			});

			it("should fallthrough to getter if not a relationship", function() {
				var user = createUser();
				user.name = "Test User";

				// name is not a relationship, should act as getter
				var name = user.name;
				expect(name).toBe("Test User");
			});

			it("should fallthrough to setter if not a relationship", function() {
				var user = createUser();
				user.email = "test@example.com";

				var scope = user.getVariablesScope();
				expect(scope.attributes.email).toBe("test@example.com");
			});

		});
	}

	// Helper functions
	private function setupDatabase() {
		// Create test tables (simplified for relationship testing)
		try {
			queryExecute("DROP TABLE IF EXISTS posts", [], {datasource: "testdb"});
			queryExecute("DROP TABLE IF EXISTS users", [], {datasource: "testdb"});
			queryExecute("DROP TABLE IF EXISTS profiles", [], {datasource: "testdb"});

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

			queryExecute("
				CREATE TABLE profiles (
					id INTEGER PRIMARY KEY AUTO_INCREMENT,
					user_id INTEGER,
					bio TEXT
				)
			", [], {datasource: "testdb"});
		} catch (any e) {
			// Tables may already exist
		}
	}

	private function teardownDatabase() {
		try {
			queryExecute("DROP TABLE IF EXISTS posts", [], {datasource: "testdb"});
			queryExecute("DROP TABLE IF EXISTS profiles", [], {datasource: "testdb"});
			queryExecute("DROP TABLE IF EXISTS users", [], {datasource: "testdb"});
		} catch (any e) {
			// Ignore cleanup errors
		}
	}

	private function createUser(numeric id = 0) {
		var user = new tests.fixtures.UserWithRelationships("testdb");
		if (id > 0) {
			user.populate({id: id, name: "Test User", email: "test@example.com"});
		}
		return user;
	}

	private function createUserWithPosts() {
		var user = new tests.fixtures.UserWithRelationships("testdb");
		user.populate({id: 1, name: "Test User", email: "test@example.com"});
		return user;
	}

	private function createPostWithUser(required numeric userId) {
		var post = new tests.fixtures.PostWithRelationships("testdb");
		post.populate({id: 1, user_id: userId, title: "Test Post", status: "published"});
		return post;
	}

}
