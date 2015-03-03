middleman-swiftype
==================

A swiftype sync extension for middleman.

This extension adds a middleman command `swiftype`. You can run it by executing `middleman swiftype`.

This command pushes your content to the [swiftype search api](https://swiftype.com/).

In contrast to the swiftype crawler it only pushes content you want to be searched. So no indexing of menu items, headers or footers but only usable content.

This extension also supports the swiftype sections. So you can use the tagged categories/tags as keywords for the search.
I, for example, add tags to every post but I don't show them on my blog. However, those can be used for searching this way.

## Configuration ##

A lot of this extension can be configured by using lambda's. This is the example config that comes with swiftype and is based on my own configuration:

```
# Configuration of the swiftype extension
activate :swiftype do |swiftype|
  swiftype.api_key = 'MY_SECRET_API_KEY'
  swiftype.engine_slug = 'my_awesome_blog'
  swiftype.pages_selector = lambda { |p| p.path.match(/\.html/) && p.metadata[:options][:layout] == nil }
  swiftype.title_selector = lamda { |mm_instance, p| '...' }
  swiftype.process_html = lambda { |f| f.search('.//div[@class="linenodiv"]').remove }
  swiftype.generate_sections = lambda { |p| (p.metadata[:page]['tags'] ||= []) + (p.metadata[:page]['categories'] ||= []) }
  swiftype.generate_info = lambda { |f| TruncateHTML.truncate_html(strip_img(f.to_s), blog.options.summary_length, '...') }
  swiftype.exclude_empty_titles = true
end
```

`swiftype.api_key` and `swiftype.engine_slug` are required. The rest of the options are optional.

The api key and engine slug can be found in the swiftype dashboard.

The `pages_selector` can be used to filter the pages that are searchable. If this option is not used all pages will be searched. So this will include any rss or atom feeds generated.

The `title_selector` can be used to look up a page's title (for each page). For example, maybe you store the titles in a customized table of contents file.

`process_html` can be used for transforming the html content that will be send to swiftype. In my example I'm using this to remove line numbers in code blocks: I don't want them to be searchable by swiftype.

`generate_sections` can be used for search keywords you want to use but are not in the main content. I base mine on the categories & tags for a post.

`generate_info` is an option that can be used for anything. _I_ use it for storing the summary of each post.

`exclude_empty_titles` will skip indexing resources which do not have a title if set to true