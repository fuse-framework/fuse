component extends="testbox.system.BaseSpec" {

	function run() {
		describe("TableBuilder component", function() {

			it("should initialize with table name, datasource, and mode", function() {
				var tb = new fuse.orm.TableBuilder("users", "testDS", "create");

				expect(tb).toBeInstanceOf("fuse.orm.TableBuilder");
			});

			it("should create id column with primary key", function() {
				var tb = new fuse.orm.TableBuilder("users", "testDS", "create");

				var result = tb.id();

				expect(result).toBeInstanceOf("fuse.orm.ColumnBuilder");
			});

			it("should create string column with default length", function() {
				var tb = new fuse.orm.TableBuilder("users", "testDS", "create");

				var result = tb.string("email");

				expect(result).toBeInstanceOf("fuse.orm.ColumnBuilder");
			});

			it("should create integer column", function() {
				var tb = new fuse.orm.TableBuilder("users", "testDS", "create");

				var result = tb.integer("age");

				expect(result).toBeInstanceOf("fuse.orm.ColumnBuilder");
			});

			it("should track multiple columns", function() {
				var tb = new fuse.orm.TableBuilder("users", "testDS", "create");

				tb.id();
				tb.string("email");
				tb.integer("age");

				var sql = tb.toSQL();

				expect(sql).toInclude("CREATE TABLE users");
				expect(sql).toInclude("id");
				expect(sql).toInclude("email");
				expect(sql).toInclude("age");
			});

			it("should generate CREATE TABLE statement", function() {
				var tb = new fuse.orm.TableBuilder("users", "testDS", "create");

				tb.id();
				tb.string("email").notNull().unique();

				var sql = tb.toSQL();

				expect(sql).toInclude("CREATE TABLE users");
				expect(sql).toInclude("BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY");
				expect(sql).toInclude("VARCHAR(255)");
				expect(sql).toInclude("NOT NULL");
				expect(sql).toInclude("UNIQUE");
			});

			it("should generate ALTER TABLE statement for alter mode", function() {
				var tb = new fuse.orm.TableBuilder("users", "testDS", "alter");

				tb.string("phone");

				var sql = tb.toSQL();

				expect(sql).toInclude("ALTER TABLE users");
				expect(sql).toInclude("ADD COLUMN");
			});

			it("should track indexes", function() {
				var tb = new fuse.orm.TableBuilder("users", "testDS", "create");

				tb.id();
				tb.string("email");
				tb.index("email");

				var sql = tb.toSQL();

				expect(sql).toInclude("INDEX idx_users_email");
			});

		});
	}

}
