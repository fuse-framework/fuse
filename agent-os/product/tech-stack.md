# Fuse Framework Tech Stack

## Core Runtime
- **Lucee 7+**: Exclusive target platform, requires static method support (Lucee 6+, stable in 7)
- **Jakarta EE**: Modern servlet APIs via PageContext wrapper
- **CFML**: Primary programming language for all framework code
- **JVM**: Java Virtual Machine runtime (Java 11+)

## Framework Architecture
- **Application Scope Caching**: Standard Lucee application singleton pattern with thread-safe locking
- **Component-Based**: All framework code in CFC components
- **Module System**: Everything-is-a-module architecture with IModule interface
- **Static Methods**: Core to ActiveRecord pattern and query builder API

## Dependency Injection
- **Built-in DI Container**: Custom lightweight DI implementation (not WireBox)
- **Constructor Injection**: Primary injection method
- **Property Injection**: Auto-wiring via `inject` metadata
- **Scope Support**: Singleton and transient scopes
- **Interface Binding**: Pluggable components via interface-to-implementation binding

## ORM & Database
- **ActiveRecord Pattern**: Model base class with static and instance methods
- **Two-Layer Query Builder**: QueryBuilder (raw SQL) + ModelBuilder (ORM features)
- **Hash-Based Query Syntax**: Struct-based where conditions (CFML native)
- **CFC-Based Migrations**: Schema builder with type-safe column definitions
- **Prepared Statements**: Parameterized queries for security
- **Database Support**: Any JDBC-compatible database (MySQL, PostgreSQL, SQL Server, etc)

## Testing
- **Built-in Test Framework**: Custom Rails-like test implementation (not TestBox)
- **Test Runner**: Automatic test discovery and execution
- **Assertions Library**: Common assert methods (assertEqual, assertTrue, etc)
- **Model Factories**: Test data generation helpers
- **Transaction Rollback**: Automatic database cleanup between tests

## CLI
- **lucli**: Lucee 7 CLI tool (framework dependency)
- **Embedded Commands**: CLI code in `fuse/cli/` loaded by lucli as extension
- **Code Generators**: Template-based code generation for models/handlers/migrations
- **Database Commands**: Migration runner, rollback, seed commands
- **Dev Server**: Built-in development server via lucli

## Module System Components
- **Core Modules**: Built-in framework modules (routing, events, cache, orm, views, testing)
- **Module Auto-Discovery**: Automatic loading from `fuse/modules/` and `/modules/` directories
- **Dependency Resolution**: Topological sort for module initialization order
- **IModule Interface**: Standard contract for all modules (register, boot, getRoutes, getInterceptors)

## Cache Layer
- **Pluggable Architecture**: ICacheProvider interface for cache adapters
- **Built-in RAM Provider**: Default memory-based cache
- **Third-Party Support**: Redis, Memcached via community providers

## View Layer
- **CFM Templates**: Standard CFML templates for views
- **Layout System**: Layout wrapping with yield points
- **Helper Methods**: View-specific helper functions
- **Partial Support**: Reusable view components

## Event System
- **Interceptor Pattern**: Event-driven architecture throughout request lifecycle
- **Built-in Events**: onBeforeRequest, onAfterRouting, onBeforeHandler, onAfterHandler, onBeforeRender, onAfterRender
- **Module Events**: Modules can provide custom interceptors
- **Event Announcement**: Publish/subscribe pattern for extensibility

## Development Tools
- **Environment Configuration**: .env file support with environment-specific overrides
- **Development Reload**: Query param-based framework reload (?fuseReload)
- **Error Handling**: Framework-aware error pages with clear messages
- **Request Logging**: Built-in request lifecycle logging

## Performance Optimizations
- **Application Scope Singleton**: Standard pattern, <1ms per-request overhead
- **Optional Server Singleton**: Lucee server-level singleton mode (5-20ms/request savings)
- **Smart Eager Loading**: Automatic N+1 query prevention
- **Component Lifecycle**: Efficient component caching and reuse

## AI/Documentation Stack
- **YAML API Schema**: Machine-readable API reference (api-reference.yaml)
- **Code Templates**: Generator templates for scaffolding
- **Decision Trees**: Task-based decision logic for AI agents
- **Error Reference**: Complete exception taxonomy (error-reference.md)

## Distribution & Versioning
- **Single Package**: Framework + CLI in one distribution
- **Semantic Versioning**: Version-locked CLI to framework version
- **Git Repository**: GitHub-based source control
- **lucli Extension**: Framework loads as lucli extension for CLI commands

## Production Stack
- **Web Server**: Apache/nginx with mod_cfml or Tomcat/Undertow
- **Lucee Server**: Standard Lucee 7+ installation
- **JDBC Datasources**: Configured in Lucee administrator
- **Application Scope**: Production apps use standard application scope caching
- **Monitoring**: Custom logging/monitoring via module system

## External Dependencies
- **Zero Runtime Dependencies**: No external CFML frameworks required
- **JDBC Drivers**: Database-specific (MySQL Connector, PostgreSQL JDBC, etc)
- **Java Dependencies**: Only Jakarta EE (provided by Lucee)
- **lucli**: Required for CLI functionality only (not runtime)

## Development Dependencies
- **Git**: Version control
- **Text Editor/IDE**: VS Code, IntelliJ IDEA, Sublime Text (any editor)
- **Database Client**: For schema inspection (TablePlus, DBeaver, etc)
- **Browser**: For testing web interface

## Not Used
- **Adobe ColdFusion**: Not supported
- **CommandBox**: Not used (lucli replaces)
- **TestBox**: Not used (built-in testing)
- **WireBox**: Not used (built-in DI)
- **ColdBox ORM/Wheels ORM**: Not used (custom ActiveRecord)
- **FW/1**: Not used (standalone framework)
- **Node.js/npm**: Not required (pure CFML)
- **Front-end Build Tools**: Framework-agnostic (use any)
