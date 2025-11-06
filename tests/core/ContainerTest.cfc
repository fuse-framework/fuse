component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		variables.container = new fuse.core.Container();
	}

	function run() {
		describe("Container basics", function() {

			beforeEach(function() {
				variables.container = new fuse.core.Container();
			});

			it("should resolve singleton binding and cache instance", function() {
				container.singleton("testService", "tests.fixtures.SimpleService");

				var instance1 = container.resolve("testService");
				var instance2 = container.resolve("testService");

				expect(instance1).toBe(instance2);
			});

			it("should resolve transient binding and create new instances", function() {
				container.bind("testService", "tests.fixtures.SimpleService");

				var instance1 = container.resolve("testService");
				var instance2 = container.resolve("testService");

				expect(instance1.getInstanceId()).notToBe(instance2.getInstanceId());
			});

			it("should resolve constructor injection with dependencies", function() {
				container.singleton("logger", "tests.fixtures.Logger");
				container.singleton("database", "tests.fixtures.Database");
				container.singleton("userService", "tests.fixtures.UserService");

				var userService = container.resolve("userService");

				expect(userService.getLogger()).toBeInstanceOf("tests.fixtures.Logger");
				expect(userService.getDatabase()).toBeInstanceOf("tests.fixtures.Database");
			});

			it("should resolve property injection via inject metadata", function() {
				container.singleton("logger", "tests.fixtures.Logger");
				container.singleton("orderService", "tests.fixtures.OrderService");

				var orderService = container.resolve("orderService");

				expect(orderService.getLogger()).toBeInstanceOf("tests.fixtures.Logger");
			});

			it("should detect circular dependencies", function() {
				container.singleton("serviceA", "tests.fixtures.CircularA");
				container.singleton("serviceB", "tests.fixtures.CircularB");

				expect(function() {
					container.resolve("serviceA");
				}).toThrow();
			});

			it("should throw error for missing dependency", function() {
				container.singleton("userService", "tests.fixtures.UserService");

				expect(function() {
					container.resolve("userService");
				}).toThrow(regex="logger|database");
			});

			it("should support closure-based bindings", function() {
				var counter = 0;
				container.singleton("closureService", function(c) {
					counter++;
					return new tests.fixtures.SimpleService();
				});

				var instance1 = container.resolve("closureService");
				var instance2 = container.resolve("closureService");

				expect(counter).toBe(1);
				expect(instance1).toBe(instance2);
			});

			it("should pass container to closure factories", function() {
				container.singleton("logger", "tests.fixtures.Logger");
				container.singleton("complexService", function(c) {
					var logger = c.resolve("logger");
					var service = new tests.fixtures.SimpleService();
					service.setLogger(logger);
					return service;
				});

				var service = container.resolve("complexService");

				expect(service.getLogger()).toBeInstanceOf("tests.fixtures.Logger");
			});

		});
	}

}
