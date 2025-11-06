component extends="testbox.system.BaseSpec" {

	function run() {
		describe("ActiveRecord validation and callback DSL", function() {

			beforeEach(function() {
				variables.datasource = "testdb";
			});

			it("should register validations via validates() DSL", function() {
				var model = new tests.fixtures.User(variables.datasource);

				// Register validations
				model.validates("email", {required: true, email: true});
				model.validates("name", {required: true, length: {min: 3}});

				// Verify validations stored in variables scope
				var validations = model.getVariablesScope().validations;
				expect(validations).toHaveKey("email");
				expect(validations).toHaveKey("name");
				expect(arrayLen(validations.email)).toBe(2);
				expect(arrayLen(validations.name)).toBe(2);

				// Check structure of validation configs
				expect(validations.email[1].type).toBe("required");
				expect(validations.email[2].type).toBe("email");
				expect(validations.name[1].type).toBe("required");
				expect(validations.name[2].type).toBe("length");
			});

			it("should register callbacks via callback DSL methods", function() {
				var model = new tests.fixtures.User(variables.datasource);

				// Register callbacks
				model.beforeSave("updateTimestamp");
				model.afterSave("logSaveEvent");
				model.beforeCreate("setDefaults");

				// Verify callbacks delegated to CallbackManager
				var callbackManager = model.getVariablesScope().callbackManager;
				var callbacks = callbackManager.getCallbacks();

				expect(arrayLen(callbacks.beforeSave)).toBe(1);
				expect(callbacks.beforeSave[1]).toBe("updateTimestamp");
				expect(arrayLen(callbacks.afterSave)).toBe(1);
				expect(callbacks.afterSave[1]).toBe("logSaveEvent");
				expect(arrayLen(callbacks.beforeCreate)).toBe(1);
				expect(callbacks.beforeCreate[1]).toBe("setDefaults");
			});

			it("should populate errors via isValid() method", function() {
				var model = new tests.fixtures.User(variables.datasource);
				model.validates("email", {required: true});

				// Leave email empty
				var result = model.isValid();

				expect(result).toBeFalse();
				expect(model.hasErrors()).toBeTrue();
				expect(model.getErrors()).toHaveKey("email");
			});

			it("should return true from isValid() when valid", function() {
				var model = new tests.fixtures.User(variables.datasource);
				model.validates("email", {email: true});
				model.email = "test@example.com";

				var result = model.isValid();

				expect(result).toBeTrue();
				expect(model.hasErrors()).toBeFalse();
			});

			it("should return errors struct from getErrors()", function() {
				var model = new tests.fixtures.User(variables.datasource);
				model.validates("email", {required: true});
				model.validates("name", {required: true});

				// Trigger validation
				model.isValid();

				var errors = model.getErrors();
				expect(errors).toBeStruct();
				expect(errors).toHaveKey("email");
				expect(errors).toHaveKey("name");
				expect(errors.email).toBeArray();
				expect(errors.name).toBeArray();
			});

			it("should return field-specific errors from getErrors(fieldName)", function() {
				var model = new tests.fixtures.User(variables.datasource);
				model.validates("email", {required: true, email: true});
				model.email = "invalid";

				model.isValid();

				var emailErrors = model.getErrors("email");
				expect(emailErrors).toBeArray();
				expect(arrayLen(emailErrors)).toBeGTE(1);
			});

			it("should return empty array for field with no errors", function() {
				var model = new tests.fixtures.User(variables.datasource);
				model.validates("email", {email: true});
				model.email = "valid@example.com";

				model.isValid();

				var emailErrors = model.getErrors("email");
				expect(emailErrors).toBeArray();
				expect(arrayLen(emailErrors)).toBe(0);
			});

			it("should clear errors on subsequent isValid() call", function() {
				var model = new tests.fixtures.User(variables.datasource);
				model.validates("email", {required: true});

				// First validation - fail
				model.isValid();
				expect(model.hasErrors()).toBeTrue();

				// Fix the issue
				model.email = "test@example.com";
				model.isValid();

				// Errors should be cleared
				expect(model.hasErrors()).toBeFalse();
			});

		});
	}

}
