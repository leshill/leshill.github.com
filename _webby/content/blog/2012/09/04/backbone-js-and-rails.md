---
title:      'Backbone.js and Rails (Part 1 of 2)'
author: Les Hill
created_at: 2012-09-04 00:00:27.876041 -07:00
layout: blog_post
blog_post:  true
filter:
  - coderay
  - markdown
  - footnote
  - notefoot
---

## “Down Mexico Way”

Earlier this summer I had the opportunity to speak at a fantastic regional conference,
[Magma Rails](http://magmarails.com).

The location is not what you might expect, being an off-the-beaten-path part of
[Mexico](http://en.wikipedia.org/wiki/Colima). There are no crowds of American
and European *touristas* &mdash; well none outside of the crowd of non-Mexican
rubyists.

On the other hand, you are deep in Mexico, midway along the Pacific coast, with
nice beaches and lovely mountains. The [sponsors](http://www.crowdint.com/),
Mexican rubyists, and people in general are genial and engaging, making us
*touristas* feel right at home.

The original talk topic was going to be **Cucumber**, instead I opted{fn1} for
talk titled [Getting started with Backbone and Rails, 25 things you need to
know](http://blog.leshill.org/backbone_and_rails_magma) ([ShowOff
slides](https://github.com/leshill/backbone_and_rails_magma)). The talk has a
fair bit of code, drawn from a working example. The example app was going to be
released after the conference…

…and, long story short, that never{fn2} happened…

…until now!

### An example app

The app is incomplete, lacking tests, and written for clarity not conciseness.
All of the JavaScript code is written in
[CoffeeScript](http://coffeescript.org/){fn3}. The Rails code is mostly
scaffolding. You can find the source on
[github](https://github.com/leshill/backbone_and_rails_example).

Over roughly 22 commits, the app is transformed into a one-page Backbone app
that:

* shows a list of movies
* allows drilling into a specific movie
* can add a new movie
* can deleted an existing movie
* sorts the list of movies
* allows deep links directly to a specific movie

The app demonstrates how to structure a Backbone app for use with the asset
pipeline, how to write views, handle forms, and interact with models, and how
to fit Backbone in with Rails.

## In depth

Let's explore two areas that are cross-cutting to all apps: rendering views and using routers and
controllers.

### Rendering

By default, Backbone does not render anything.

Nothing. Zip, zero, zilch. Na&ndash;da.

Really.

Backbone does create a container element. This very minimalist opinion in
Backbone is deliberate. The choice of how to render views into the DOM is
entirely up to you.

We are going to render using [mustache](http://mustache.github.com/) templates.
Not surprisingly, mustache, another minimal yet strongly opinionated piece of
software, is a great fit with Backbone.

### Rendering mustache

Let's start by replacing the Rails `index.html` view with a
client-side mustache template.

Normally, the template string would be processed in the browser by the
rendering engine, however [hogan.js](http://twitter.github.com/hogan.js/) gives
us a mustache rendering engine that can precompile templates for faster
processing in the browser.  We can precompile our mustache templates in the
Rails asset pipeline using
[hogan\_assets](https://github.com/leshill/hogan_assets){fn4}. The templates
files are compiled into JavaScript code that will render in the browser.

To load our template into the page, we use the asset pipeline's `require_tree`
directive in `application.js`
([commit](https://github.com/leshill/backbone_and_rails_example/commit/f926c433e610a7c2bb19d0571986798aeaaee329)).

**Note:** Using the asset pipeline means that you can do without JavaScript
loaders like **AMD**. If you are having problems with the asset pipeline or
want a good starting point, the Rails Guides
[entry](http://guides.rubyonrails.org/asset_pipeline.html) is particularly good.

With the template available on the page, we want to render the template as part
of a `Backbone.View`. We create a simple `View` class that does little more
than just expose the `render` method for now. The `render` method executes our
precompiled template and inserts the resulting string as the content of our
`@$el`. Mustache's render method takes two arguments, the context and a list
of partials. Initially we pass along our movie data as the context
([commit](https://github.com/leshill/backbone_and_rails_example/commit/12d929d2df815b36854afcc57e37807dfd0afe3d)).


### Rendering a Collection

Our movie data is coming from a JSON array inserted into our page by Rails.
Let's transform the data from an array of JSON to a `Backbone.Collection`.
Backbone directly understands JSON arrays and converts them to instances of
`Backbone.Model`.

To render our new collection, we introduce a specialized view class: `CollectionView`
that will know how to render the individual model instances
([commit](https://github.com/leshill/backbone_and_rails_example/commit/6be7879392f8c84157373726f3d0bee1c21d842c)).

We create our single `CollectionView` with the collection to render, the
element to render into, the selector for the child view container and a
callback to generate child view instances. Our callback generates a `Movie`
view (a placeholder at the moment.)

<coderay:javascript>
view = new App.Views.Index
  collection: collection
  el: $('body')
  selector: '#movie_list'
  view: (model) ->
    new App.Views.Movie(model: model)
</coderay>

**Note:** For anything other than a simple string or reference, prefer
configuration via code (callback) instead of configuration via property. For
the `view` option, the less desirable alternative would be to pass a class name
as a property. When in doubt, use a callback instead of a property{fn5}. If you
are writing a library, you *might* consider supporting both.

The `CollectionView` also registers itself for the `reset` event. The `reset`
event is sent when a collection is updated in bulk. `CollectionView` will then
re-render itself and all its child views. The concept of one view managing its
child views (and their child views) is crucial to writing scalable view code.
Our code is ignoring existing views and just creating new views. We will come
back to this when we talk about other events.

**Note:** Events are the key concept in Backbone. You should know what events
are fired and when by `Backbone.Collection` and `Backbone.Model`. Yes,
you need to know that.

### Rendering an individual Model using a Presenter

At this point we are rendering raw attributes. Looking at `View.renderContext`:

<coderay:javascript>
renderContext: () ->
  if @model?
    @model.toJSON()
  else
    {}
</coderay>

We are copying the model's attributes which are usually just simple types. For
example, our opening weekend total is shown as a number instead of currency.

In Rails, we would use a helper like `number_to_currency`. Instead of using a
helper{fn6}, mustache expects us to give it a formatted currency string as the
opening week total. What we need is a Presenter.

> The presenter acts upon the model and the view. It retrieves data from
repositories (the model), and formats it for display in the view.

&mdash; [Wikipedia](http://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93presenter)

Using a presenter allows to expose the model's attributes in a render-ready way
without adding formatting logic to the model or the view
([commit](https://github.com/leshill/backbone_and_rails_example/commit/f490911062040caf32878e207669307e74042591)).

We add a `Presenter` class{fn7} that wraps a model's attributes. For example,
our presenter formats our opening weekend total:

<coderay:javascript>
class App.Presenters.Movie extends App.Presenter
  opening_weekend: ->
    '$' + format '#,##0.00', @get('opening_weekend')
</coderay>

And we modify `View` to understand presenters by specifying a `presenter`
callback option:

<coderay:javascript>
renderContext: () ->
  if @presenter?
    @presenter.apply @, [@model]
  else if @model?
    @model.toJSON()
  else
    {}
</coderay>

### Responding to Events

We want the collection view to show movies as we add them. And we want the
collection view to remove movies as we delete them. When we edit a movie's
details, we also want to update the list view. Events make this easy.

**Note:** Events also mean our code is loosely coupled. We recently tried an
experiment with a larger, packaged Backbone framework. Since all our code uses
standard events, we were able to wire up a completely new collection view
implementation by changing one line and our UI (add, delete, edit, and more)
just worked.

Adding a new model to a collection fires the `add` event. When we see the `add`
event, our collection view generates a new child view for the newly added
model. Collections will maintain their sort order, so we take advantage of that
to render the new child view in the correct place
([commit](https://github.com/leshill/backbone_and_rails_example/commit/be518c8aa65dc10b7c3a1c7213af5ef5cf5bd26d)).

The event flow goes like this:

* the collection sends an `add` event to its listeners
* the `CollectionView` adds a new child view for the new model

Removing a model from a collection fires the 'destroy' event. When we see the
`destroy` event, our collection view removes the child view for the removed
model
([commit](https://github.com/leshill/backbone_and_rails_example/commit/0c33e4ddea8a8a3e1682889e8af290babcb6d5c7)).

The event flow goes like this:

* the model sends a `destroy` event to its listeners
* the collection containing the model passes the event along to its listeners
* the `CollectionView` destroys its child view

When a view is destroyed, the view should cleanup.  Aside from just being good
practice, leaving dangling objects around, particularly callbacks, can lead to
unexpected and difficult to diagnose behaviors.

Until recently, Backbone had a minimal `remove` that only removed the DOM
element (by now you must be seeing the trend in Backbone.)  On August 15th,
2012, `dispose` was added to Backbone master.  The `dispose` method cleans up
all the events registered via Backbone: the events hash and the model and
collection bindings. Calling `remove` will call `dispose` for you.

Using `remove`/`dispose` covers the core Backbone cleanup. There is no hook
for non-core Backbone cleanup; for example you might use `Backbone.Events` to
trigger events from a widget, `dispose` will not know about them.

Instead of calling `remove`, we are going to use `destroy` which we implement
in our `View` class:

<coderay:javascript>
destroy: ->
  @hide()
  @unbind()
  @remove()
  @
</coderay>

The view is hidden, we `unbind`{fn8}, and then we ask Backbone to cleanup. `unbind`
is the hook to perform our non-core Backbone cleanup. For example,
`CollectionView` could use `unbind` to destroy all of its children when the
parent view is destroyed (and so on if the child views had children).

## Wrap up

Recap!

* render templates; use mustache
* manage your views in a hierarchy; ideally instantiating only a top level view
* use presenters
* leverage events; for example to automatically render and destroy your views
* cleanup after your views

The next installment will cover routers and controllers and how you should be
using them and why Backbone *is not* MVC, even though it *is* MVC.

## TL;DR

Render your views with mustache.

Use presenters instead of using models directly from views.

Use events.

Cleanup when you destroy a view.

Be kind to others; be especially kind to children, the elderly, and animals.

{nf1}
Started using Backbone in 2010 when it seemed that a minor revison happened
every month.
{/nf1}
{nf2}
Not exactly true, it was used at the inaugural Seattle Backbone meetup on July
10th, 2012.
{/nf2}
{nf3}
Seriously, you should use [CoffeeScript](http://coffeescript.org/).
{/nf3}
{nf4}
We are also using `haml` &mdash; `hogan_assets` supports *hamstache* templates
if the `haml` gem is available.
{/nf4}
{nf5}
Although well-established in the JavaScript community, it is not common in
Backbone.  This may have been because using properties was how you configured
your Backbone.js objects. This has changed in the past year with more examples
using configuration via code.
{/nf5}
{nf6}
[handlebars.js](http://handlebarsjs.com/) is a mustache superset that allows
adding helpers into your mustache templates. Use
[handlebars\_assets](https://github.com/leshill/handlebars_assets) to compile
your handlebars templates in the asset pipeline.
{/nf6}
{nf7}
The
[implementation](https://github.com/leshill/backbone_and_rails_example/blob/master/app/assets/javascripts/app/presenter.js.coffee)
is simple.
{/nf7}
{nf8}
Our example app is using an older version of Backbone so we do the work of
`dispose` in our `unbind` implementation. Usually `unbind` is matched with
another method for setup.
{/nf8}
