/**
 * N1Detector - Detects and logs N+1 query problems
 *
 * Monitors relationship access patterns and logs warnings when relationships
 * are accessed via lazy loading after batch queries, helping developers
 * identify performance issues during development.
 *
 * USAGE EXAMPLE:
 *
 * Detect N+1 query:
 *     var detector = new fuse.orm.N1Detector();
 *     detector.detect("User", "posts", {isDevelopment: true});
 *     // Logs: "N+1 Query Detected: Accessed relationship 'posts' on User without eager loading..."
 *
 * Production mode (silent):
 *     detector.detect("User", "posts", {isDevelopment: false});
 *     // No logging in production
 *
 * Detection strategy:
 * - Only logs in development environment
 * - Triggered when relationship accessed without eager loading
 * - Provides actionable recommendation to use includes()
 */
component {

	/**
	 * Detect and log N+1 query pattern
	 *
	 * @param modelClass Name of the model class (e.g., "User")
	 * @param relationshipName Name of the relationship being accessed
	 * @param context Struct with environment info (isDevelopment, etc.)
	 */
	public void function detect(
		required string modelClass,
		required string relationshipName,
		struct context = {}
	) {
		// Only log in development environment
		var isDevelopment = structKeyExists(arguments.context, "isDevelopment")
			? arguments.context.isDevelopment
			: isDevEnvironment();

		if (!isDevelopment) {
			return;
		}

		// Log N+1 warning
		var message = "N+1 Query Detected: Accessed relationship '#arguments.relationshipName#' on #arguments.modelClass# without eager loading. Consider using includes(['#arguments.relationshipName#'])";

		// Use systemOutput for logging (TestBox-friendly)
		systemOutput(message, true);

		// Also try to log via application logger if available
		if (structKeyExists(application, "logger") && isObject(application.logger)) {
			try {
				application.logger.warn(message);
			} catch (any e) {
				// Silently ignore if logger fails
			}
		}
	}

	/**
	 * Detect if running in development environment
	 * Checks common environment indicators
	 *
	 * @return Boolean true if development environment
	 */
	private boolean function isDevEnvironment() {
		// Check application.environment
		if (structKeyExists(application, "environment")) {
			var env = lcase(application.environment);
			return env == "development" || env == "dev" || env == "local";
		}

		// Check application.config.environment
		if (structKeyExists(application, "config") && structKeyExists(application.config, "environment")) {
			var env = lcase(application.config.environment);
			return env == "development" || env == "dev" || env == "local";
		}

		// Default to development if not explicitly set
		return true;
	}

}
