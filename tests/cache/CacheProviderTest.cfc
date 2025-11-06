component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		variables.container = new fuse.core.Container();
	}

	function run() {
		describe("Cache provider operations", function() {

			beforeEach(function() {
				variables.container = new fuse.core.Container();

				// Bind config first (required by CacheModule)
				container.singleton("config", function(c) {
					return {
						cache: {
							defaultTTL: 0,
							enabled: true
						}
					};
				});

				// Register cache module
				var cacheModule = new fuse.modules.CacheModule();
				cacheModule.register(container);
				cacheModule.boot(container);
				variables.cache = container.resolve("ICacheProvider");
			});

			it("should set and get cached values", function() {
				cache.set("testKey", "testValue", 0);
				var result = cache.get("testKey");

				expect(result).toBe("testValue");
			});

			it("should return null for non-existent keys", function() {
				var result = cache.get("nonExistentKey");

				expect(isNull(result)).toBeTrue();
			});

			it("should check if key exists using has()", function() {
				cache.set("existingKey", "value", 0);

				expect(cache.has("existingKey")).toBeTrue();
				expect(cache.has("missingKey")).toBeFalse();
			});

			it("should expire items after TTL seconds", function() {
				cache.set("expireKey", "value", 1);

				// Should exist immediately
				expect(cache.get("expireKey")).toBe("value");

				// Wait for expiration (add buffer for timing)
				sleep(1500);

				// Should be null after expiration
				var expiredValue = cache.get("expireKey");
				expect(isNull(expiredValue)).toBeTrue();
			});

			it("should delete cached items", function() {
				cache.set("deleteKey", "value", 0);
				expect(cache.has("deleteKey")).toBeTrue();

				cache.delete("deleteKey");

				expect(cache.has("deleteKey")).toBeFalse();
			});

			it("should clear all cached items", function() {
				cache.set("key1", "value1", 0);
				cache.set("key2", "value2", 0);

				expect(cache.has("key1")).toBeTrue();
				expect(cache.has("key2")).toBeTrue();

				cache.clear();

				expect(cache.has("key1")).toBeFalse();
				expect(cache.has("key2")).toBeFalse();
			});

			it("should handle zero TTL as no expiration", function() {
				cache.set("neverExpire", "value", 0);

				// Wait a moment
				sleep(100);

				// Should still exist
				expect(cache.get("neverExpire")).toBe("value");
			});

			it("should be thread-safe for concurrent access", function() {
				var local.iterations = 10;
				var local.threadResults = {};

				// Spawn threads that all try to set/get the same key
				for (var i = 1; i <= 5; i++) {
					thread action="run" name="cacheThread#i#" i="#i#" cache="#cache#" iterations="#local.iterations#" {
						for (var j = 1; j <= attributes.iterations; j++) {
							attributes.cache.set("sharedKey", "thread#attributes.i#-value#j#", 0);
							var val = attributes.cache.get("sharedKey");
						}
					}
				}

				// Wait for all threads
				thread action="join" name="cacheThread1,cacheThread2,cacheThread3,cacheThread4,cacheThread5";

				// Should have a value (any value is fine, just shouldn't error)
				var local.finalValue = cache.get("sharedKey");
				expect(local.finalValue).notToBeNull();
			});

		});
	}

}
