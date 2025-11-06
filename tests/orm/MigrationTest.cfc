component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Migration and Migrator components", function() {

			beforeEach(function() {
				variables.testDatasource = "test_fuse";
			});

			it("should initialize Migration with datasource", function() {
				var migration = new fuse.orm.Migration(variables.testDatasource);

				expect(migration).toBeInstanceOf("fuse.orm.Migration");
			});

			it("should provide schema property", function() {
				var migration = new fuse.orm.Migration(variables.testDatasource);
				var schema = migration.getSchema();

				expect(schema).toBeInstanceOf("fuse.orm.SchemaBuilder");
			});

			it("should have up and down methods", function() {
				var migration = new fuse.orm.Migration(variables.testDatasource);

				expect(migration).toHaveKey("up");
				expect(migration).toHaveKey("down");
			});

			it("should initialize Migrator with datasource", function() {
				var migrator = new fuse.orm.Migrator(variables.testDatasource);

				expect(migrator).toBeInstanceOf("fuse.orm.Migrator");
			});

			it("should have migrate method", function() {
				var migrator = new fuse.orm.Migrator(variables.testDatasource);

				expect(migrator).toHaveKey("migrate");
			});

			it("should have rollback method", function() {
				var migrator = new fuse.orm.Migrator(variables.testDatasource);

				expect(migrator).toHaveKey("rollback");
			});

			it("should have status method", function() {
				var migrator = new fuse.orm.Migrator(variables.testDatasource);

				expect(migrator).toHaveKey("status");
			});

			it("should have reset method", function() {
				var migrator = new fuse.orm.Migrator(variables.testDatasource);

				expect(migrator).toHaveKey("reset");
			});

		});
	}

}
