<cfscript>
testbox = new testbox.system.TestBox(
	bundles = ["tests.cache.CacheProviderTest"],
	reporter = "text"
);

results = testbox.run();
writeOutput(results);
</cfscript>
