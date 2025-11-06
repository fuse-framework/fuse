# Fuse Framework Roadmap

1. [ ] Bootstrap Core & DI Container — Application.cfc initialization with thread-safe locking, module loader with dependency resolution, DI container with constructor/property injection and singleton caching, configuration loading with environment overrides `M`

2. [ ] Routing & Event System — Route registration with pattern matching (static/params/wildcards), RESTful resource routes, named route generation, event service with interceptor points (onBeforeRequest, onAfterRouting, onBeforeHandler, onAfterHandler, onBeforeRender, onAfterRender) `M`

3. [ ] Cache & View Rendering — Pluggable cache manager with ICacheProvider interface, RAM cache provider implementation, view renderer with layout wrapping, helper method system for views `S`

4. [ ] Query Builder Foundation — Two-layer query builder (QueryBuilder for raw SQL, ModelBuilder for ORM features), hash-based where() with operator structs ({gte:, like:, in:}), orderBy/limit/offset, raw SQL support (whereRaw, selectRaw) `L`

5. [ ] ActiveRecord Base & CRUD — Model base class with static query methods (where, find, all), instance methods (save, update, delete), attribute handling with dirty tracking, table name conventions, primary key handling `L`

6. [ ] Schema Builder & Migrations — CFC-based Migration base class, Schema builder for table operations (create/drop/rename), column types (id/string/text/integer/boolean/timestamps), column modifiers (notNull/unique/default/index), Migrator for tracking and running migrations with up/down support `M`

7. [ ] ORM Relationships — Relationship definition methods (hasMany, belongsTo, hasOne) in ActiveRecord, relationship metadata storage, foreign key conventions, relationship query methods (user.posts()) `L`

8. [ ] Smart Eager Loading — includes() implementation with automatic N+1 prevention, smart strategy selection (JOIN vs separate queries), nested eager loading support, manual strategy override (joins, preload), result hydration for eager loaded relationships `L`

9. [ ] Validations & Lifecycle — Validator component with validates() DSL in models, built-in validators (required/email/unique/length/format), custom validator support, validation error collection, lifecycle callbacks (beforeSave/afterSave/beforeCreate/afterCreate/beforeDelete/afterDelete) with registration system `M`

10. [ ] Test Framework Foundation — TestCase base class with setup/teardown, test runner with discovery and execution, Assertions component with common assert methods, test reporting to console, database transaction rollback between tests `M`

11. [ ] Test Helpers & Integration — Model factories (make/create methods), handler testing helpers for request/response simulation, integration test support, test database setup/teardown automation `S`

12. [ ] CLI Generators — FuseCLI entry point for lucli integration, NewCommand for app scaffolding, GenerateCommand for code generation (handler/model/migration/module), template system for code generation with variable interpolation `M`

13. [ ] CLI Database & Dev Tools — MigrateCommand for running migrations, RollbackCommand for migration rollback, SeedCommand for data seeding, RoutesCommand to list all routes, ServeCommand for dev server, TestCommand to run test suite `S`

14. [ ] Documentation & Examples — Getting started guide, architecture overview, routing/ORM/testing guides, module development guide, API reference, configuration reference, CLI reference, tutorial blog application `L`

15. [ ] Production Polish & Performance — Performance optimization pass (query caching, component lifecycle), enhanced error handling with framework-aware errors, logging system for requests/errors, production deployment checklist, migration guides from Wheels/FW/1/ColdBox `M`

> Notes
> - Items ordered by technical dependencies: bootstrap → core modules → ORM foundation → ORM relationships → validations → testing → CLI → docs
> - Each item represents end-to-end functionality spanning multiple components (bootstrap includes Application.cfc + Bootstrap.cfc + ModuleLoader + DI container)
> - ORM items are split by architectural layers (query builder → ActiveRecord → relationships → eager loading) enabling incremental testing
> - Testing framework comes after ORM to enable comprehensive model/handler testing
> - CLI and documentation phases assume working framework core for generation targets
