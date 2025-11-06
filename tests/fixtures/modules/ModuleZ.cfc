component {

	function init() {
		return this;
	}

	public void function register(required container) {}

	public void function boot(required container) {}

	public array function getDependencies() {
		return ["NonExistentModule"];
	}

	public struct function getConfig() {
		return {};
	}

}
