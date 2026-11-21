local M = {}

local is_win = vim.fn.has("win32") == 1

M.config = {
  terminal_id = 1, -- Target hfd-terminal session ID
  keymap = "<leader>r", -- Normal mode keymap (set to false when using lazy.nvim `keys`)
  commands = {
    py = function(ctx)
      return ("python %s"):format(vim.fn.shellescape(ctx.file))
    end,
    rs = function(ctx)
      if ctx.cargo_root then
        if is_win then
          return ("Set-Location %s; cargo run"):format(vim.fn.shellescape(ctx.cargo_root))
        end
        return ("cd %s && cargo run"):format(vim.fn.shellescape(ctx.cargo_root))
      end

      if is_win then
        local exe_path = ctx.no_ext .. ".exe"
        local run_path = exe_path:match("^%.[/\\]") and exe_path or (".\\" .. exe_path)
        return ("rustc %s -o %s; %s"):format(
          vim.fn.shellescape(ctx.file),
          vim.fn.shellescape(exe_path),
          vim.fn.shellescape(run_path)
        )
      end

      return ("rustc %s && %s"):format(
        vim.fn.shellescape(ctx.file),
        vim.fn.shellescape(ctx.no_ext)
      )
    end,
    go = function(ctx)
      if ctx.go_root then
        if is_win then
          return ("Set-Location %s; go run ."):format(vim.fn.shellescape(ctx.go_root))
        end
        return ("cd %s && go run ."):format(vim.fn.shellescape(ctx.go_root))
      end
      return ("go run %s"):format(vim.fn.shellescape(ctx.file))
    end,
    sh = function(ctx)
      return ("bash %s"):format(vim.fn.shellescape(ctx.file))
    end,
    ps1 = function(ctx)
      local path = ctx.file
      if is_win and not path:match("^%.[/\\]") and not path:match("^[A-Za-z]:") then
        path = ".\\" .. path
      end
      return ("& %s"):format(vim.fn.shellescape(path))
    end,
  },
}

local function collect_context()
  local file = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  if file == "" then
    return nil
  end

  local ext = vim.fn.fnamemodify(file, ":e"):lower()
  local dir = vim.fn.fnamemodify(file, ":p:h")
  local no_ext = vim.fn.fnamemodify(file, ":p:r")

  local cargo_file = vim.fs.find("Cargo.toml", { path = dir, upward = true })[1]
  local go_mod = vim.fs.find("go.mod", { path = dir, upward = true })[1]

  return {
    file = file,
    ext = ext,
    dir = dir,
    no_ext = no_ext,
    cargo_root = cargo_file and vim.fn.fnamemodify(cargo_file, ":h") or nil,
    go_root = go_mod and vim.fn.fnamemodify(go_mod, ":h") or nil,
  }
end

function M.run()
  -- Save buffer before running so the latest changes are executed
  if vim.bo.modified then
    vim.cmd("write")
  end

  local ctx = collect_context()
  if not ctx or ctx.ext == "" then
    vim.notify("No valid file found to run.", vim.log.levels.WARN)
    return
  end

  local builder = M.config.commands[ctx.ext]
  if not builder then
    vim.notify(("No run command defined for '.%s' files."):format(ctx.ext), vim.log.levels.WARN)
    return
  end

  local cmd = type(builder) == "function" and builder(ctx) or tostring(builder)

  local ok, term = pcall(require, "hfd.terminal")
  if not ok or not term then
    vim.notify("hfd-terminal plugin not found!", vim.log.levels.ERROR)
    return
  end

  local send = term.send_command or term.komut_gonder
  if send then
    send(cmd, M.config.terminal_id)
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  vim.api.nvim_create_user_command("HfdRun", function()
    M.run()
  end, { desc = "Run the current file or project in hfd-terminal" })

  if M.config.keymap and M.config.keymap ~= "" then
    vim.keymap.set("n", M.config.keymap, function()
      M.run()
    end, { desc = "hfd-run: Run File/Project" })
  end
end

return M