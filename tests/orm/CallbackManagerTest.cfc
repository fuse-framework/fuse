component extends="testbox.system.BaseSpec" {

	function run() {
		describe("CallbackManager component callback execution", function() {

			beforeEach(function() {
				callbackManager = new fuse.orm.CallbackManager();
			});

			it("should register callback and append to array", function() {
				callbackManager.registerCallback("beforeSave", "myBeforeSave");

				var callbacks = callbackManager.getCallbacks();
				expect(callbacks.beforeSave).toBeArray();
				expect(arrayLen(callbacks.beforeSave)).toBe(1);
				expect(callbacks.beforeSave[1]).toBe("myBeforeSave");
			});

			it("should throw exception for invalid callback point", function() {
				expect(function() {
					callbackManager.registerCallback("invalidPoint", "someMethod");
				}).toThrow(type="InvalidCallbackPointException");
			});

			it("should execute callbacks in registration order", function() {
				var model = new tests.fixtures.CallbackTestModel();

				callbackManager.registerCallback("beforeSave", "firstCallback");
				callbackManager.registerCallback("beforeSave", "secondCallback");

				var result = callbackManager.executeCallbacks(model, "beforeSave");

				expect(result).toBeTrue();
				var executionOrder = model.getExecutionOrder();
				expect(executionOrder).toBeArray();
				expect(arrayLen(executionOrder)).toBe(2);
				expect(executionOrder[1]).toBe("first");
				expect(executionOrder[2]).toBe("second");
			});

			it("should short-circuit when callback returns false", function() {
				var model = new tests.fixtures.CallbackTestModel();

				callbackManager.registerCallback("beforeSave", "firstCallback");
				callbackManager.registerCallback("beforeSave", "returnFalseCallback");
				callbackManager.registerCallback("beforeSave", "thirdCallback");

				var result = callbackManager.executeCallbacks(model, "beforeSave");

				expect(result).toBeFalse();
				var executionOrder = model.getExecutionOrder();
				expect(arrayLen(executionOrder)).toBe(2);
				expect(executionOrder[1]).toBe("first");
				expect(executionOrder[2]).toBe("returnFalse");
				// thirdCallback should NOT have executed
			});

			it("should return true when all callbacks pass", function() {
				var model = new tests.fixtures.CallbackTestModel();

				callbackManager.registerCallback("afterSave", "firstCallback");
				callbackManager.registerCallback("afterSave", "secondCallback");

				var result = callbackManager.executeCallbacks(model, "afterSave");

				expect(result).toBeTrue();
			});

			it("should handle callback point with no registered callbacks", function() {
				var model = new tests.fixtures.CallbackTestModel();

				var result = callbackManager.executeCallbacks(model, "beforeDelete");

				expect(result).toBeTrue();
			});

			it("should support all 6 callback points", function() {
				callbackManager.registerCallback("beforeSave", "method1");
				callbackManager.registerCallback("afterSave", "method2");
				callbackManager.registerCallback("beforeCreate", "method3");
				callbackManager.registerCallback("afterCreate", "method4");
				callbackManager.registerCallback("beforeDelete", "method5");
				callbackManager.registerCallback("afterDelete", "method6");

				var callbacks = callbackManager.getCallbacks();
				expect(arrayLen(callbacks.beforeSave)).toBe(1);
				expect(arrayLen(callbacks.afterSave)).toBe(1);
				expect(arrayLen(callbacks.beforeCreate)).toBe(1);
				expect(arrayLen(callbacks.afterCreate)).toBe(1);
				expect(arrayLen(callbacks.beforeDelete)).toBe(1);
				expect(arrayLen(callbacks.afterDelete)).toBe(1);
			});

		});
	}

}
