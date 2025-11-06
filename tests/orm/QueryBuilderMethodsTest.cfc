component extends="testbox.system.BaseSpec" {

	function run() {
		describe("QueryBuilder builder methods", function() {

			it("should accept select with comma-separated string", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.select("id, name, email");

				var result = qb.toSQL("users");
				expect(result.sql).toInclude("SELECT id, name, email");
			});

			it("should accept select with array", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.select(["id", "name"]);

				var result = qb.toSQL("users");
				expect(result.sql).toInclude("SELECT id, name");
			});

			it("should append multiple select calls", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.select("id").select("name");

				var result = qb.toSQL("users");
				expect(result.sql).toInclude("SELECT id, name");
			});

			it("should handle where with simple equality", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.where({active: true, status: "published"});

				var result = qb.toSQL("posts");
				// Check for both orderings and case insensitive
				var sql = ucase(result.sql);
				expect(sql).toInclude("WHERE");
				expect(sql).toInclude("ACTIVE = ?");
				expect(sql).toInclude("STATUS = ?");
				expect(sql).toInclude("AND");
				expect(result.bindings).toHaveLength(2);
			});

			it("should handle where with gte operator", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.where({age: {gte: 18}});

				var result = qb.toSQL("users");
				var sql = ucase(result.sql);
				expect(sql).toInclude("WHERE AGE >= ?");
				expect(result.bindings[1]).toBe(18);
			});

			it("should handle where with in operator", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.where({role: {in: ["admin", "moderator"]}});

				var result = qb.toSQL("users");
				var sql = ucase(result.sql);
				expect(sql).toInclude("WHERE ROLE IN (?, ?)");
				expect(result.bindings).toHaveLength(2);
				expect(result.bindings[1]).toBe("admin");
				expect(result.bindings[2]).toBe("moderator");
			});

			it("should handle where with isNull operator", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.where({deleted_at: {isNull: true}});

				var result = qb.toSQL("posts");
				var sql = ucase(result.sql);
				expect(sql).toInclude("WHERE DELETED_AT IS NULL");
				expect(result.bindings).toHaveLength(0);
			});

			it("should handle whereRaw with SQL and bindings", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.whereRaw("DATE(created_at) = ?", [createDate(2024, 1, 1)]);

				var result = qb.toSQL("posts");
				expect(result.sql).toInclude("WHERE (DATE(created_at) = ?)");
				expect(result.bindings).toHaveLength(1);
			});

			it("should handle whereRaw without bindings", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.whereRaw("price > cost * 1.5");

				var result = qb.toSQL("products");
				expect(result.sql).toInclude("WHERE (price > cost * 1.5)");
				expect(result.bindings).toHaveLength(0);
			});

			it("should handle orderBy with default ASC direction", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.orderBy("created_at");

				var result = qb.toSQL("posts");
				expect(result.sql).toInclude("ORDER BY created_at ASC");
			});

			it("should handle orderBy with DESC direction", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.orderBy("created_at", "DESC");

				var result = qb.toSQL("posts");
				expect(result.sql).toInclude("ORDER BY created_at DESC");
			});

			it("should handle groupBy with string", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.groupBy("category");

				var result = qb.toSQL("products");
				expect(result.sql).toInclude("GROUP BY category");
			});

			it("should handle groupBy with array", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.groupBy(["category", "brand"]);

				var result = qb.toSQL("products");
				expect(result.sql).toInclude("GROUP BY category, brand");
			});

			it("should handle limit", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.limit(10);

				var result = qb.toSQL("users");
				expect(result.sql).toInclude("LIMIT 10");
			});

			it("should handle offset", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.offset(20);

				var result = qb.toSQL("users");
				expect(result.sql).toInclude("OFFSET 20");
			});

			it("should handle join", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.join("posts", "users.id = posts.user_id");

				var result = qb.toSQL("users");
				expect(result.sql).toInclude("INNER JOIN posts ON users.id = posts.user_id");
			});

			it("should handle leftJoin", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.leftJoin("posts", "users.id = posts.user_id");

				var result = qb.toSQL("users");
				expect(result.sql).toInclude("LEFT OUTER JOIN posts ON users.id = posts.user_id");
			});

			it("should handle rightJoin", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");
				qb.rightJoin("posts", "users.id = posts.user_id");

				var result = qb.toSQL("users");
				expect(result.sql).toInclude("RIGHT OUTER JOIN posts ON users.id = posts.user_id");
			});

		});
	}

}
