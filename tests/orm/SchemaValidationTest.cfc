component extends="testbox.system.BaseSpec" {

	function run() {
		describe("Schema validation and error handling", function() {

			beforeEach(function() {
				variables.testDatasource = "test_fuse";
			});

			it("should validate table names contain only valid characters", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				expect(function() {
					schema.create("users-table", function(table) {
						table.id();
					});
				}).toThrow(type: "Schema.InvalidDefinition");
			});

			it("should validate column names contain only valid characters", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				expect(function() {
					schema.create("users", function(table) {
						table.string("email-address");
					});
				}).toThrow(type: "Schema.InvalidDefinition");
			});

			it("should throw Schema.ExecutionError on SQL execution failure", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				// Try to create a table with invalid SQL
				expect(function() {
					schema.create("test_table", function(table) {
						// Force an error by creating duplicate primary keys
						table.id();
						var col = new fuse.orm.ColumnBuilder("id", "BIGINT PRIMARY KEY", variables.testDatasource);
						arrayAppend(table.getColumns(), col);
					});
				}).toThrow(type: "Schema.ExecutionError");
			});

			it("should validate foreign key references are defined", function() {
				var table = new fuse.orm.TableBuilder("posts", variables.testDatasource, "create");

				expect(function() {
					var fk = table.foreignKey("user_id");
					// Don't call references() - should fail validation
					fk.toSQL();
				}).toThrow(type: "Schema.InvalidDefinition");
			});

			it("should validate foreign key actions are valid", function() {
				var fk = new fuse.orm.ForeignKeyBuilder("user_id", "posts");
				fk.references("users", "id");

				expect(function() {
					fk.onDelete("INVALID_ACTION");
					fk.toSQL();
				}).toThrow(type: "Schema.InvalidDefinition");
			});

			it("should provide clear error messages on execution failure", function() {
				var schema = new fuse.orm.SchemaBuilder(variables.testDatasource);

				try {
					schema.create("test_invalid", function(table) {
						// Create invalid scenario
						table.id();
						queryExecute("INVALID SQL", {}, {datasource: variables.testDatasource});
					});
					fail("Should have thrown an error");
				} catch (any e) {
					expect(e.type).toInclude("Schema");
					expect(e.message).toBeString();
					expect(len(e.message)).toBeGT(0);
				}
			});

		});
	}

}
