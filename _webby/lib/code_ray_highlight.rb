Webby::Filters.register :coderay do |text|
  text.gsub(%r{<coderay(\:(\w+))?>(.+?)</coderay>}m) do |match|
    src = $~[3].strip
    lang = $~[2] || :ruby
    CodeRay.scan(src, lang).html(:line_numbers => :inline, :wrap => :div)
  end
end

