# Spec Requirements: Routing & Event System

## Initial Description
Route registration with pattern matching (static/params/wildcards), RESTful resource routes, named route generation, event service with interceptor points (onBeforeRequest, onAfterRouting, onBeforeHandler, onAfterHandler, onBeforeRender, onAfterRender).

This is roadmap item #2, building on the completed Bootstrap Core & DI Container (item #1).

## Requirements Discussion

### First Round Questions

**Q1:** Handler directory location - confirm `/app/handlers/` as convention?
**Answer:** CONFIRMED - `/app/handlers/` directory

**Q2:** Named route helper style - Rails verbose (`urlFor("users_show", {id: 1})`) vs Laravel shorthand (`route("users.show", {id: 1})`)?
**Answer:** CONFIRMED - Rails-style verbose helpers with underscores: `urlFor("users_show", {id: 1})`

**Q3:** Handler instantiation - singleton (cached) vs transient (per-request)?
**Answer:** CONFIRMED - Transient (per-request) with DI container auto-wiring

**Q4:** Route definition location - confirm `/config/routes.cfm` as convention?
**Answer:** CONFIRMED (implicit from roadmap context)

**Q5:** Route pattern syntax - Rails-style (`:id`) vs Laravel-style (`{id}`)?
**Answer:** Rails-style colon syntax: `/users/:id`

**Q6:** RESTful resource routes - standard 7 routes (index, new, create, show, edit, update, destroy)?
**Answer:** CONFIRMED - 7 standard RESTful routes

**Q7:** Event system approach - observer pattern with registration vs automatic discovery?
**Answer:** Observer pattern with explicit registration via modules

**Q8:** Interceptor points needed beyond listed - beforeValidation, afterError, onSessionStart?
**Answer:** Start with specified 6 points: onBeforeRequest, onAfterRouting, onBeforeHandler, onAfterHandler, onBeforeRender, onAfterRender

### Follow-up Questions

**Follow-up 1:** Handler directory structure - flat `/app/handlers/` or namespace-based `/app/handlers/admin/`, `/app/handlers/api/`?
**Answer:** Start with flat structure, namespacing via future roadmap item

**Follow-up 2:** Route constraints (regex patterns, HTTP method filtering) - include or defer?
**Answer:** Defer to future roadmap item

**Follow-up 3:** Middleware chain architecture - include or defer?
**Answer:** Defer to future roadmap item (middleware chains excluded from scope)

**Follow-up 4:** Route parameter validation - include or defer?
**Answer:** Defer to future roadmap item

### Existing Code to Reference

**Similar Features Identified:**
- Feature: Bootstrap Core & DI Container - Path: `/fuse/core/`
- Components to potentially reuse: DI container for handler auto-wiring, module system for interceptor registration
- Backend logic to reference: Bootstrap initialization pattern, module loading pattern

No additional existing code beyond Bootstrap Core & DI Container (item #1).

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
Not applicable - no visual files found.

## Requirements Summary

### Functional Requirements

**Route Registration:**
- Route definition file at `/config/routes.cfm`
- Pattern matching syntax: static segments, `:param` style parameters, wildcard support
- HTTP verb specification (GET, POST, PUT, PATCH, DELETE)
- Mapping routes to handler actions: `router.get("/users/:id", "Users.show")`

**RESTful Resource Routes:**
- Single declaration: `router.resource("users")` generates 7 routes:
  - `GET /users` → `Users.index`
  - `GET /users/new` → `Users.new`
  - `POST /users` → `Users.create`
  - `GET /users/:id` → `Users.show`
  - `GET /users/:id/edit` → `Users.edit`
  - `PUT/PATCH /users/:id` → `Users.update`
  - `DELETE /users/:id` → `Users.destroy`

**Named Routes:**
- Auto-generated names from resource routes: `users_index`, `users_show`, `users_new`, etc.
- Explicit naming: `router.get("/about", "Pages.about", {name: "about_page"})`
- Helper method API: `urlFor("users_show", {id: 1})` returns `/users/1`
- Helper available in handlers and views

**Handler Conventions:**
- Location: `/app/handlers/` directory
- Naming: `Users.cfc`, `Pages.cfc` (singular or plural, match route declaration)
- Methods: public functions matching action names (`index()`, `show()`, `create()`, etc.)
- Lifecycle: transient (per-request instantiation)
- DI auto-wiring: constructor injection and property injection via DI container

**Event System:**
- Event service component manages interceptor registration and execution
- Six interceptor points throughout request lifecycle:
  - `onBeforeRequest` - before any routing/handler execution
  - `onAfterRouting` - after route matched, before handler instantiation
  - `onBeforeHandler` - after handler instantiated, before action method called
  - `onAfterHandler` - after action method returns, before rendering
  - `onBeforeRender` - before view rendering
  - `onAfterRender` - after view rendered, before response sent
- Interceptors registered by modules via observer pattern
- Interceptors receive event context struct with request/response/routing data

**Route Pattern Matching:**
- Static segments: `/about`, `/users/new`
- Named parameters: `/users/:id`, `/posts/:post_id/comments/:id`
- Wildcard support: `/files/*path` matches `/files/docs/readme.pdf`
- Parameter extraction into handler arguments or request context

### Reusability Opportunities

**Bootstrap Core & DI Container patterns:**
- DI container integration for handler instantiation with auto-wiring
- Module system for interceptor registration (modules provide interceptors)
- Configuration management patterns for routes.cfm loading
- Initialization sequence integration (Bootstrap → Routing setup)

**Framework reference patterns:**
- Rails routing conventions (syntax, RESTful resources, named routes)
- Rails-style helper method naming with underscores
- Observer pattern for event system (similar to Rails callbacks)

### Scope Boundaries

**In Scope:**
- Route definition DSL in `/config/routes.cfm`
- Pattern matching: static, `:param`, wildcard `*`
- RESTful resource route generation (7 standard routes)
- Named route system with `urlFor()` helper
- Handler loading from `/app/handlers/`
- Handler instantiation (transient) with DI auto-wiring
- Event service with 6 interceptor points
- Interceptor registration via module system
- Route-to-handler dispatching

**Out of Scope:**
- Middleware chain architecture (future roadmap item)
- Route constraints (regex validation, domain matching)
- Namespace-based handler organization (`/app/handlers/admin/`)
- Route parameter validation/coercion
- Route caching/compilation optimization
- Advanced resource routing (nested resources, shallow routes)
- Custom interceptor points beyond specified 6
- Error handling interceptors (`afterError`, etc.)
- Session lifecycle events (`onSessionStart`, etc.)
- Route versioning (API v1, v2)
- Route prefixing/grouping with shared middleware

### Technical Considerations

**Integration Points:**
- Bootstrap Core: routing setup during application initialization
- DI Container: handler instantiation with dependency resolution
- Module System: interceptor registration from modules
- Configuration System: load `/config/routes.cfm` with environment awareness

**Existing System Constraints:**
- Must work with completed Bootstrap Core & DI Container (roadmap #1)
- Module interface (`IModule`) from Bootstrap supports interceptor hooks
- DI container supports transient scope for per-request instantiation
- Thread-safe initialization from Bootstrap applies to route registration

**Technology Preferences:**
- Lucee 7 exclusive (static methods available)
- Convention-over-configuration (zero config for standard patterns)
- Rails-inspired conventions (routing DSL, RESTful resources)
- Hash-based configuration where applicable (route options struct)

**Similar Code Patterns to Follow:**
- Bootstrap.cfc initialization pattern for Router setup
- ModuleLoader pattern for discovering/registering interceptors from modules
- DI Container `get()` pattern for handler instantiation
- Configuration loading pattern from `/config/` directory
