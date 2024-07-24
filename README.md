# bazelbub.nvim
A simple neovim plugin to run bazel test and bazel build

# Installation
## Using lazy.nvim

Use the following snippet but update the version to the latest release.
```
{
    'mrheinen/bazelbub.nvim',
    version = "0.1"
}
```

## Using packer.nvim

Similar to above; use this snippet and update the tag to the latest release.

```
use {
  'mrheinen/bazelbub.nvim',
  tag = '0.1',
}
```

# Description

This is a very simple plugin for those who develop with
[bazel](https://bazel.build/). The plugin allows you to run tests and build for
the dependencies of the file you are editing.

At the moment it beats having to go from neovim to a seperate terminal to run
bazel <action> but there is room for improvement.

## Running tests

Using `:BazelTest` you can run "bazel test" against all test dependencies of the
current file you are editing. If you want to check what these targets are then
first run `:BazelShowTestTargets`

## Building

Using `:BazelBuild` you can run "bazel build" against all dependencies of the
current file. To inspect what the targets are you can use `:BazelShowBuildTargets`
