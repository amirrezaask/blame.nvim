# blame.nvim
Show git blame message for line under cursor. updates on each cursor movement

# Installation
```lua
use { 'amirrezaask/blame.nvim', requires = {{"nvim-lua/plenary.nvim"}}}
```

# Usage
```lua
-- sets up the autocmd for each cursor movements
require('blame').setup()
-- or do it manually for current line using
require('blame').blame()
```
