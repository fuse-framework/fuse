# Routing & Event System

**Roadmap Item #2**

Route registration with pattern matching (static/params/wildcards), RESTful resource routes, named route generation, event service with interceptor points (onBeforeRequest, onAfterRouting, onBeforeHandler, onAfterHandler, onBeforeRender, onAfterRender).

## Context

This is the second roadmap item for the Fuse framework. The Bootstrap Core & DI Container (item #1) has been completed, providing the foundation of Application.cfc initialization, module loading, DI container, and configuration management.

This feature will build the routing and event system on top of that foundation, enabling HTTP request handling, URL routing to handlers, and lifecycle event interception throughout the request flow.
