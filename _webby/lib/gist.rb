Webby::Filters.register :gist do |input|
  if ENV['NO_GIST']
    input
  else
    input.gsub(/gist(\d+)\./) { |s| "<script src='http://gist.github.com/#{$1}.js'></script>" }
  end
end
