component extends="testbox.system.BaseSpec" {

	function run() {
		describe("QueryBuilder core structure", function() {

			it("should initialize with datasource parameter", function() {
				var qb = new fuse.orm.QueryBuilder("myDatasource");

				expect(qb).toBeInstanceOf("fuse.orm.QueryBuilder");
			});

			it("should initialize internal state arrays", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");

				// Access internal state via toSQL to verify initialization
				var result = qb.toSQL("users");

				expect(result).toBeStruct();
				expect(result).toHaveKey("sql");
				expect(result).toHaveKey("bindings");
				expect(result.bindings).toBeArray();
			});

			it("should return this from init for chaining", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");

				// init() already called by new, verify it returns this
				expect(qb).toBeInstanceOf("fuse.orm.QueryBuilder");
			});

			it("should generate basic SQL structure with toSQL", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");

				var result = qb.toSQL("users");

				expect(result.sql).toInclude("SELECT");
				expect(result.sql).toInclude("FROM users");
			});

			it("should default to SELECT * when no columns specified", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");

				var result = qb.toSQL("users");

				expect(result.sql).toInclude("SELECT *");
			});

			it("should return empty bindings array when no conditions", function() {
				var qb = new fuse.orm.QueryBuilder("testDS");

				var result = qb.toSQL("users");

				expect(result.bindings).toBeArray();
				expect(result.bindings).toHaveLength(0);
			});

		});
	}

}
