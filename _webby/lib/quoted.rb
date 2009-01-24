def properly_quoted(text)
  quote = "'"
  quote = '"' if text.index("'")
  quote + text + quote
end
