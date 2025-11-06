/**
 * Pages Handler
 *
 * Example handler for static/informational pages.
 * Demonstrates urlFor helper usage and simple actions.
 */
component {

	public function init() {
		return this;
	}

	/**
	 * Home page (GET /)
	 *
	 * @return Struct response
	 */
	public struct function index() {
		return {
			success: true,
			action: "index",
			page: "home"
		};
	}

	/**
	 * About page (GET /pages/about)
	 *
	 * Demonstrates accessing urlFor helper from event context.
	 * In real app, urlFor would be injected via request scope or helper.
	 *
	 * @return Struct response
	 */
	public struct function about() {
		// In real implementation, urlFor would be available via:
		// - request.urlFor() injected by dispatcher
		// - this.urlFor() if set as property
		// - arguments.urlFor() if passed as param
		//
		// For this test, we check if available as property (injected by interceptor)
		var usersIndexUrl = "/users"; // Default if urlFor not available

		// Try to use urlFor if available (injected by interceptor in test)
		if (structKeyExists(this, "urlFor")) {
			usersIndexUrl = this.urlFor("users_index", {});
		}

		return {
			success: true,
			action: "about",
			page: "about",
			usersIndexUrl: usersIndexUrl
		};
	}

	/**
	 * Contact page (GET /pages/contact)
	 *
	 * @return String view name
	 */
	public string function contact() {
		return "pages/contact";
	}

	/**
	 * Static content with void return
	 * Demonstrates handler with no explicit return value
	 *
	 * @return void
	 */
	public void function static() {
		// Void return - framework would render default view
		// In this case: views/pages/static.cfm
	}

}
