-- Inline color previews: highlights `#rrggbb`, `rgb(...)`, named colors, etc.
-- with their actual color, right in the buffer.
--
-- Uses the maintained `catgoose` fork — the original `norcalli/nvim-colorizer`
-- is archived/unmaintained. Drop-in compatible, faster, more filetypes.
-- Lazy-loaded on BufReadPre so it doesn't cost anything at startup.
return {
  "catgoose/nvim-colorizer.lua",
  event = "BufReadPre",
  opts = {},
}
