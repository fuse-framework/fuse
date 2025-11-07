# Views

**Status:** Coming in v1.1

Render dynamic HTML responses using Fuse's view system with layouts, partials, and view helpers for clean separation between presentation and business logic.

## Overview

View system provides template rendering (planned for v1.1):

```cfml
// Planned view rendering pattern (v1.1)
// app/handlers/Posts.cfc
component {

    public struct function index() {
        var posts = Post::where({published: true})
            .orderBy("created_at DESC")
            .get();

        // Return view with data
        return this.render("posts/index", {
            posts: posts,
            title: "Recent Posts"
        });
    }

    public struct function show() {
        var post = Post::find(params.id);

        return this.render("posts/show", {
            post: post
        });
    }
}
```

```cfml
<!-- Planned view template (v1.1) -->
<!-- app/views/posts/index.cfm -->
<cfoutput>
    <h1>#title#</h1>

    <div class="posts">
        <cfloop array="#posts#" index="post">
            <article>
                <h2><a href="#urlFor('posts_show', {id: post.id})#">#post.title#</a></h2>
                <p>#post.excerpt#</p>
                <p>By #post.user.name# on #dateFormat(post.created_at, "mmm d, yyyy")#</p>
            </article>
        </cfloop>
    </div>
</cfoutput>
```

Views enable clean HTML generation with data binding and reusable components.

## View Rendering

### Rendering Views from Handlers

Return rendered views from handler actions:

```cfml
// Planned pattern (v1.1)
// app/handlers/Users.cfc
component {

    public struct function index() {
        var users = User::all().get();

        // Render view
        return this.render("users/index", {
            users: users,
            pageTitle: "All Users"
        });
    }

    public struct function show() {
        var user = User::find(params.id);

        // Render with layout
        return this.render("users/show", {
            user: user
        }, {
            layout: "admin"
        });
    }
}
```

### View Location Convention

Views stored in `/app/views` following conventions:

```
app/views/
├── layouts/
│   ├── application.cfm      # Default layout
│   └── admin.cfm            # Admin layout
├── posts/
│   ├── index.cfm            # Posts list
│   ├── show.cfm             # Single post
│   └── _post.cfm            # Post partial (starts with _)
├── users/
│   ├── index.cfm
│   └── show.cfm
└── shared/
    ├── _header.cfm
    └── _footer.cfm
```

Convention: `views/{handler}/{action}.cfm`

### Passing Data to Views

Pass local variables to view:

```cfml
// Handler
return this.render("posts/index", {
    posts: posts,
    featured: featuredPost,
    categories: categories
});

// View has access to:
// - posts
// - featured
// - categories
```

## Layout System

### Default Layout

Application-wide layout wraps all views:

```cfml
<!-- Planned layout (v1.1) -->
<!-- app/views/layouts/application.cfm -->
<cfoutput>
<!DOCTYPE html>
<html>
<head>
    <title>#pageTitle ?: 'My Application'#</title>
    <link rel="stylesheet" href="/css/app.css">
</head>
<body>
    <header>
        #renderPartial('shared/header')#
    </header>

    <main>
        <!-- View content rendered here -->
        #content#
    </main>

    <footer>
        #renderPartial('shared/footer')#
    </footer>

    <script src="/js/app.js"></script>
</body>
</html>
</cfoutput>
```

### Custom Layouts

Specify different layout per view:

```cfml
// Handler
return this.render("admin/dashboard", {
    stats: stats
}, {
    layout: "admin"  // Use admin layout instead of default
});
```

### Disabling Layout

Render view without layout:

```cfml
// AJAX response without layout
return this.render("posts/_post", {
    post: post
}, {
    layout: false
});
```

## Partial Rendering

### Including Partials

Reuse view fragments:

```cfml
<!-- Planned partial pattern (v1.1) -->
<!-- app/views/posts/index.cfm -->
<cfoutput>
    <h1>Posts</h1>

    <div class="posts">
        <cfloop array="#posts#" index="post">
            #renderPartial('posts/post', {post: post})#
        </cfloop>
    </div>
</cfoutput>
```

```cfml
<!-- app/views/posts/_post.cfm -->
<cfoutput>
    <article class="post">
        <h2>#post.title#</h2>
        <p>#post.excerpt#</p>
        <a href="#urlFor('posts_show', {id: post.id})#">Read more</a>
    </article>
</cfoutput>
```

### Partial Convention

Partial filenames start with underscore:
- `_header.cfm`
- `_post.cfm`
- `_form.cfm`

### Collection Partials

Render partial for each item:

```cfml
<!-- Planned pattern (v1.1) -->
<cfoutput>
    #renderCollection(posts, 'posts/post')#
</cfoutput>

<!-- Equivalent to: -->
<cfoutput>
    <cfloop array="#posts#" index="post">
        #renderPartial('posts/post', {post: post})#
    </cfloop>
</cfoutput>
```

## View Helpers

### Built-in Helpers

Framework provides common helpers:

```cfml
<!-- Planned helpers (v1.1) -->

<!-- URL generation -->
<a href="#urlFor('posts_show', {id: post.id})#">View Post</a>
<a href="#urlFor('users_edit', {id: user.id})#">Edit User</a>

<!-- HTML escaping -->
<p>#h(user.bio)#</p>  <!-- Escapes HTML entities -->

<!-- Form helpers -->
#formFor(user, {action: 'update'}, function() {
    return inputField('name') &
           textareaField('bio') &
           submitButton('Save');
})#

<!-- Date formatting -->
<time>#dateFormat(post.created_at, 'mmm d, yyyy')#</time>
```

### Custom Helpers

Register application-specific helpers:

```cfml
// Planned helper registration (v1.1)
// config/bootstrap.cfc

viewRenderer.addHelper("avatar", function(user) {
    if (len(trim(user.avatar_url))) {
        return '<img src="' & user.avatar_url & '" alt="' & user.name & '">';
    } else {
        return '<div class="avatar-placeholder">' & left(user.name, 1) & '</div>';
    }
});

viewRenderer.addHelper("truncate", function(text, length = 100) {
    if (len(text) <= length) {
        return text;
    }
    return left(text, length) & "...";
});
```

```cfml
<!-- Use custom helpers in views -->
<cfoutput>
    <div class="user-profile">
        #avatar(user)#
        <p>#truncate(user.bio, 200)#</p>
    </div>
</cfoutput>
```

## View Examples

### List View

```cfml
<!-- Planned pattern (v1.1) -->
<!-- app/views/posts/index.cfm -->
<cfoutput>
    <h1>#pageTitle#</h1>

    <div class="actions">
        <a href="#urlFor('posts_new')#" class="btn">New Post</a>
    </div>

    <table class="posts-table">
        <thead>
            <tr>
                <th>Title</th>
                <th>Author</th>
                <th>Published</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <cfloop array="#posts#" index="post">
                <tr>
                    <td><a href="#urlFor('posts_show', {id: post.id})#">#h(post.title)#</a></td>
                    <td>#h(post.user.name)#</td>
                    <td>#dateFormat(post.published_at, 'mmm d, yyyy')#</td>
                    <td>
                        <a href="#urlFor('posts_edit', {id: post.id})#">Edit</a>
                        <a href="#urlFor('posts_destroy', {id: post.id})#" data-method="delete">Delete</a>
                    </td>
                </tr>
            </cfloop>
        </tbody>
    </table>
</cfoutput>
```

### Detail View

```cfml
<!-- app/views/posts/show.cfm -->
<cfoutput>
    <article class="post-detail">
        <header>
            <h1>#h(post.title)#</h1>
            <p class="meta">
                By <a href="#urlFor('users_show', {id: post.user_id})#">#h(post.user.name)#</a>
                on #dateFormat(post.published_at, 'mmm d, yyyy')#
            </p>
        </header>

        <div class="post-body">
            #post.body#
        </div>

        <aside class="comments">
            <h2>Comments</h2>
            #renderPartial('comments/list', {comments: post.comments})#
        </aside>
    </article>
</cfoutput>
```

### Form View

```cfml
<!-- app/views/posts/edit.cfm -->
<cfoutput>
    <h1>Edit Post</h1>

    #renderPartial('shared/errors', {errors: post.getErrors()})#

    <form action="#urlFor('posts_update', {id: post.id})#" method="post">
        <input type="hidden" name="_method" value="PUT">

        <div class="form-group">
            <label for="title">Title</label>
            <input type="text" name="title" id="title" value="#h(post.title)#">
        </div>

        <div class="form-group">
            <label for="body">Body</label>
            <textarea name="body" id="body">#h(post.body)#</textarea>
        </div>

        <div class="form-group">
            <label>
                <input type="checkbox" name="published" value="1" #post.published ? 'checked' : ''#>
                Published
            </label>
        </div>

        <div class="actions">
            <button type="submit">Save Post</button>
            <a href="#urlFor('posts_show', {id: post.id})#">Cancel</a>
        </div>
    </form>
</cfoutput>
```

## Current Workarounds

Until views implemented, use these patterns:

### Return JSON

```cfml
// Handler returns JSON
public struct function index() {
    var posts = Post::all().get();

    return {
        success: true,
        data: posts
    };
}
```

### Include CFM Templates

```cfml
// Handler includes template manually
public void function index() {
    variables.posts = Post::all().get();
    include "/views/posts/index.cfm";
}
```

### Use Custom View Service

```cfml
// Custom view renderer
public struct function index() {
    var posts = Post::all().get();

    var viewService = new app.services.ViewService();
    var html = viewService.render("posts/index", {
        posts: posts
    });

    return {
        body: html,
        contentType: "text/html"
    };
}
```

## Implementation Timeline

View system implementation planned for v1.1:

**Phase 1:**
- Basic view rendering
- Layout system
- Data passing to views

**Phase 2:**
- Partial rendering
- Built-in helpers
- Custom helper registration

**Phase 3:**
- Form helpers
- Collection rendering
- View caching

## Design Goals

View system will prioritize:

1. **Simplicity** - Easy to use for CFML developers
2. **Convention** - Follow framework conventions
3. **Performance** - Fast rendering with optional caching
4. **Flexibility** - Support custom helpers and extensions
5. **Security** - Auto-escape HTML by default

## Related Topics

- [Handlers](../handlers.md) - Handler return values and response patterns
- [Routing](../guides/routing.md) - URL generation for views
- [Modules](modules.md) - View module implementation
- [Performance](performance.md) - View caching strategies
