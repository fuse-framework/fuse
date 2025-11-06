component {

	this.name = "FuseTests" & hash(getCurrentTemplatePath());
	this.sessionManagement = false;
	this.setClientCookies = false;

	// Map paths
	this.mappings["/testbox"] = expandPath("../testbox");
	this.mappings["/tests"] = expandPath("./");
	this.mappings["/fuse"] = expandPath("../fuse");

}
