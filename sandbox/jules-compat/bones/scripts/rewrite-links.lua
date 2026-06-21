-- bones/scripts/rewrite-links.lua
-- Pandoc Lua filter to rewrite internal .md links to .html
-- This allows writing documentation with .md links so they work in editors,
-- while rendering the HTML output to use .html links.

function Link(el)
  -- Ignore absolute URLs (http, https, mailto, etc)
  if not el.target:match("^%a+://") and not el.target:match("^mailto:") then
    -- Replace .md at the end of the URL
    el.target = el.target:gsub("%.md$", ".html")
    -- Replace .md followed by a # fragment
    el.target = el.target:gsub("%.md#", ".html#")
  end
  return el
end
