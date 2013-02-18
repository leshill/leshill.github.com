---
title:      'Tip: Run Jasmine From RSpec'
author: Les Hill
created_at: 2013-02-18 14:14:43.260472 -08:00
layout: blog_post
extension: html
blog_post:  true
filter:
  - gist
  - coderay
  - markdown
  - footnote
  - notefoot
---
Want to run your Jasmine suite from your RSpec suite? Easy. Take a look at this [gist](https://gist.github.com/2059):

gist4981365.

Add `jasmine_spec.rb` to your `specs/features` and enjoy.

We are using [jasminerice](https://github.com/bradphelan/jasminerice) to run our [CoffeeScript](http://coffeescript.org) suite. You might need to tweak this if you are running Jasmine some other way in your app.

Hat tip to [Sandro](https://github.com/sandro) who wrote this for our app.
