component extends="testbox.system.BaseSpec" {

	function run() {
		describe("ModelBuilder extends QueryBuilder", function() {

			it("should extend QueryBuilder", function() {
				var mb = new fuse.orm.ModelBuilder("testDS", "users");

				expect(mb).toBeInstanceOf("fuse.orm.QueryBuilder");
				expect(mb).toBeInstanceOf("fuse.orm.ModelBuilder");
			});

			it("should accept datasource and tableName in init", function() {
				var mb = new fuse.orm.ModelBuilder("myDatasource", "posts");

				expect(mb).toBeInstanceOf("fuse.orm.ModelBuilder");
			});

			it("should store tableName for FROM clause", function() {
				var mb = new fuse.orm.ModelBuilder("testDS", "users");

				var result = mb.toSQL();

				expect(result.sql).toInclude("FROM users");
			});

			it("should inherit select method from QueryBuilder", function() {
				var mb = new fuse.orm.ModelBuilder("testDS", "users");

				mb.select("id, name");
				var result = mb.toSQL();

				expect(result.sql).toInclude("SELECT id, name");
				expect(result.sql).toInclude("FROM users");
			});

			it("should inherit where method from QueryBuilder", function() {
				var mb = new fuse.orm.ModelBuilder("testDS", "users");

				mb.where({active: true, status: "published"});
				var result = mb.toSQL();

				expect(result.sql).toInclude("WHERE");
				expect(result.sql).toInclude("active = ?");
				expect(result.sql).toInclude("status = ?");
				expect(result.bindings).toHaveLength(2);
			});

			it("should support method chaining", function() {
				var mb = new fuse.orm.ModelBuilder("testDS", "users");

				var chain = mb.select("id").where({active: true}).orderBy("name");

				expect(chain).toBeInstanceOf("fuse.orm.ModelBuilder");

				var result = chain.toSQL();
				expect(result.sql).toInclude("SELECT id");
				expect(result.sql).toInclude("WHERE active = ?");
				expect(result.sql).toInclude("ORDER BY name");
			});

			it("should inherit orderBy and limit methods", function() {
				var mb = new fuse.orm.ModelBuilder("testDS", "posts");

				mb.orderBy("created_at", "DESC").limit(10);
				var result = mb.toSQL();

				expect(result.sql).toInclude("ORDER BY created_at DESC");
				expect(result.sql).toInclude("LIMIT 10");
			});

			it("should inherit hash-based operator support", function() {
				var mb = new fuse.orm.ModelBuilder("testDS", "users");

				mb.where({age: {gte: 18}, role: {in: ["admin", "moderator"]}});
				var result = mb.toSQL();

				expect(result.sql).toInclude("age >= ?");
				expect(result.sql).toInclude("role IN (?, ?)");
				expect(result.bindings).toHaveLength(3);
			});

		});
	}

}
