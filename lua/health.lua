local M = {}

M.check = function()
    vim.health.start("bazelbub report")

    if vim.fn.executable("bazel") == 0 then
        vim.health.error("bazel not found on path")
        return
    end

    vim.health.ok("bazel found on path")
end

return M
