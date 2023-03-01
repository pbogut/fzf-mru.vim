local utils = require('fzf_mru.utils')
local sqlite = require('fzf_mru.sqlite')
local fn = vim.fn
local g = vim.g

local M = {}
local l = {}

local config = {
  exclude = {},
  store_max = 10000,
  show_max = 500,
}

for option, _ in pairs(config) do
  if g['fzf_mru_lua_' .. option] then
    config[option] = g['fzf_mru_lua_' .. option]
  end
end

local file_path = fn.stdpath('data') .. '/fzf_mru/mru.db'
local locked = false

function M.display(filters)
  local options = {
    source = l.file_list_source(filters),
    options = '--prompt "MRU> " ' .. (vim.g.fzf_preview or ''),
    sink = 'e',
  }
  fn['fzf#run'](fn['fzf#wrap'](options))
end

function M.add(buf_nr)
  if locked then return end

  local buf_name = fn.bufname(buf_nr) or ''

  if buf_nr > 0 and buf_name ~= '' and utils.file_exists(buf_name) then
    local full_name = fn.fnamemodify(buf_name, ':p')
    if l.should_exclude(full_name) then
      return
    end
    sqlite.insert(l.file_record(full_name))
  end
end

function M.truncate()
  if config.store_max and config.store_max > 0 then
    sqlite.truncate(config.store_max)
  end
end

function M.lock()
  locked = true
end

function M.unlock()
  locked = false
end

function l.file_record(file_name)
  return {
    name = file_name,
    cwd = fn.getcwd(),
    branch = utils.get_git_branch() or '',
  }
end

function l.cwd_pattern()
  local cwd = fn.getcwd()
  return cwd:gsub('([^%w])', '%%%1')
end

function l.sanitize_config()
  if config.exclude and type(config.exclude) ~= 'table' then
    print('[FZF  MRU]: ' .. 'exclude should be a table, ' .. type(config.exclude) .. ' given.')
    config.exclude = {}
  end
  if config.show_max and type(config.show_max) ~= 'number' then
    print('[FZF  MRU]: ' .. 'show_max should be a number, ' .. type(config.exclude) .. ' given.')
    config.exclude = {}
  end
end

function l.should_exclude(file_name)
  if config.exclude then
    for _, pattern in pairs(config.exclude) do
      if file_name:match(pattern) then
        return true
      end
    end
  end

  return false
end

function l.prepare_filters(filters)
  filters = filters or {}
  if not filters.show_max and config.show_max then
    filters.show_max = config.show_max
  end
  return filters
end

function l.file_list_source(filters)
  filters = l.prepare_filters(filters)
  sqlite.database(file_path)
  local list = sqlite.get(filters)

  local cwd = l.cwd_pattern()
  local cur_file = fn.expand('%:p')
  local cur_relative = fn.expand('%:.')

  list = utils.filter(list, function(file)
    -- hide current file
    if file.name == cur_file or file.name == cur_relative then
      return false
    end

    if l.should_exclude(file.name) then
      return false
    end

    -- check if file exists
    return utils.file_exists(file.name)
  end)

  -- display_relative if possible
  list = utils.map(list, function(file)
    return file.name:gsub('^' .. cwd .. '/', '')
  end)
  return list
end

utils.augroup('fzf_mru_lua', {
    BufAdd = {'*', [[call v:lua.fzf_mru.add(expand('<abuf>', 1) + 0)]]},
    BufEnter = {'*', [[call v:lua.fzf_mru.add(expand('<abuf>', 1) + 0)]]},
    BufLeave = {'*', [[call v:lua.fzf_mru.add(expand('<abuf>', 1) + 0)]]},
    BufWritePost = {'*', [[call v:lua.fzf_mru.add(expand('<abuf>', 1) + 0)]]},
    QuickFixCmdPre = {'*', [[call v:lua.fzf_mru.lock()]]},
    QuickFixCmdPost  = {'*', [[call v:lua.fzf_mru.unlock()]]},
    VimLeavePre = {'*', [[call v:lua.fzf_mru.truncate()]]},
})

l.sanitize_config()

-- add member functions to v:lua.fzf_mru.*
_G.fzf_mru = _G.fzf_mru or {}
for name, func in pairs(M) do
  _G.fzf_mru[name] = func
end

return M
