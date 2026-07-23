-- Reserve [[ and ]] for Tree-sitter scope boundaries instead of illuminate's
-- reference navigation (which remains available through its other commands).
return {
  "RRethy/vim-illuminate",
  keys = {
    { "[[", false },
    { "]]", false },
  },
}
