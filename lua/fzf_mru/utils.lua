local M = {}

local cmd = vim.cmd
local fn = vim.fn

function M.augroup(group_name, definitions)
  cmd('augroup ' .. group_name)
  cmd('autocmd!')
  for event_type, definition in pairs(definitions) do
    if type(definition[1]) ~= 'table' then
      definition = {definition}
    end
    for _, def in pairs(definition) do
      local callback = table.remove(def, #def)

      table.insert(def, 1, 'autocmd')
      table.insert(def, 2, event_type)
      local command = table.concat(def, ' ')
      command = command .. ' ' .. callback
      cmd(command)
    end
  end
  cmd('augroup END')
end

function M.file_exists(file_name)
  return fn.filereadable(file_name) > 0
end

function M.is_dir(dir_name)
  return fn.isdirectory(dir_name) > 0
end

function M.make_parent_dir(file)
  fn.system('mkdir -p ' .. fn.fnamemodify(file, ':h'))
end

function M.map(tab, callback)
  local result = {}
  for index, element in ipairs(tab) do
    result[#result+1] = callback(element, index)
  end

  return result
end

function M.filter(tab, callback)
  local result = {}
  for index, element in ipairs(tab) do
    if callback(element, index) then
      result[#result+1] = element
    end
  end

  return result
end

-- Adapted from from clink-completions' git.lua
function M.get_git_dir(path)

  -- Checks if provided directory contains git directory
  local function has_git_dir(dir)
    local git_dir = dir..'/.git'
    if M.is_dir(git_dir) then return git_dir end
  end

  -- Get git directory from git file if present
  local function has_git_file(dir)
    local gitfile = io.open(dir..'/.git')
    if gitfile ~= nil then
      local git_dir = gitfile:read():match('gitdir: (.*)')
      gitfile:close()

      return git_dir
    end
  end

  local function parent_pathname(pathname)
    local i = pathname:find("[\\/:][^\\/:]*$")
    if not i then return end
    return pathname:sub(1, i-1)
  end

  -- If path nil or '.' get the absolute path to current directory
  if not path or path == '.' then
    path = vim.fn.getcwd()
  end

  local git_dir
  -- Check in each path for a git directory, continues until found or reached
  -- root directory
  while path do
    -- Try to get the git directory checking if it exists or from a git file
    git_dir = has_git_dir(path) or has_git_file(path)
    if git_dir ~= nil then
      break
    end
    -- Move to the parent directory, nil if there is none
    path = parent_pathname(path)
  end

  if not git_dir then return end

  -- Check if git directory is absolute path or a relative
  if git_dir:sub(1,1) == '/' then
    return git_dir
  end
  return  path .. '/' .. git_dir
end


function M.get_git_branch()
  if vim.bo.filetype == 'help' then return end
  local current_file = vim.fn.expand('%:p')
  local current_dir

  -- If file is a symlinks
  if vim.fn.getftype(current_file) == 'link' then
    local real_file = vim.fn.resolve(current_file)
    current_dir = vim.fn.fnamemodify(real_file,':h')
  else
    current_dir = vim.fn.expand('%:p:h')
  end

  local _,gitbranch_pwd = pcall(vim.api.nvim_buf_get_var,0,'gitbranch_pwd')
  local _,gitbranch_path = pcall(vim.api.nvim_buf_get_var,0,'gitbranch_path')
  if gitbranch_path and gitbranch_pwd then
    if gitbranch_path:find(current_dir) and string.len(gitbranch_pwd) ~= 0 then
      return  gitbranch_pwd
    end
  end
  local git_dir = M.get_git_dir(current_dir)
  if not git_dir then return end

  -- The function get_git_dir should return the root git path with '.git'
  -- appended to it. Otherwise if a different gitdir is set this substitution
  -- doesn't change the root.
  local git_root = git_dir:gsub('/.git/?$','')

  -- If git directory not found then we're probably outside of repo or
  -- something went wrong. The same is when head_file is nil
  local head_file = io.open(git_dir..'/HEAD')
  if not head_file then return end

  local HEAD = head_file:read()
  head_file:close()

  -- If HEAD matches branch expression, then we're on named branch
  -- otherwise it is a detached commit
  local branch_name = HEAD:match('ref: refs/heads/(.+)')
  if branch_name == nil then return  end

  vim.api.nvim_buf_set_var(0,'gitbranch_pwd',branch_name)
  vim.api.nvim_buf_set_var(0,'gitbranch_path',git_root)

  return branch_name
end

return M
