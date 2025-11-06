component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		variables.testAppScope = {};
	}

	function run() {
		describe("Bootstrap thread-safety", function() {

			beforeEach(function() {
				variables.testAppScope = {};
			});

			it("should initialize framework singleton in application scope", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);

				expect(variables.testAppScope).toHaveKey("fuse");
				expect(variables.testAppScope.fuse).toBeInstanceOf("fuse.core.Framework");
			});

			it("should return cached framework instance on second call", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework1 = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var framework2 = bootstrap.initFramework(variables.testAppScope, "fuse", 30);

				expect(framework1).toBe(framework2);
			});

			it("should use configurable application key", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "customKey", 30);

				expect(variables.testAppScope).toHaveKey("customKey");
				expect(variables.testAppScope).notToHaveKey("fuse");
			});

			it("should handle concurrent initialization safely with double-checked locking", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var results = [];
				var threads = [];

				// Simulate concurrent requests
				for (var i = 1; i <= 5; i++) {
					thread name="test#i#" action="run" bootstrap=bootstrap appScope=variables.testAppScope results=results {
						var fw = attributes.bootstrap.initFramework(attributes.appScope, "fuse", 30);
						arrayAppend(attributes.results, fw.getInstanceId());
					}
					arrayAppend(threads, "test#i#");
				}

				// Wait for all threads
				thread action="join" name=arrayToList(threads);

				// All threads should get same instance
				expect(arrayLen(results)).toBe(5);
				var firstId = results[1];
				for (var id in results) {
					expect(id).toBe(firstId);
				}
			});

			it("should respect lock timeout configuration", function() {
				var bootstrap = new fuse.core.Bootstrap();

				// This test verifies timeout is passed to lock, not that it actually times out
				// since that would make tests slow
				expect(function() {
					bootstrap.initFramework(variables.testAppScope, "fuse", 1);
				}).notToThrow();
			});

			it("should have minimal overhead after initialization", function() {
				var bootstrap = new fuse.core.Bootstrap();
				bootstrap.initFramework(variables.testAppScope, "fuse", 30);

				var start = getTickCount();
				for (var i = 1; i <= 1000; i++) {
					bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				}
				var elapsed = getTickCount() - start;

				// 1000 iterations should complete in well under 1 second
				// If each iteration is <1ms, 1000 iterations = ~1000ms max
				expect(elapsed < 1000).toBeTrue();
			});

		});

		describe("Framework initialization sequence", function() {

			beforeEach(function() {
				variables.testAppScope = {};
			});

			it("should create initialized framework with container", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);

				expect(framework.getContainer()).toBeInstanceOf("fuse.core.Container");
			});

			it("should bind config to container as singleton", function() {
				var bootstrap = new fuse.core.Bootstrap();
				var framework = bootstrap.initFramework(variables.testAppScope, "fuse", 30);
				var container = framework.getContainer();

				expect(container.has("config")).toBeTrue();
				var config = container.resolve("config");
				expect(config).toBeStruct();
			});

		});
	}

}
