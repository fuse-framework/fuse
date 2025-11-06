component implements="fuse.core.IModule" {

	/**
	 * Register cache services in the DI container
	 */
	public void function register(required container) {
		// Bind ICacheProvider to RAMCacheProvider singleton
		arguments.container.singleton("ICacheProvider", function(c) {
			var config = c.resolve("config");
			return new fuse.cache.RAMCacheProvider(config);
		});
	}

	/**
	 * Boot the cache module
	 * Cache is ready immediately after registration, no boot actions needed
	 */
	public void function boot(required container) {
		// No-op: cache ready after registration
	}

	/**
	 * Get module dependencies
	 * Cache has no dependencies
	 */
	public array function getDependencies() {
		return [];
	}

	/**
	 * Get cache module configuration defaults
	 */
	public struct function getConfig() {
		return {
			cache: {
				defaultTTL: 0,
				enabled: true
			}
		};
	}

}
