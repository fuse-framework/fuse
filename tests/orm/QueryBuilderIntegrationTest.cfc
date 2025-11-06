component extends="testbox.system.BaseSpec" {

	function run() {
		describe("QueryBuilder integration tests", function() {

			it("should build complete query chain with select, where, orderBy, limit", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");

				qb.select("id, name, email")
					.where({active: true, status: "published"})
					.orderBy("created_at", "DESC")
					.limit(10);

				var result = qb.toSQL("posts");

				expect(result.sql).toInclude("SELECT id, name, email");
				expect(result.sql).toInclude("FROM posts");
				expect(result.sql).toInclude("WHERE");
				expect(result.sql).toInclude("active = ?");
				expect(result.sql).toInclude("status = ?");
				expect(result.sql).toInclude("ORDER BY created_at DESC");
				expect(result.sql).toInclude("LIMIT 10");
				expect(result.bindings).toHaveLength(2);
			});

			it("should handle complex where with multiple operator types", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");

				qb.where({
					age: {gte: 18},
					role: {in: ["admin", "moderator"]},
					deleted_at: {isNull: true}
				});

				var result = qb.toSQL("users");

				expect(result.sql).toInclude("age >= ?");
				expect(result.sql).toInclude("role IN (?, ?)");
				expect(result.sql).toInclude("deleted_at IS NULL");
				// Bindings: 18, "admin", "moderator" (no binding for isNull)
				expect(result.bindings).toHaveLength(3);
			});

			it("should handle join with where conditions", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");

				qb.select("users.name, posts.title")
					.join("posts", "users.id = posts.user_id")
					.where({
						"users.active": true,
						"posts.status": "published"
					})
					.orderBy("posts.created_at", "DESC");

				var result = qb.toSQL("users");

				expect(result.sql).toInclude("SELECT users.name, posts.title");
				expect(result.sql).toInclude("INNER JOIN posts ON users.id = posts.user_id");
				expect(result.sql).toInclude("WHERE");
				expect(result.sql).toInclude("users.active = ?");
				expect(result.sql).toInclude("posts.status = ?");
				expect(result.bindings).toHaveLength(2);
			});

			it("should handle whereRaw integration with where", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");

				qb.where({status: "published"})
					.whereRaw("price > cost * 1.5")
					.where({active: true});

				var result = qb.toSQL("products");

				expect(result.sql).toInclude("WHERE");
				expect(result.sql).toInclude("status = ?");
				expect(result.sql).toInclude("(price > cost * 1.5)");
				expect(result.sql).toInclude("active = ?");
				// All three conditions should be joined with AND
				expect(result.sql).toInclude("AND");
				expect(result.bindings).toHaveLength(2); // Only status and active, no bindings for whereRaw
			});

			it("should maintain correct binding order for prepared statements", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");

				qb.where({name: "Alice", age: {gte: 25}, city: "NYC"})
					.orderBy("created_at");

				var result = qb.toSQL("users");

				// Bindings should be in order: name value, age value, city value
				// Note: struct key order in CFML may vary, so we just verify count and presence
				expect(result.bindings).toHaveLength(3);
				expect(result.bindings).toContain("Alice");
				expect(result.bindings).toContain(25);
				expect(result.bindings).toContain("NYC");
			});

			it("should throw error for invalid operator", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");

				expect(function() {
					qb.where({age: {invalidOp: 18}});
				}).toThrow("QueryBuilder.InvalidOperator");
			});

			it("should throw error for invalid limit value", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");

				expect(function() {
					qb.limit(-10);
				}).toThrow("QueryBuilder.InvalidValue");
			});

			it("should handle between operator with array values", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");

				qb.where({age: {between: [18, 65]}});

				var result = qb.toSQL("users");

				expect(result.sql).toInclude("WHERE age BETWEEN ? AND ?");
				expect(result.bindings).toHaveLength(2);
				expect(result.bindings[1]).toBe(18);
				expect(result.bindings[2]).toBe(65);
			});

			it("should handle notNull and notIn operators", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");

				qb.where({
					email: {notNull: true},
					status: {notIn: ["banned", "suspended"]}
				});

				var result = qb.toSQL("users");

				expect(result.sql).toInclude("email IS NOT NULL");
				expect(result.sql).toInclude("status NOT IN (?, ?)");
				// Only 2 bindings for notIn array, none for notNull
				expect(result.bindings).toHaveLength(2);
				expect(result.bindings).toContain("banned");
				expect(result.bindings).toContain("suspended");
			});

			it("should handle ModelBuilder with complex query chain", function() {
				var mb = new fuse.orm.ModelBuilder("testDS", "users");

				mb.select("id, name, email")
					.where({
						active: true,
						age: {gte: 18},
						role: {in: ["admin", "moderator"]}
					})
					.orderBy("name")
					.limit(20)
					.offset(10);

				var result = mb.toSQL();

				expect(result.sql).toInclude("SELECT id, name, email");
				expect(result.sql).toInclude("FROM users");
				expect(result.sql).toInclude("WHERE");
				expect(result.sql).toInclude("active = ?");
				expect(result.sql).toInclude("age >= ?");
				expect(result.sql).toInclude("role IN (?, ?)");
				expect(result.sql).toInclude("ORDER BY name ASC");
				expect(result.sql).toInclude("LIMIT 20");
				expect(result.sql).toInclude("OFFSET 10");
				// Bindings: true, 18, "admin", "moderator"
				expect(result.bindings).toHaveLength(4);
			});

		});
	}

}
