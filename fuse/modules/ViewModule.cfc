component implements="fuse.core.IModule" {

	/**
	 * Register view services in the DI container
	 */
	public void function register(required container) {
		// Bind ViewRenderer as singleton
		arguments.container.singleton("ViewRenderer", function(c) {
			var config = c.resolve("config");
			return new fuse.views.ViewRenderer(config);
		});
	}

	/**
	 * Boot the view module
	 * Register built-in helpers and interceptors
	 */
	public void function boot(required container) {
		var viewRenderer = arguments.container.resolve("ViewRenderer");
		var eventService = arguments.container.resolve("eventService");
		var router = arguments.container.resolve("router");

		// Register built-in helpers
		registerBuiltInHelpers(viewRenderer, router);

		// Register onBeforeRender interceptor
		registerRenderInterceptor(eventService, viewRenderer);
	}

	/**
	 * Get module dependencies
	 */
	public array function getDependencies() {
		return [];
	}

	/**
	 * Get view module configuration defaults
	 */
	public struct function getConfig() {
		return {
			views: {
				path: "/views",
				layoutPath: "/views/layouts",
				defaultLayout: "application"
			}
		};
	}

	// Private helper methods

	/**
	 * Register built-in helper functions
	 */
	private void function registerBuiltInHelpers(required viewRenderer, required router) {
		// h() - HTML escape helper
		arguments.viewRenderer.addHelper("h", function(required string str) {
			return htmlEditFormat(arguments.str);
		});

		// linkTo() - URL generation helper
		arguments.viewRenderer.addHelper("linkTo", function(required string routeName, struct params = {}) {
			return arguments.router.urlFor(arguments.routeName, arguments.params);
		});
	}

	/**
	 * Register onBeforeRender interceptor for view rendering
	 */
	private void function registerRenderInterceptor(required eventService, required viewRenderer) {
		// Capture viewRenderer in local scope for closure
		var renderer = arguments.viewRenderer;

		arguments.eventService.registerInterceptor("onBeforeRender", function(event) {
			// Extract view rendering data from event.result
			var result = event.result;

			// Skip rendering if no view specified
			if (!structKeyExists(result, "view") || !len(trim(result.view))) {
				return;
			}

			// Render the view with layout
			var renderedHtml = renderer.render(
				result.view,
				result.locals,
				result.layout
			);

			// Set response body
			event.response.body = renderedHtml;
		});
	}

}
