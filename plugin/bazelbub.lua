-- Show all test targets that depend on the target of the current file.
vim.api.nvim_create_user_command("BazelShowTestTargets", require('bazelbub').getTestTargets, {})
-- Show all build target dependencies.
vim.api.nvim_create_user_command("BazelShowBuildTargets", require('bazelbub').getBuildTargets, {})
-- Run bazel test on all test dependencies.
vim.api.nvim_create_user_command("BazelTest", require('bazelbub').runTestTargets, {})
-- RUn bazel build on all build targets.
vim.api.nvim_create_user_command("BazelBuild", require('bazelbub').buildTargets, {})
-- Run gazelle
vim.api.nvim_create_user_command("BazelGazelle", require('bazelbub').runGazelle, {})
-- Run gazelle update repos
vim.api.nvim_create_user_command("BazelGazelleUpdate", require('bazelbub').runGazelleUpdateRepos, {})
