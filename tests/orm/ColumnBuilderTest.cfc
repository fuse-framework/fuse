component extends="testbox.system.BaseSpec" {

	function run() {
		describe("ColumnBuilder component", function() {

			it("should initialize with column name, type, and datasource", function() {
				var cb = new fuse.orm.ColumnBuilder("email", "VARCHAR(255)", "testDS");

				expect(cb).toBeInstanceOf("fuse.orm.ColumnBuilder");
			});

			it("should store column definition state", function() {
				var cb = new fuse.orm.ColumnBuilder("id", "BIGINT", "testDS");

				var sql = cb.toSQL();

				expect(sql).toBeString();
				expect(sql).toInclude("BIGINT");
			});

			it("should chain modifier methods correctly", function() {
				var cb = new fuse.orm.ColumnBuilder("email", "VARCHAR(255)", "testDS");

				var result = cb.notNull().unique();

				expect(result).toBeInstanceOf("fuse.orm.ColumnBuilder");
			});

			it("should generate SQL fragment with NOT NULL constraint", function() {
				var cb = new fuse.orm.ColumnBuilder("email", "VARCHAR(255)", "testDS");

				var sql = cb.notNull().toSQL();

				expect(sql).toInclude("VARCHAR(255)");
				expect(sql).toInclude("NOT NULL");
			});

			it("should generate SQL fragment with UNIQUE constraint", function() {
				var cb = new fuse.orm.ColumnBuilder("email", "VARCHAR(255)", "testDS");

				var sql = cb.unique().toSQL();

				expect(sql).toInclude("UNIQUE");
			});

			it("should generate SQL fragment with default value", function() {
				var cb = new fuse.orm.ColumnBuilder("status", "VARCHAR(50)", "testDS");

				var sql = cb.default("active").toSQL();

				expect(sql).toInclude("DEFAULT");
				expect(sql).toInclude("'active'");
			});

			it("should chain multiple modifiers", function() {
				var cb = new fuse.orm.ColumnBuilder("email", "VARCHAR(255)", "testDS");

				var sql = cb.notNull().unique().default("test@example.com").toSQL();

				expect(sql).toInclude("VARCHAR(255)");
				expect(sql).toInclude("NOT NULL");
				expect(sql).toInclude("UNIQUE");
				expect(sql).toInclude("DEFAULT");
			});

			it("should properly quote string default values", function() {
				var cb = new fuse.orm.ColumnBuilder("status", "VARCHAR(50)", "testDS");

				var sql = cb.default("active").toSQL();

				expect(sql).toInclude("DEFAULT 'active'");
			});

		});
	}

}
