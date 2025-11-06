component extends="testbox.system.BaseSpec" {

	function run() {
		describe("save/update/delete validation and callback integration", function() {

			beforeEach(function() {
				variables.datasource = "testdb";

				// Create test table with validation and callback tracking
				queryExecute("
					CREATE TABLE IF NOT EXISTS integration_test_models (
						id INT PRIMARY KEY AUTO_INCREMENT,
						name VARCHAR(100),
						email VARCHAR(100),
						status VARCHAR(50),
						created_at DATETIME,
						updated_at DATETIME
					)
				", [], {datasource: variables.datasource});

				// Clean table before each test
				queryExecute("DELETE FROM integration_test_models", [], {datasource: variables.datasource});
			});

			afterEach(function() {
				// Clean up
				queryExecute("DROP TABLE IF EXISTS integration_test_models", [], {datasource: variables.datasource});
			});

			it("should return true from save() on successful INSERT", function() {
				var model = new tests.fixtures.IntegrationTestModel(variables.datasource);
				model.name = "Test User";
				model.email = "test@example.com";

				var result = model.save();

				expect(result).toBeTrue();
				expect(model.getVariablesScope().isPersisted).toBeTrue();
			});

			it("should return false from save() when validation fails", function() {
				var model = new tests.fixtures.IntegrationTestModel(variables.datasource);
				// Model has validation requiring email
				// Leave email empty to trigger validation failure

				var result = model.save();

				expect(result).toBeFalse();
				expect(model.hasErrors()).toBeTrue();
				expect(model.getErrors()).toHaveKey("email");
				expect(model.getVariablesScope().isPersisted).toBeFalse();
			});

			it("should execute callbacks in correct order for INSERT", function() {
				var model = new tests.fixtures.IntegrationTestModel(variables.datasource);
				model.name = "Test User";
				model.email = "test@example.com";

				var result = model.save();

				expect(result).toBeTrue();

				var order = model.getCallbackOrder();
				expect(order).toBeArray();
				expect(arrayLen(order)).toBeGTE(4);

				// Verify callback execution order: beforeCreate -> beforeSave -> afterSave -> afterCreate
				expect(order[1]).toBe("beforeCreate");
				expect(order[2]).toBe("beforeSave");
				expect(order[3]).toBe("afterSave");
				expect(order[4]).toBe("afterCreate");
			});

			it("should return false from save() when beforeSave returns false", function() {
				var model = new tests.fixtures.IntegrationTestModel(variables.datasource);
				model.name = "Test User";
				model.email = "test@example.com";
				model.setHaltBeforeSave(true); // Trigger callback to return false

				var result = model.save();

				expect(result).toBeFalse();
				expect(model.getVariablesScope().isPersisted).toBeFalse();
			});

			it("should return true from save() on successful UPDATE", function() {
				var model = new tests.fixtures.IntegrationTestModel(variables.datasource);
				model.name = "Test User";
				model.email = "test@example.com";
				model.save();

				// Now update
				model.name = "Updated User";
				var result = model.save();

				expect(result).toBeTrue();
			});

			it("should execute callbacks in correct order for UPDATE", function() {
				var model = new tests.fixtures.IntegrationTestModel(variables.datasource);
				model.name = "Test User";
				model.email = "test@example.com";
				model.save();

				// Clear callback order and update
				model.clearCallbackOrder();
				model.name = "Updated User";
				var result = model.save();

				expect(result).toBeTrue();

				var order = model.getCallbackOrder();
				expect(order).toBeArray();
				expect(arrayLen(order)).toBe(2);

				// UPDATE path: beforeSave -> afterSave
				expect(order[1]).toBe("beforeSave");
				expect(order[2]).toBe("afterSave");
			});

			it("should return boolean from update() method", function() {
				var model = new tests.fixtures.IntegrationTestModel(variables.datasource);
				model.name = "Test User";
				model.email = "test@example.com";
				model.save();

				var result = model.update({name: "Updated User"});

				expect(result).toBeBoolean();
				expect(result).toBeTrue();
			});

			it("should return false from delete() when beforeDelete returns false", function() {
				var model = new tests.fixtures.IntegrationTestModel(variables.datasource);
				model.name = "Test User";
				model.email = "test@example.com";
				model.save();

				model.setHaltBeforeDelete(true);
				var result = model.delete();

				expect(result).toBeFalse();
				// Model should still be persisted since delete was halted
				expect(model.getVariablesScope().isPersisted).toBeTrue();
			});

		});
	}

}
