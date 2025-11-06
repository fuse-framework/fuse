# Task Breakdown: Bootstrap Core & DI Container

## Overview
Total Tasks: 5 major task groups with 25 sub-tasks

## Task List

### DI Container Core

#### Task Group 1: DI Container Foundation
**Dependencies:** None

- [x] 1.0 Complete DI container foundation
  - [x] 1.1 Write 2-8 focused tests for container basics
    - Test singleton vs transient binding/resolution
    - Test constructor injection with dependencies
    - Test property injection via inject metadata
    - Test circular dependency detection
    - Test missing dependency error handling
  - [x] 1.2 Create Container.cfc with core data structures
    - Bindings struct (name -> factory closure/CFC path)
    - Instances struct (name -> singleton instance)
    - Resolution stack array (circular dependency tracking)
    - Scope tracking per binding (singleton vs transient)
  - [x] 1.3 Implement binding registration methods
    - `bind(name, implementation)` for transient scope
    - `singleton(name, implementation)` for singleton scope
    - Support CFC path strings and closure factories
    - Validate binding name uniqueness
  - [x] 1.4 Implement basic resolution method
    - `resolve(name)` returns instance
    - Check instances cache for singletons first
    - Create new instance for transients always
    - Track resolution stack for circular detection
    - Throw descriptive error if binding not found
  - [x] 1.5 Add constructor injection via metadata introspection
    - Use `getMetadata()` to find init() parameters
    - Match param names to container bindings
    - Resolve dependencies recursively
    - Pass as named arguments to init()
    - Error if required param missing and no default
  - [x] 1.6 Add property injection via inject metadata
    - Scan component properties for inject attribute
    - Resolve each injected dependency from container
    - Call implicit setter (e.g., setLogger()) after construction
    - Support property injection on all resolved components
  - [x] 1.7 Ensure DI container tests pass
    - Run ONLY the 2-8 tests written in 1.1
    - Verify singleton caching works correctly
    - Verify transient creates new instances
    - Verify circular dependency throws error

**Acceptance Criteria:**
- The 2-8 tests written in 1.1 pass
- Singleton scope caches instances correctly
- Transient scope creates new instances each time
- Constructor and property injection work via metadata
- Circular dependencies detected and fail fast
- Missing dependencies throw descriptive errors

### Configuration System

#### Task Group 2: Configuration Loading & Merging
**Dependencies:** Task Group 1 (needs DI container)

- [x] 2.0 Complete configuration system
  - [x] 2.1 Write 2-8 focused tests for configuration
    - Test base config loading from application.cfc
    - Test environment override deep-merge
    - Test module config merging under module key
    - Test environment detection (APPLICATION.environment, ENV.FUSE_ENV)
    - Test final config bound to DI container as singleton
  - [x] 2.2 Create Config.cfc component
    - Load base config from `/config/application.cfc` getConfig()
    - Detect environment from APPLICATION.environment or ENV.FUSE_ENV
    - Load environment override from `/config/environments/{env}.cfc`
    - Implement deep-merge algorithm for nested structs
    - Override values take precedence over base values
  - [x] 2.3 Add module configuration merging
    - Accept module config structs
    - Merge under module name key (e.g., config.RoutingModule)
    - Preserve base/environment config
    - Return final merged configuration struct
  - [x] 2.4 Bind configuration to DI container
    - Register merged config as "config" singleton
    - Allow primitive value injection (strings, numbers, structs)
    - Support nested key access in injected properties
  - [x] 2.5 Ensure configuration tests pass
    - Run ONLY the 2-8 tests written in 2.1
    - Verify deep-merge works for nested structs
    - Verify environment overrides take precedence
    - Verify module configs merged correctly

**Acceptance Criteria:**
- The 2-8 tests written in 2.1 pass
- Base configuration loads from application.cfc
- Environment-specific overrides merge correctly
- Module configs merge under module name keys
- Final config bound to container as singleton

### Module System

#### Task Group 3: Module Discovery & Dependency Resolution
**Dependencies:** Task Groups 1-2 (needs DI container and config)

- [x] 3.0 Complete module system
  - [x] 3.1 Write 2-8 focused tests for module system
    - Test auto-discovery from /fuse/modules/ and /modules/
    - Test topological sort with valid dependency graph
    - Test circular dependency detection throws error
    - Test missing dependency throws error
    - Test two-phase initialization (register then boot)
    - Test framework modules load before app modules
  - [x] 3.2 Create IModule.cfc interface
    - Define register(container) method
    - Define boot(container) method
    - Define getDependencies() method (returns array)
    - Define getConfig() method (returns struct)
    - Add interface validation or runtime checking
  - [x] 3.3 Create ModuleRegistry.cfc component
    - Scan /fuse/modules/ for *Module.cfc files
    - Scan /modules/ for *Module.cfc files
    - Instantiate each module and validate IModule interface
    - Build ordered struct: name -> {path, instance, dependencies, loaded}
    - Framework modules added before application modules
  - [x] 3.4 Implement topological sort for dependency ordering
    - Parse getDependencies() from each module
    - Build dependency graph
    - Detect circular dependencies (throw descriptive error)
    - Detect missing dependencies (throw descriptive error)
    - Return dependency-ordered array of module names
  - [x] 3.5 Implement two-phase module initialization
    - Phase 1: Call register(container) on all modules in order
    - Modules bind services, no resolution allowed
    - Phase 2: Call boot(container) on all modules in same order
    - Modules resolve dependencies and initialize
    - Merge module getConfig() into global config before Phase 1
  - [x] 3.6 Ensure module system tests pass
    - Run ONLY the 2-8 tests written in 3.1
    - Verify modules discovered from both directories
    - Verify topological sort orders correctly
    - Verify circular dependencies throw error

**Acceptance Criteria:**
- The 2-8 tests written in 3.1 pass
- Modules auto-discovered from framework and app directories
- Topological sort orders modules by dependencies
- Circular and missing dependencies fail fast with clear errors
- Two-phase initialization (register then boot) works correctly
- Framework modules load before application modules

### Application Bootstrap

#### Task Group 4: Thread-Safe Application.cfc Bootstrap
**Dependencies:** Task Groups 1-3 (needs all core systems)

- [x] 4.0 Complete thread-safe bootstrap
  - [x] 4.1 Write 2-8 focused tests for bootstrap
    - Test double-checked locking pattern
    - Test framework singleton in application scope
    - Test lock timeout configuration
    - Test onApplicationStart() triggers initialization
    - Test onRequestStart() fails if framework not initialized
    - Test <1ms overhead after initialization
  - [x] 4.2 Create Bootstrap.cfc component
    - Check application scope for framework instance (first check)
    - Acquire named lock with configurable timeout (default 30s)
    - Check application scope again (double-checked locking)
    - Initialize framework if absent
    - Store singleton under configurable key (default "fuse")
    - Return framework instance
  - [x] 4.3 Implement framework initialization sequence
    - Instantiate DI container
    - Load configuration (base + environment + modules)
    - Bind config to container as singleton
    - Discover modules via ModuleRegistry
    - Sort modules by dependencies (topological sort)
    - Execute two-phase initialization (register then boot)
    - Return initialized framework instance
  - [x] 4.4 Create Application.cfc template with bootstrap integration
    - Add lockTimeout property (default 30s)
    - Add applicationKey property (default "fuse")
    - onApplicationStart() calls Bootstrap initialization
    - onRequestStart() validates framework initialized (fail fast)
    - Cache framework instance for <1ms overhead per request
  - [x] 4.5 Ensure bootstrap tests pass
    - Run ONLY the 2-8 tests written in 4.1
    - Verify double-checked locking prevents race conditions
    - Verify singleton stored in application scope
    - Verify fail-fast behavior works

**Acceptance Criteria:**
- The 2-8 tests written in 4.1 pass
- Double-checked locking prevents race conditions
- Framework singleton stored in application scope
- Lock timeout configurable via Application.cfc property
- onApplicationStart() triggers initialization
- onRequestStart() fails fast if framework not initialized
- <1ms overhead per request after initialization

### Testing & Integration

#### Task Group 5: Integration Tests & Gap Analysis
**Dependencies:** Task Groups 1-4 (complete system)

- [x] 5.0 Complete integration testing
  - [x] 5.1 Review tests from Task Groups 1-4
    - Review DI container tests (1.1)
    - Review configuration tests (2.1)
    - Review module system tests (3.1)
    - Review bootstrap tests (4.1)
    - Total existing: approximately 8-32 tests
  - [x] 5.2 Analyze integration test coverage gaps
    - Identify end-to-end workflows lacking coverage
    - Focus on cross-component interactions
    - Prioritize critical bootstrap sequence testing
    - Do NOT assess comprehensive edge case coverage
  - [x] 5.3 Write up to 10 additional integration tests maximum
    - Test complete Application.cfc bootstrap flow
    - Test module loading with real module dependencies
    - Test DI resolution through module initialization
    - Test configuration injection into resolved components
    - Test error scenarios: circular deps, missing modules, invalid config
    - Focus on end-to-end critical paths only
  - [x] 5.4 Run complete feature test suite
    - Run all tests from groups 1-4 plus new integration tests
    - Expected total: approximately 18-42 tests maximum
    - Verify all critical workflows pass
    - Document any known limitations or edge cases
    - Do NOT run tests for out-of-scope features

**Acceptance Criteria:**
- All feature-specific tests pass (approximately 18-42 tests total)
- End-to-end bootstrap workflow validated
- Module dependency resolution tested with real modules
- DI container integration tested across module lifecycle
- No more than 10 additional tests added in gap analysis
- Testing focused exclusively on bootstrap core & DI container

## Execution Order

Recommended implementation sequence:
1. DI Container Core (Task Group 1) - Foundation for all dependency management
2. Configuration System (Task Group 2) - Required by modules and bootstrap
3. Module System (Task Group 3) - Depends on DI container and config
4. Application Bootstrap (Task Group 4) - Orchestrates all systems
5. Testing & Integration (Task Group 5) - Validates complete system

## Implementation Notes

**CFML-Specific Considerations:**
- Use `getMetadata()` for component introspection (constructor params, properties)
- Leverage Lucee 7 struct ordering for module registry
- Use named locks for thread-safe application scope access
- Apply `inject` metadata attribute on properties for injection marking
- Use closure-based factory functions for lazy instantiation

**Reference Implementations:**
- ColdBox Bootstrap.cfc - Double-checked locking pattern
- ColdBox Injector.cfc - Constructor/property injection via metadata
- ColdBox ModuleService.cfc - Two-phase initialization and registry
- Laravel Container - Binding closures and singleton caching
- Rails Railtie - Module dependency and initialization ordering

**Error Handling:**
- Circular dependencies: Descriptive error with dependency chain
- Missing dependencies: List missing module and dependent module
- Missing bindings: Show binding name and requesting component
- Lock timeout: Clear message about initialization conflict
- All errors fail fast with actionable messages

**Performance Targets:**
- <1ms request overhead after initialization
- Module discovery under 10ms for typical app (10-20 modules)
- DI resolution under 1ms for typical dependency graph
- Application scope singleton pattern (not server scope)
