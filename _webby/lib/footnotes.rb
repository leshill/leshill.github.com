Webby::Filters.register :footnote do |input|
  input.gsub(/\{fn(\d+)\}/) do |s|
    "<sup class='footnote' id='fnr#{$1}'><a href='#fn#{$1}'>#{$1}</a></sup>"
  end
end

Webby::Filters.register :notefoot do |input|
  input.gsub(/\{nf(\d+)\}(.*)\{\/nf\1\}/m) do |s|
    "<p class='footnote' id='fn#{$1}'><a href='#fn#{$1}'><sup>#{$1}</sup></a>#{$2}</p>"
  end
end
