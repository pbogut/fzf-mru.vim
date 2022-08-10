local conf = require('telescope.config').values
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')

local function list()
  local files = vim.fn['fzf_mru#mrufiles#raw_list']()
  local results = {}
  -- @todo get oPtions with defaults simillary to vimscript version
  local exclude_curent_file = vim.g.fzf_mru_exclude_current_file == nil
    or vim.g.fzf_mru_exclude_current_file == true
    or  vim.g.fzf_mru_exclude_current_file > 0

  for _, path in pairs(files) do
    if not exclude_curent_file or path ~= vim.fn.expand('%:p') then
      results[#results+1] = path
    end
  end

  return results
end

local function picker(opts, results)
  return pickers
    .new(opts or {}, {
      prompt_title = 'Most Recent Files',
      finder = finders.new_table({
        results = results,
      }),
      previewer = conf.file_previewer(opts),
      sorter = conf.generic_sorter(opts),
    })
end

local fzf_mru = function(opts)
  opts = opts or {}
  local results = vim.fn['fzf_mru#mrufiles#source']()
  picker(opts, results):find()
end

local current_path = function(opts)
  opts = opts or {}
  local files = list()
  local results = {}
  local cwd = vim.fn.getcwd()

  for _, path in pairs(files) do
    if path:sub(1, #cwd) == cwd then
      results[#results+1] = path:sub(#cwd+2)
    end
  end

  picker(opts, results):find()
end

local all_files = function(opts)
  opts = opts or {}
  local files = list()
  local results = {}
  local cwd = vim.fn.getcwd()

  for _, path in pairs(files) do
    results[#results+1] = path:sub(1, #cwd) == cwd and path:sub(#cwd+2) or path
  end

  picker(opts, results):find()
end

return require('telescope').register_extension({
  exports = {
    fzf_mru = fzf_mru,
    current_path = current_path,
    all = all_files,
  },
})
