component {

	// Application settings
	this.name = "FuseApplication";
	this.sessionManagement = true;
	this.sessionTimeout = createTimeSpan(0, 0, 30, 0);

	// Bootstrap settings
	this.lockTimeout = 30;
	this.applicationKey = "fuse";

	// Map framework path
	this.mappings["/fuse"] = expandPath("../");

	/**
	 * Application start - initialize framework
	 */
	public boolean function onApplicationStart() {
		var bootstrap = new fuse.core.Bootstrap();
		bootstrap.initFramework(application, this.applicationKey, this.lockTimeout);
		return true;
	}

	/**
	 * Request start - validate framework initialized
	 */
	public boolean function onRequestStart(required string targetPage) {
		// Fail fast if framework not initialized
		if (!structKeyExists(application, this.applicationKey)) {
			throw(
				type = "Framework.NotInitialized",
				message = "Framework not initialized",
				detail = "Application.onApplicationStart() must complete before processing requests"
			);
		}

		// Cache framework instance in request scope for fast access
		request.fuse = application[this.applicationKey];

		return true;
	}

}
