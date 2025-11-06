component extends="testbox.system.BaseSpec" {

	function run() {
		describe("SchemaBuilder component", function() {

			beforeEach(function() {
				variables.testDatasource = "test_fuse";
			});

			it("should initialize with datasource", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				expect(schema).toBeInstanceOf("fuse.orm.SchemaBuilder");
			});

			it("should have create method", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				expect(schema).toHaveKey("create");
			});

			it("should have dropIfExists method", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				expect(schema).toHaveKey("dropIfExists");
			});

			it("should have table method", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				expect(schema).toHaveKey("table");
			});

			it("should have rename method", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				expect(schema).toHaveKey("rename");
			});

			it("should have createIfNotExists method", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				expect(schema).toHaveKey("createIfNotExists");
			});

			it("should have drop method", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				expect(schema).toHaveKey("drop");
			});

		});
	}

}
