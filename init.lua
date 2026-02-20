vim.g.mapleader = " "
vim.g.maplocalleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, 
    config = function()
      local function get_current_flavor()
        local f = io.open(vim.fn.expand("~/.config/nvim/current_flavor"), "r")
        if f then
          local flavor = f:read("*a"):gsub("%s+", "") 
          f:close()
          if flavor == "latte" then return "latte" end
        end
        return "mocha" 
      end

      require("catppuccin").setup({ 
        flavour = get_current_flavor(),
        integrations = { ts_rainbow = true } 
      })
      vim.cmd.colorscheme("catppuccin-" .. get_current_flavor())

      vim.api.nvim_create_autocmd("Signal", {
        pattern = "SIGUSR1",
        callback = function()
          local new_flavor = get_current_flavor()
          vim.cmd("colorscheme catppuccin-" .. new_flavor)
        end,
      })
    end 
  },
  { "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({
        view_options = { show_hidden = true },
        float = { padding = 2, border = "rounded" },
      })
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    end
  },
  { "folke/zen-mode.nvim",
    opts = {
      window = { width = 85, options = { number = false, relativenumber = false, signcolumn = "no", foldcolumn = "0" } },
      plugins = { options = { enabled = true, laststatus = 0 }, twilight = { enabled = true } },
    }
  },
  { 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function() require('lualine').setup({ options = { theme = 'catppuccin' } }) end 
  },
  { "vim-scripts/fountain.vim", ft = "fountain" },
})

local ns_id = vim.api.nvim_create_namespace("FountainLive")

local function apply_indent(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local state = "NORMAL" 
  
  for i, line in ipairs(lines) do
    local clean = line:gsub("^%s*", ""):gsub("%s*$", "")
    local indent_spaces = 0 
    
    if clean == "" then
      state = "NORMAL"
      goto continue
    end
    
    if clean:match("^[A-Z%s]+ TO:$") or clean:match("^FADE IN:$") or clean:match("^FADE OUT$") or clean:match("^>") then
      indent_spaces = 60
      state = "NORMAL"
    elseif state == "NORMAL" then
      local is_char = false
      if clean:match("^@") then
        is_char = true
      elseif clean:match("^[A-Z%s%d%p]+$") and not clean:match("^[IE][NX]T%.") then
        local next_line = lines[i+1] and lines[i+1]:gsub("^%s*", ""):gsub("%s*$", "") or ""
        if next_line ~= "" and not clean:match("%?$") then
          is_char = true
        end
      end
      
      if is_char then
        indent_spaces = 35 
        state = "CHARACTER"
      else
        indent_spaces = 15 
        state = "NORMAL"
      end
    elseif state == "CHARACTER" or state == "DIALOGUE" or state == "PARENTHETICAL" then
      if clean:match("^%(") then
        indent_spaces = 30 
        state = clean:match("%)%s*$") and "DIALOGUE" or "PARENTHETICAL"
      elseif state == "PARENTHETICAL" then
        indent_spaces = 30
        if clean:match("%)%s*$") then state = "DIALOGUE" end
      else
        indent_spaces = 25 
        state = "DIALOGUE"
      end
    end
    
    if indent_spaces > 0 then
      local spaces = string.rep(" ", indent_spaces)
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, i-1, 0, { virt_text = {{spaces, "None"}}, virt_text_pos = "inline" })
    end
    
    ::continue::
  end
end

local function update_fountain_margins()
  local row = vim.fn.line('.') - 1
  local block_start = row
  while block_start > 0 do
    local prev = vim.api.nvim_buf_get_lines(0, block_start - 1, block_start, false)[1]
    if prev:match("^%s*$") then break end
    block_start = block_start - 1
  end
  
  local state = "NORMAL"
  local current_line_state = "NORMAL"
  local lines = vim.api.nvim_buf_get_lines(0, block_start, row + 1, false)
  for i, l in ipairs(lines) do
    l = l:gsub("^%s*", ""):gsub("%s*$", "")
    
    if i == 1 then
      if l:match("^@") or (l:match("^[A-Z%s%d%p]+$") and not l:match("^[IE][NX]T%.") and not l:match("TO:$") and not l:match("^FADE ") and not l:match("^>")) then
        state = "CHARACTER"
        current_line_state = "CHARACTER"
      else
        state = "NORMAL"
        current_line_state = "NORMAL"
        break
      end
    else
      if state == "CHARACTER" or state == "DIALOGUE" or state == "PARENTHETICAL" then
        if l:match("^%(") then
          current_line_state = "PARENTHETICAL"
          state = l:match("%)%s*$") and "DIALOGUE" or "PARENTHETICAL"
        elseif state == "PARENTHETICAL" then
          current_line_state = "PARENTHETICAL"
          if l:match("%)%s*$") then state = "DIALOGUE" end
        else
          current_line_state = "DIALOGUE"
          state = "DIALOGUE"
        end
      end
    end
  end
  
  if current_line_state == "DIALOGUE" then
    vim.opt_local.textwidth = 60
  elseif current_line_state == "PARENTHETICAL" then
    vim.opt_local.textwidth = 30
  elseif current_line_state == "CHARACTER" then
    vim.opt_local.textwidth = 0
  else
    vim.opt_local.textwidth = 80 
  end
end

_G.FountainCharComplete = function(findstart, base)
  if findstart == 1 then
    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col('.') - 1
    local before = line:sub(1, col)
    local start_idx = before:find("[A-Z0-9]+$")
    return start_idx and (start_idx - 1) or col
  else
    local chars, seen = {}, {}
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    
    for _, l in ipairs(lines) do
      local clean = l:gsub("^%s*", ""):gsub("%s*$", "")
      if clean ~= "" and clean:match("^[A-Z][A-Z%s%d%p]*$") and not clean:match("^[IE][NX]T%.") and not clean:match("TO:$") and not clean:match("^FADE ") and not clean:match("^>") then
         if not seen[clean] then
           table.insert(chars, { word = clean, menu = "[Character]" })
           seen[clean] = true
         end
      end
    end
    
    local res = {}
    for _, c in ipairs(chars) do
      if c.word:sub(1, #base) == base then
        table.insert(res, c)
      end
    end
    return res
  end
end

vim.opt.termguicolors = true
vim.filetype.add({ extension = { fountain = "fountain" } })

local default_scrolloff = 8
local typewriter_group = vim.api.nvim_create_augroup("TypewriterMode", { clear = true })

vim.api.nvim_create_user_command("TypewriterToggle", function()
  if vim.o.scrolloff == 999 then
    vim.o.scrolloff = default_scrolloff
    vim.api.nvim_clear_autocmds({ group = typewriter_group })
    
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local first, last = 1, #lines
    while first <= #lines and lines[first] == "" do first = first + 1 end
    while last >= 1 and lines[last] == "" do last = last - 1 end
    if first > last then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {""})
    else
      if last < #lines then vim.api.nvim_buf_set_lines(0, last, -1, false, {}) end
      if first > 1 then vim.api.nvim_buf_set_lines(0, 0, first - 1, false, {}) end
    end
  else
    vim.o.scrolloff = 999
    
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "TextChangedI" }, {
      group = typewriter_group,
      callback = function()
        local win_height = vim.api.nvim_win_get_height(0)
        local half_screen = math.floor(win_height / 2)
        local total_lines = vim.fn.line('$')
        
        local top_padding = 0
        for i = 1, total_lines do
          if vim.fn.getline(i) == "" then top_padding = top_padding + 1 else break end
        end
        if top_padding == total_lines then top_padding = total_lines - 1 end
        
        local cursor_row = vim.fn.line('.')
        local real_cursor_row = math.max(1, cursor_row - top_padding)
        local desired_top = math.max(0, half_screen - real_cursor_row)
        
        if top_padding < desired_top then
          local add = {} for _=1, (desired_top - top_padding) do table.insert(add, "") end
          vim.api.nvim_buf_set_lines(0, 0, 0, false, add)
        elseif top_padding > desired_top then
          vim.api.nvim_buf_set_lines(0, 0, top_padding - desired_top, false, {})
        end
        
        total_lines = vim.fn.line('$')
        cursor_row = vim.fn.line('.')
        local bottom_padding = 0
        for i = total_lines, 1, -1 do
          if vim.fn.getline(i) == "" then bottom_padding = bottom_padding + 1 else break end
        end
        if bottom_padding == total_lines then bottom_padding = total_lines - 1 end
        
        local real_lines_below = math.max(0, total_lines - bottom_padding - cursor_row)
        local desired_bottom = math.max(0, half_screen - real_lines_below)
        
        if bottom_padding < desired_bottom then
          local add = {} for _=1, (desired_bottom - bottom_padding) do table.insert(add, "") end
          vim.api.nvim_buf_set_lines(0, total_lines, total_lines, false, add)
        elseif bottom_padding > desired_bottom then
          vim.api.nvim_buf_set_lines(0, total_lines - (bottom_padding - desired_bottom), total_lines, false, {})
        end
      end,
    })
    
    vim.cmd("doautocmd CursorMoved")
    vim.cmd("normal! zz")
  end
end, {})

vim.keymap.set("n", "<leader>tw", ":TypewriterToggle<CR>")
vim.keymap.set("n", "<leader>f", "gqip")

vim.api.nvim_create_user_command("FountainFormat", function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local formatted_lines = {}
  local state = "NORMAL"

  for _, line in ipairs(lines) do
    local l = line:gsub("^%s*", ""):gsub("%s*$", "")

    if l == "" then
      state = "NORMAL"
      table.insert(formatted_lines, "")
    else
      local current_line_state = state
      
      if l:match("^[A-Z%s]+ TO:$") or l:match("^FADE IN:$") or l:match("^FADE OUT$") or l:match("^>") then
         state = "NORMAL"
         current_line_state = "NORMAL"
      elseif state == "NORMAL" then
        if l:match("^@") or (l:match("^[A-Z%s%d%p]+$") and not l:match("^[IE][NX]T%.") and not l:match("%?")) then
          state = "CHARACTER"
          current_line_state = "CHARACTER"
        else
          state = "NORMAL"
          current_line_state = "NORMAL"
        end
      elseif state == "CHARACTER" or state == "DIALOGUE" or state == "PARENTHETICAL" then
        if l:match("^%(") then
          current_line_state = "PARENTHETICAL"
          state = l:match("%)%s*$") and "DIALOGUE" or "PARENTHETICAL"
        elseif state == "PARENTHETICAL" then
          current_line_state = "PARENTHETICAL"
          if l:match("%)%s*$") then state = "DIALOGUE" end
        else
          current_line_state = "DIALOGUE"
          state = "DIALOGUE"
        end
      end

      local max_len = 80 
      if current_line_state == "DIALOGUE" then max_len = 35 end
      if current_line_state == "PARENTHETICAL" then max_len = 30 end

      if current_line_state == "CHARACTER" then
        table.insert(formatted_lines, l)
      else
        local remaining = l
        while #remaining > max_len do
          local search_area = remaining:sub(1, max_len + 1)
          local last_space = nil
          for j = #search_area, 1, -1 do
            if search_area:sub(j, j) == " " then
              last_space = j
              break
            end
          end

          if last_space then
            table.insert(formatted_lines, remaining:sub(1, last_space - 1))
            remaining = remaining:sub(last_space + 1)
          else
            table.insert(formatted_lines, remaining:sub(1, max_len))
            remaining = remaining:sub(max_len + 1)
          end
        end
        if remaining ~= "" then
          table.insert(formatted_lines, remaining)
        end
      end
    end
  end
  
  vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_lines)
end, {})

local metadata_commands = {
  FountainTitle   = "Title",
  FountainCredits = "Credit",
  FountainAuthor  = "Author",
  FountainNotes   = "Notes",
  FountainContact = "Contact"
}

for cmd_name, tag in pairs(metadata_commands) do
  vim.api.nvim_create_user_command(cmd_name, function(opts)
    vim.api.nvim_buf_set_lines(0, 0, 0, false, { tag .. ": " .. opts.args })
  end, { nargs = "+" })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "fountain",
  callback = function(args)
    local bufnr = args.buf
    
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true 
    vim.opt_local.formatoptions:append("t") 
    
    vim.bo[bufnr].omnifunc = "v:lua.FountainCharComplete"
    vim.opt_local.completeopt = { "menuone", "noselect", "noinsert" }
    
    apply_indent(bufnr)

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      buffer = bufnr,
      callback = function() vim.schedule(update_fountain_margins) end
    })

    vim.api.nvim_buf_attach(bufnr, false, {
      on_lines = function() vim.schedule(function() apply_indent(bufnr) end) end
    })
    
    vim.api.nvim_create_autocmd("TextChangedI", {
      buffer = bufnr,
      callback = function()
        local line = vim.api.nvim_get_current_line()
        local col = vim.fn.col('.') - 1
        local before_cursor = line:sub(1, col)
        
        if before_cursor:match("^%s*[A-Z]+$") then
          if vim.fn.pumvisible() == 0 then
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true), "n", true)
          end
        end
      end
    })

    vim.keymap.set("i", "<CR>", function()
      if vim.fn.pumvisible() == 1 then
        return vim.api.nvim_replace_termcodes("<C-y>", true, false, true)
      else
        return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
      end
    end, { buffer = bufnr, expr = true })
    
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local first = 1
        local last = #lines
        while first <= #lines and lines[first] == "" do first = first + 1 end
        while last >= 1 and lines[last] == "" do last = last - 1 end
        if first > last then
          vim.api.nvim_buf_set_lines(0, 0, -1, false, {""})
        else
          if last < #lines then vim.api.nvim_buf_set_lines(0, last, -1, false, {}) end
          if first > 1 then vim.api.nvim_buf_set_lines(0, 0, first - 1, false, {}) end
        end
      end
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
      buffer = bufnr,
      callback = function()
        if vim.o.scrolloff == 999 then vim.cmd("doautocmd CursorMoved") end
      end
    })

    vim.keymap.set("n", "<leader>z", ":ZenMode<CR>", { buffer = bufnr })
    vim.keymap.set("n", "<leader>p", function()
      local input = vim.fn.expand("%:p")
      local output = vim.fn.expand("%:p:h") .. "/Exports/" .. vim.fn.expand("%:t:r") .. ".pdf"
      if vim.fn.isdirectory(vim.fn.expand("%:p:h") .. "/Exports") == 0 then vim.fn.mkdir(vim.fn.expand("%:p:h") .. "/Exports", "p") end
      
      vim.cmd("write")
      
      local cmd = string.format("afterwriting --source %s --pdf %s --overwrite 2>&1", vim.fn.shellescape(input), vim.fn.shellescape(output))
      vim.fn.system(cmd)
    end, { buffer = bufnr })
  end,
})