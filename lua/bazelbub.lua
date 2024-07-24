local log = require('log')
local plenary = require('plenary')

local api, fn = vim.api, vim.fn

local has_plenary, Float = pcall(require, "plenary.window.float")
if not has_plenary then
  log.error("Please install nvim-lua/plenary.nvim")
end

function highlight_passed(bufid, hlname, match_string, hlcolor)
  vim.api.nvim_set_hl(0, hlname, { fg = hlcolor })

  local lines = vim.api.nvim_buf_get_lines(bufid, 0, -1, true)
  local occurrences = {}

  for line_nr, line in ipairs(lines) do
    local start_col = 1
    while true do
      local s, e = line:find(match_string, start_col, true)
      if not s then break end
      table.insert(occurrences, { line_nr - 1, s - 1 })
      start_col = e + 1
    end
  end

  -- Add highlights for each occurrence
  for _, occurrence in ipairs(occurrences) do
    local line_nr, col = unpack(occurrence)
    vim.api.nvim_buf_add_highlight(bufid, -1, hlname, line_nr, col, col + string.len(match_string))
  end
end

function showFloatWindow(title, content)
  local float = Float.percentage_range_window(0.6, 0.3, { winblend = 5 }, {
    title = title,
    titlehighlight = "Bazel",
    topleft = "┌",
    topright = "┐",
    top = "─",
    left = "│",
    right = "│",
    botleft = "└",
    botright = "┘",
    bot = "─",
  })

  api.nvim_buf_set_lines(float.bufnr, 0, -1, true, content)
  highlight_passed(float.bufnr, 'MyPassed', 'PASSED', '#00FF00')
  highlight_passed(float.bufnr, 'MySuccess', 'successfully', '#00FF00')
  highlight_passed(float.bufnr, 'MyFailed', 'FAILED', '#FF0000')
  api.nvim_buf_set_keymap(float.bufnr, "n", "q", "<cmd>close!<CR>", { nowait = true, noremap = true, silent = true })
  api.nvim_set_option_value("readonly", true, { buf = float.bufnr })
end

function getBazelTestDependencies(file)
    local executeCommand = string.format("bazel query 'kind(test, rdeps(//..., %s))' --keep_going; echo $?", file)

    local handle = io.popen(executeCommand)
    local output = {}

    for line in handle:lines() do
        table.insert(output, line)
    end

    -- Close the handle
    handle:close()

    -- Get the exit code from the last line of the output
    local exitCode = tonumber(table.remove(output))
    return output, exitCode
end

function getBazelAllDependencies(file)
    local executeCommand = string.format("bazel query 'rdeps(//..., %s)' --keep_going; echo $?", file)

    local handle = io.popen(executeCommand)
    local output = {}

    for line in handle:lines() do
        table.insert(output, line)
    end

    -- Close the handle
    handle:close()

    -- Get the exit code from the last line of the output
    local exitCode = tonumber(table.remove(output))
    return output, exitCode
end

--- Run a single bazel test target
-- @param target The target to run
-- @return The command output and command exit code
function runSingleBazelTestTarget(target)
    local executeCommand = string.format("bazel test %s 2>&1; echo $?", target)

    local handle = io.popen(executeCommand)
    local output = {}

    for line in handle:lines() do
        table.insert(output, line)
    end

    handle:close()
    local exitCode = tonumber(table.remove(output))
    return output, exitCode
end


local M = {}

function M.onInsertEnter()
  local curline = api.nvim_win_get_cursor(0)[1]
  vim.b.insert_top = curline
  vim.b.insert_bottom = curline
  vim.b.whitespace_lastline = curline
end

-- Get the test targets for the file in the current buffer.
function M.getTestTargets()
  local fpa_rel = plenary.path:new(vim.api.nvim_buf_get_name(0)):make_relative()
  local result, exit = getBazelTestDependencies(fpa_rel)

  local dBuffer = ""
  local title = "Bazel targets"
  if exit > 0 then
    dBuffer = "Bazel failed\n"
    title = "Bazel run failed"
  end

  for _, v in pairs(result) do
    dBuffer = string.format("%s%s\n", dBuffer, v)
  end

  showFloatWindow(title, vim.split(dBuffer, "\n"))
end

-- Get the build targets for the file in the current buffer.
function M.getBuildTargets()
  local fpa_rel = plenary.path:new(vim.api.nvim_buf_get_name(0)):make_relative()
  local result, exit = getBazelAllDependencies(fpa_rel)

  local dBuffer = ""
  local title = "Bazel targets"
  if exit > 0 then
    dBuffer = "Bazel failed\n"
    title = "Bazel run failed"
  end

  for _, v in pairs(result) do
    dBuffer = string.format("%s%s\n", dBuffer, v)
  end

  showFloatWindow(title, vim.split(dBuffer, "\n"))
end

-- Run bazel test on the targets for the current file.
function M.runTestTargets()
  local fpa_rel = plenary.path:new(vim.api.nvim_buf_get_name(0)):make_relative()
  local targets, exit = getBazelTestDependencies(fpa_rel)
  if exit > 0 then
    log.error("Bazel failed")
    return
  end

  local callback = function(obj)
    vim.schedule(function()
      if obj.code > 0 then
        showFloatWindow("Bazel test failed!", vim.split(obj.stderr, "\n"))
        return
      end
      showFloatWindow("Bazel tests ran successfully", vim.split(obj.stdout, "\n"))
    end)

  end

  index = 1
  cmd = {}
  cmd[index] = 'bazel'
  index = index + 1
  cmd[index] = 'test'
  index = index + 1

  for _, v in pairs(targets) do
    cmd[index] = v
    index = index + 1
  end

  vim.system(cmd, { text = true }, callback)
end

-- Build all dependencies for the current file.
function M.buildTargets()
  local fpa_rel = plenary.path:new(vim.api.nvim_buf_get_name(0)):make_relative()
  local targets, exit = getBazelAllDependencies(fpa_rel)
  if exit > 0 then
    log.error("Bazel failed")
    return
  end

  local callback = function(obj)
    vim.schedule(function()
      if obj.code > 0 then
        showFloatWindow("Bazel build failed!", vim.split(obj.stderr, "\n"))
        return
      end
      -- For some reason the output is on stderr.
      showFloatWindow("Bazel build ran successfully", vim.split(obj.stderr, "\n"))
    end)
  end

  index = 1
  cmd = {}
  cmd[index] = 'bazel'
  index = index + 1
  cmd[index] = 'build'
  index = index + 1

  for _, v in pairs(targets) do
    cmd[index] = v
    index = index + 1
  end

  vim.system(cmd, { text = true }, callback)
end

function M.setup()
end

return M
