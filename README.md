# hfd-run

A lightweight Neovim plugin that automatically detects and runs the current file or project in an hfd-terminal session.

## Features

- Automatic language detection based on file extensions.
- Supports Python, Rust, Go, Bash, and PowerShell.
- Automatically detects Cargo and Go project roots.
- Saves modified buffers before execution.
- Customizable run commands and terminal session IDs.

## Installation (lazy.nvim)

```lua
return {
    {
        "PyNetCoder/hfd-run",
        dependencies = {
            "PyNetCoder/hfd-terminal.nvim",
        },
        cmd = "HfdRun",
        keys = {
            {
                "<leader>r",
                "<cmd>HfdRun<CR>",
                desc = "Run File/Project",
            },
        },
        opts = {
            terminal_id = 1,
            keymap = false,
        },
        config = function(_, opts)
            require("hfd.run").setup(opts)
        end,
    },
}
```

## Commands

| Command | Description |
|---------|-------------|
| `:HfdRun` | Run the current file or project in hfd-terminal. |
--------------------------------------------------------