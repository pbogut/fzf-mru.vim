local utils = require('fzf_mru.utils')
local M = {}
local l = {}

local fn = vim.fn

local db_file = nil
local created = false

function M.database(file)
  if db_file ~= file then
    created = false
    db_file = file
  end
  if not created then
    if not utils.file_exists(file) then
      utils.make_parent_dir(file)
    end
    M.create()
  end
end

function M.create()
  local create_table =
    [[CREATE TABLE IF NOT EXISTS mru_files (
          name TEXT NOT NULL,
          branch TEXT NOT NULL DEFAULT '',
          cwd TEXT NOT NULL DEFAULT '',
          touched datetime DEFAULT current_timestamp,
          UNIQUE (name, branch, cwd)
      );
    ]]

  local result = fn.system({'sqlite3', db_file}, create_table)
  if result ~= '' then
    print('CREATE TABLE ERROR: ' .. result)
  end
end

function M.insert(record)
  local query = 'INSERT INTO mru_files (name, branch, cwd) VALUES ('
    .. l.quote(record.name) .. ','
    .. l.quote(record.branch) .. ','
    .. l.quote(record.cwd or fn.getcwd()) .. ')'
    .. [[ ON CONFLICT(name, branch, cwd) DO UPDATE SET touched=datetime('now')]]

  local result = fn.system({'sqlite3', db_file}, query)
  if result ~= '' then
    print('INSERT ERROR: ' .. result)
  end
end

function M.get_all()
  local query = [[SELECT DISTINCT name FROM mru_files ORDER BY touched DESC]]
  local result = fn.system({'sqlite3', '--json', db_file}, query)
  return l.decode(result)
end


function M.get(filter)
  filter = filter or {}

  local query = 'SELECT DISTINCT name as name FROM mru_files'
  if filter.relative then
    query = 'SELECT DISTINCT ' .. l.cut_cwd(l.relative_name)
      .. ' as name FROM mru_files'
  end

  local where = l.get_where_from_filter(filter)

  if #where > 0 then
    query = query .. ' WHERE ' .. table.concat(where, ' AND ')
  end

  query = query .. ' ORDER BY touched DESC'
  if filter.show_max and filter.show_max > 0 then
    query = query .. ' LIMIT ' .. filter.show_max
  end
  return l.query(query)
end

function M.truncate(count)
  local rowids = [[SELECT rowid FROM mru_files ORDER BY touched DESC
    LIMIT -1 OFFSET ]] .. count;
  local query = 'DELETE FROM mru_files where rowid in (' .. rowids .. ')'
  return l.query(query)
end

l.relative_name = [[
    SUBSTR(name, IIF(LENGTH(cwd) AND name LIKE cwd || '%', LENGTH(cwd)+2, 1))]]

function l.query(query)
  local result = fn.system({'sqlite3', '--json', db_file}, query)
  return l.decode(result)
end

function l.decode(set)
  if type(set) == 'string' and set ~= '' then
    return fn.json_decode(set)
  end

  return {}
end

function l.quote(val)
  return fn.json_encode(val)
end


function l.cut_cwd(field)
  local cwd = fn.getcwd()
  return 'SUBSTR(' .. field .. ', IIF(' .. field .. ' LIKE '
  .. l.quote(cwd .. '%') .. ', LENGTH(' .. l.quote(cwd) .. ')+2, 1))'
end

function l.get_filter(filter, name, default)
  if filter[name] == true then
    filter[name] = default
  end
  if type(filter[name]) == 'string' then
    return name .. ' = ' .. l.quote(filter.branch)
  end

  return nil
end

function l.get_in_cwd_filter(filter)
  if filter.in_cwd == true then
    filter.in_cwd = fn.getcwd()
  end
  if type(filter.in_cwd) == 'string' then
    return 'name LIKE ' .. l.quote(filter.in_cwd .. '%')
  end

  return nil
end

function l.get_where_from_filter(filter)
  local where = {}
  if filter.branch and not filter.in_cwd then
    filter.in_cwd = true
  end

  where[#where+1] = l.get_filter(filter, 'branch', utils.get_git_branch())
  where[#where+1] = l.get_filter(filter, 'cwd', fn.getcwd())
  where[#where+1] = l.get_in_cwd_filter(filter)

  return where
end

return M
