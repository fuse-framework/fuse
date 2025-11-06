interface {

	/**
	 * Register services in the DI container
	 * No dependency resolution allowed in this phase
	 *
	 * @container DI container instance
	 */
	public void function register(required container);

	/**
	 * Boot the module and resolve dependencies
	 * All bindings are available in this phase
	 *
	 * @container DI container instance
	 */
	public void function boot(required container);

	/**
	 * Get module dependencies
	 *
	 * @return Array of module name strings this module depends on
	 */
	public array function getDependencies();

	/**
	 * Get module configuration
	 *
	 * @return Struct of configuration values to merge into global config
	 */
	public struct function getConfig();

}
