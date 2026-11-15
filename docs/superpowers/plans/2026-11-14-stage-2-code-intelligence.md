# Stage 2: Code Intelligence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Language servers, completion, formatting and diagnostic display for Lua, C/C++ and Python, each switched on only where its tool exists.

**Architecture:** Language files in `lua/lang` gain data fields (servers, mason packages, formatters and their project config files); `core.lang` collects them. Plugin files read the collected data: `lsp.lua` enables a server through `vim.lsp.enable` only when its executable is on `PATH` (mason's bin directory included), `conform.lua` formats on save only when the project carries the formatter's config. Tests extend the headless harness in `tests/run.sh` with a fake language server and fake formatters, so they run offline and do not depend on what is installed on the host.

**Tech Stack:** Neovim 0.12 (`vim.lsp.config` / `vim.lsp.enable`), lazy.nvim, mason.nvim, nvim-lspconfig (config data only), lazydev.nvim, blink.cmp + friendly-snippets, conform.nvim, bash + headless nvim for tests.

**Spec:** `docs/prd-ide.md` — user stories 11 and 12, "Code intelligence (stage 2)" decisions, Testing Decisions.

## Global Constraints

- Minimum Neovim for anything beyond the fallback tier is 0.12.
- A missing tool is skipped silently: no error, no warning at startup.
- Plugin-specific keymaps live with their plugin, not in `lua/core/keymaps.lua`.
- Every plugin can be switched off per host via `lua/local.lua` (`plugins = { [name] = false }`); no plugin file may depend on another plugin being present without a guard.
- Language servers are configured through Neovim's native API; nvim-lspconfig is used only as data. A server is enabled only when its executable exists.
- Servers and tools are installed per user by mason, with no root needed.
- Stage 2 servers: clangd; basedpyright and ruff; lua_ls with Neovim API typings.
- Completion: blink.cmp with the `super-tab` preset and friendly-snippets on the built-in snippet engine.
- Format-on-save only when the project carries a formatter configuration; session toggle and per-host default.
- Leader groups: `c` code, `u` toggles (`x` diagnostics is reserved for trouble in stage 3).
- After every task: `tests/run.sh` passes, startup emits no error, the fallback tier still starts.

## Decisions taken in this plan

- **mason installs on command, not at startup.** `:LangInstall` installs all packages the enabled languages list. Startup stays offline and fast, and a locked-down host never sees install errors. The PRD does not require automatic installation.
- **nvim-lint is deferred to stage 6.** Lua, C/C++ and Python already get lint diagnostics from their servers (lua_ls, clangd with clang-tidy, ruff). The first linter that needs nvim-lint is the Zsh syntax check in stage 6.
- **Tests use an isolated data directory.** `lazy` and `site` are symlinked from the real data directory, `mason` is not, so installed servers on the host cannot hide a missing-tool bug.

## Review Focus

1. A formatter config exists but the formatter is not installed: saving must neither error nor notify, the file stays unchanged. — Task 5 test "formatter missing".
2. `pyproject.toml` without a `[tool.ruff]` section must not count as ruff configuration. — Task 5 test "pyproject without ruff section".
3. A language switched off in `local.lua` must not start its server even when the executable is present. — Task 3 test "local.lua switches off cpp".
4. Saving a buffer without a file name must not search the current directory for formatter configs. — Task 5, guard in `project_formatters` (`name == ''`), covered by code review.
5. blink.cmp cannot download its prebuilt fuzzy matcher (offline host): completion must fall back to the Lua matcher without a warning. — Task 4, `fuzzy.implementation = 'prefer_rust'`, covered by the "no network" note in the task's manual check.

---

### Task 1: Isolated data directory and probe extensions for the test harness

**Files:**
- Modify: `tests/run.sh`
- Modify: `tests/probe.lua`

**Interfaces:**
- Produces:
  - `run VAR=value ...` now starts nvim with `XDG_DATA_HOME=$tmp/data` (lazy + site symlinked, no mason). A scenario can still override `XDG_DATA_HOME`.
  - `$tmp/project`: scratch directory for files a scenario opens; emptied by `fresh_project`.
  - Probe env `PROBE_EXTRA=<lua file>`: run at check time; it reports with the global function `probe_put(key, value)`.
  - Probe output lines `servers=…`, `mason=…`, `formatter <ft>=…` (filled once the fields exist, see Task 2).

- [ ] **Step 1: Write the failing test** — add to `tests/run.sh`, after the "ssh session" section:

```bash
#-----------------------------------------------------------
section "isolated data directory"
#-----------------------------------------------------------
cat >"$tmp/extra-data.lua" <<'EOF'
probe_put('data', vim.fn.stdpath('data'))
EOF
run PROBE_EXTRA="$tmp/extra-data.lua"
expect_exit_0
expect_line "data=$tmp/data/nvim"
expect_line "lazy_loaded=true"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `tests/run.sh`
Expected: `FAIL: expected 'data=…/data/nvim'` (the line is missing because the probe ignores `PROBE_EXTRA`).

- [ ] **Step 3: Implement**

In `tests/run.sh`, after the `cfg=` line, add:

```bash
# data copy: plugins and parsers are shared with the real data
# directory, mason is not, so tools installed on this host
# can't hide a missing tool
real_data=$("$nvim_bin" --clean --headless \
  -c 'lua io.stdout:write(vim.fn.stdpath("data"))' -c 'qa!')
mkdir -p "$tmp/data/nvim"
for dir in lazy site; do
  [ -e "$real_data/$dir" ] && ln -s "$real_data/$dir" "$tmp/data/nvim/$dir"
done

# files a scenario opens
mkdir -p "$tmp/project"
fresh_project() {
  rm -rf "$tmp/project"
  mkdir -p "$tmp/project/.git"
}
```

Change `run()` so the isolated data directory is the default (later arguments win in `env`):

```bash
run() {
  output=$(env XDG_CONFIG_HOME="$tmp/config" XDG_DATA_HOME="$tmp/data" "$@" \
    "$nvim_bin" --headless --cmd "luafile $probe" 2>"$tmp/stderr")
  status=$?
}
```

Update the header comment of `tests/run.sh`: replace "The copy keeps the real data directory, so the installed plugins are used." with "Plugins and parsers come from the real data directory (symlinked), mason packages do not."

In `tests/probe.lua`, document `PROBE_EXTRA` in the header comment:

```lua
--   PROBE_EXTRA   lua file run after startup, reports with probe_put(key, value)
```

In `check()`, replace the `if package.loaded['core.lang'] then … end` block with:

```lua
  if package.loaded['core.lang'] then
    local lang = require('core.lang')
    put('parsers', table.concat(lang.collect('treesitter'), ','))
    put('servers', table.concat(lang.collect('servers'), ','))
    put('mason', table.concat(lang.collect('mason'), ','))
    if lang.collect_map then
      local formatters = lang.collect_map('formatters')
      local fts = vim.tbl_keys(formatters)
      table.sort(fts)
      for _, ft in ipairs(fts) do
        put('formatter ' .. ft, table.concat(formatters[ft], ','))
      end
    end
  end
```

and directly before the `-- messages shown to the user during startup` block add:

```lua
  if vim.env.PROBE_EXTRA then
    _G.probe_put = put
    local ok, err = pcall(dofile, vim.env.PROBE_EXTRA)
    if not ok then
      put('extra_error', err)
    end
  end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `tests/run.sh`
Expected: all sections pass, last line `N passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add tests/run.sh tests/probe.lua
git commit -m "Isolate the data directory in startup tests"
```

---

### Task 2: Language files declare servers, mason packages and formatters

**Files:**
- Modify: `lua/core/lang.lua`
- Modify: `lua/lang/cpp.lua`, `lua/lang/lua.lua`, `lua/lang/python.lua`
- Modify: `tests/run.sh` (sections "normal startup", "language files")
- Modify: `README.md` (paragraph "To add a language …" in "Structure")

**Interfaces:**
- Consumes: probe lines from Task 1.
- Produces:
  - `require('core.lang').collect(field) -> string[]` (unchanged) for `treesitter`, `servers`, `mason`.
  - `require('core.lang').collect_map(field) -> table<string, any>` for `formatters` (`filetype -> formatter names`) and `format_config` (`formatter -> markers`). The first language in sorted file-name order wins per key.
  - Marker format in `format_config`: a file name string, or `{ file, text }` meaning "file exists and contains `text` (plain match)".

- [ ] **Step 1: Write the failing tests**

In `tests/run.sh`, section "normal startup", after `expect_line "clipboard=none"` add:

```bash
expect_line "servers=clangd,lua_ls,basedpyright,ruff"
expect_line "mason=clangd,clang-format,lua-language-server,stylua,basedpyright,ruff"
expect_line "formatter c=clang-format"
expect_line "formatter cpp=clang-format"
expect_line "formatter lua=stylua"
expect_line "formatter python=ruff_format"
```

In section "language files", replace the `zz_new.lua` line with:

```bash
cat >"$cfg/lua/lang/zz_new.lua" <<'EOF'
return {
  treesitter = { 'zz_probe', 'lua', 'c' },
  formatters = { zz_ft = { 'zz_fmt' }, lua = { 'zz_other' } },
}
EOF
```

and after the duplicate check add:

```bash
expect_line "formatter zz_ft=zz_fmt"
# lua.lua sorts before zz_new.lua, so its entry wins
expect_line "formatter lua=stylua"
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `tests/run.sh`
Expected: FAIL for `servers=…`, `mason=…` and every `formatter …` line.

- [ ] **Step 3: Implement**

`lua/core/lang.lua` — update the header example and add `collect_map` after `collect`:

```lua
-- Every file in lua/lang describes one language, e.g.
--
--   return {
--     treesitter = { 'python' },                -- parsers to install
--     servers    = { 'basedpyright', 'ruff' },  -- names as in nvim-lspconfig
--     mason      = { 'basedpyright', 'ruff' },  -- packages for :LangInstall
--     formatters = { python = { 'ruff_format' } },  -- by filetype, see conform.nvim
--     -- files that show a project wants a formatter, a name or
--     -- { name, text } when the file must contain text
--     format_config = { ruff_format = { 'ruff.toml', { 'pyproject.toml', '[tool.ruff' } } },
--     plugins    = { ... },                     -- lazy.nvim specs only this language needs
--   }
```

```lua
-- a field that maps keys to values, merged over all enabled languages.
-- If two languages set the same key, the first one by file name wins.
function M.collect_map(field)
  if not langs then
    load()
  end
  local result = {}
  for _, name in ipairs(vim.fn.sort(vim.tbl_keys(langs))) do
    for key, value in pairs(langs[name][field] or {}) do
      if result[key] == nil then
        result[key] = value
      end
    end
  end
  return result
end
```

`lua/lang/cpp.lua`:

```lua
return {
  treesitter = { 'c', 'cpp', 'cmake' },
  servers = { 'clangd' },
  mason = { 'clangd', 'clang-format' },
  formatters = { c = { 'clang-format' }, cpp = { 'clang-format' } },
  format_config = { ['clang-format'] = { '.clang-format', '_clang-format' } },
}
```

`lua/lang/lua.lua`:

```lua
return {
  treesitter = { 'lua', 'luadoc', 'vim', 'vimdoc', 'query' },
  servers = { 'lua_ls' },
  mason = { 'lua-language-server', 'stylua' },
  formatters = { lua = { 'stylua' } },
  format_config = { stylua = { 'stylua.toml', '.stylua.toml' } },
}
```

`lua/lang/python.lua`:

```lua
return {
  treesitter = { 'python' },
  servers = { 'basedpyright', 'ruff' },
  mason = { 'basedpyright', 'ruff' },
  formatters = { python = { 'ruff_format' } },
  format_config = { ruff_format = { 'ruff.toml', '.ruff.toml', { 'pyproject.toml', '[tool.ruff' } } },
}
```

`README.md`, replace the paragraph starting "To add a language, add a file to `lua/lang`." with:

```markdown
To add a language, add a file to `lua/lang`. A language file lists the
syntax parsers (`treesitter`), language servers (`servers`, names as in
nvim-lspconfig), packages for `:LangInstall` (`mason`), formatters by
filetype (`formatters`), the files that show a project wants a formatter
(`format_config`) and plugins only this language needs (`plugins`).
See the comment in `lua/core/lang.lua`.
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `tests/run.sh`
Expected: `N passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add lua/core/lang.lua lua/lang/cpp.lua lua/lang/lua.lua lua/lang/python.lua tests/run.sh README.md
git commit -m "Let language files declare servers, packages and formatters"
```

---

### Task 3: mason, language servers, diagnostics display

**Files:**
- Create: `lua/plugins/mason.lua`
- Create: `lua/plugins/lsp.lua`
- Modify: `lua/lang/lua.lua` (lazydev plugin)
- Modify: `lua/core/options.lua` (diagnostic display)
- Modify: `lua/core/keymaps.lua` (`<leader>cd`, group list in header)
- Modify: `lua/plugins/which-key.lua` (groups `c`, `u`)
- Create: `tests/fake-lsp.lua`
- Create: `tests/extra/lsp.lua`
- Modify: `tests/run.sh`
- Modify: `CHEATSHEET.md` (new section "Code"), `README.md` (Installation: `:LangInstall`)

**Interfaces:**
- Consumes: `lang.collect('servers')`, `lang.collect('mason')` (Task 2), `env.has(executable)`, `probe_put`, `run`, `fresh_project` (Task 1).
- Produces:
  - Command `:LangInstall` — installs all collected mason packages that are missing.
  - Buffer-local keymaps on LSP attach: `gd` definition, `<leader>ca` code action, `<leader>cr` rename.
  - Global keymap `<leader>cd` line diagnostics float.
  - `$tmp/bin-fake-lsp` in `tests/run.sh`: `clangd`, `lua-language-server`, `basedpyright-langserver`, `ruff` all answer as a minimal language server.

- [ ] **Step 1: Write the fake language server** — `tests/fake-lsp.lua`:

```lua
-----------------------------------------------------------
--  Minimal language server for tests/run.sh
-----------------------------------------------------------
--
-- Run with nvim -l. Answers initialize, shutdown and any other
-- request with an empty result, ignores notifications.

local function read_message()
  local length
  while true do
    local line = io.stdin:read('l')
    if not line then
      os.exit(0)
    end
    line = line:gsub('\r$', '')
    if line == '' then
      break
    end
    length = tonumber(line:match('^Content%-Length: (%d+)')) or length
  end
  return vim.json.decode(io.stdin:read(length))
end

local function send(message)
  local body = vim.json.encode(message)
  io.stdout:write('Content-Length: ' .. #body .. '\r\n\r\n' .. body)
  io.stdout:flush()
end

while true do
  local message = read_message()
  if message.method == 'exit' then
    os.exit(0)
  elseif message.method == 'initialize' then
    send({ jsonrpc = '2.0', id = message.id, result = { capabilities = {} } })
  elseif message.id then
    send({ jsonrpc = '2.0', id = message.id, result = vim.NIL })
  end
end
```

- [ ] **Step 2: Write the failing tests**

`tests/extra/lsp.lua`:

```lua
-- opens one file per language in $PROBE_PROJECT and reports
-- which language servers attached, and the LSP keymaps
for _, file in ipairs({ 'main.c', 'init.lua', 'app.py' }) do
  vim.cmd.edit(vim.env.PROBE_PROJECT .. '/' .. file)
  local buf = vim.api.nvim_get_current_buf()
  vim.wait(1500, function()
    return #vim.lsp.get_clients({ bufnr = buf }) > 0
  end, 50)
  local names = vim.tbl_map(function(c)
    return c.name
  end, vim.lsp.get_clients({ bufnr = buf }))
  table.sort(names)
  probe_put('lsp ' .. file, #names > 0 and table.concat(names, ',') or 'none')
  if file == 'main.c' then
    for _, lhs in ipairs({ 'gd', '<leader>ca', '<leader>cr' }) do
      local map = vim.fn.maparg(lhs, 'n', false, true)
      probe_put('lsp map ' .. lhs, map.buffer == 1 and 'buffer' or 'no')
    end
  end
end

local diag = vim.diagnostic.config()
probe_put('diag virtual_lines.current_line', type(diag.virtual_lines) == 'table' and diag.virtual_lines.current_line)
probe_put('diag virtual_text', diag.virtual_text)
probe_put('diag underline', diag.underline)
probe_put('diag signs', diag.signs ~= false)
```

In `tests/run.sh`, after the `bin-empty` lines add:

```bash
# PATH with fake language servers (and git, cc)
mkdir -p "$tmp/bin-fake-lsp"
cat >"$tmp/bin-fake-lsp/fake-lsp" <<EOF
#!/bin/sh
exec "$nvim_bin" -l "$repo/tests/fake-lsp.lua"
EOF
chmod +x "$tmp/bin-fake-lsp/fake-lsp"
for server in clangd lua-language-server basedpyright-langserver ruff; do
  ln -s fake-lsp "$tmp/bin-fake-lsp/$server"
done
```

After the section "isolated data directory" add:

```bash
#-----------------------------------------------------------
section "language servers present"
#-----------------------------------------------------------
fresh_project
touch "$tmp/project/main.c" "$tmp/project/init.lua" "$tmp/project/app.py"
run PATH="$tmp/bin-fake-lsp:$tmp/bin-no-ts" PROBE_PROJECT="$tmp/project" \
  PROBE_EXTRA="$repo/tests/extra/lsp.lua"
expect_exit_0
expect_messages 0
expect_line "lsp main.c=clangd"
expect_line "lsp init.lua=lua_ls"
expect_line "lsp app.py=basedpyright,ruff"
expect_line "lsp map gd=buffer"
expect_line "lsp map <leader>ca=buffer"
expect_line "lsp map <leader>cr=buffer"
expect_line "map n <leader>cd=desc"
expect_line "diag virtual_lines.current_line=true"
expect_line "diag virtual_text=false"
expect_line "diag underline=true"
expect_line "diag signs=true"

#-----------------------------------------------------------
section "language servers missing"
#-----------------------------------------------------------
run PATH="$tmp/bin-no-ts" PROBE_PROJECT="$tmp/project" \
  PROBE_EXTRA="$repo/tests/extra/lsp.lua"
expect_exit_0
expect_messages 0
expect_line "lsp main.c=none"
expect_line "lsp init.lua=none"
expect_line "lsp app.py=none"

#-----------------------------------------------------------
section "local.lua switches off cpp"
#-----------------------------------------------------------
echo "return { langs = { cpp = false } }" >"$cfg/lua/local.lua"
run PATH="$tmp/bin-fake-lsp:$tmp/bin-no-ts" PROBE_PROJECT="$tmp/project" \
  PROBE_EXTRA="$repo/tests/extra/lsp.lua"
expect_exit_0
expect_line "lsp main.c=none"
expect_line "lsp init.lua=lua_ls"
rm -f "$cfg/lua/local.lua"
```

In `tests/probe.lua` add `{ 'n', '<leader>cd' }` to the `maps` list.

- [ ] **Step 3: Run tests to verify they fail**

Run: `tests/run.sh`
Expected: FAIL for every `lsp …` line in "language servers present" (`none` instead of server names), `map n <leader>cd`, and the `diag …` lines.

- [ ] **Step 4: Implement**

`lua/plugins/mason.lua`:

```lua
-----------------------------------------------------------
--
-- Configuration for mason
-- installs language servers and formatters per user, no root needed
--
-----------------------------------------------------------

-- Packages are installed on request only (:LangInstall), so startup
-- needs no network. Installed tools are put on PATH, so the plugins
-- asking core.env find them.

return {
  'mason-org/mason.nvim',
  lazy = false, -- other plugins look for its tools at startup
  config = function()
    require('mason').setup()

    vim.api.nvim_create_user_command('LangInstall', function()
      local registry = require('mason-registry')
      registry.refresh(function()
        for _, name in ipairs(require('core.lang').collect('mason')) do
          local ok, package = pcall(registry.get_package, name)
          if not ok then
            vim.notify('LangInstall: unknown package ' .. name, vim.log.levels.WARN)
          elseif not package:is_installed() then
            vim.notify('LangInstall: installing ' .. name)
            package:install()
          end
        end
      end)
    end, { desc = 'Install servers and tools of all enabled languages' })
  end,
}
```

`lua/plugins/lsp.lua`:

```lua
-----------------------------------------------------------
--
-- Language servers
-- enables the servers the language files list, see lua/lang
--
-----------------------------------------------------------

-- nvim-lspconfig is only used for its server configs (lsp/*.lua),
-- the servers are started by neovim itself (vim.lsp.enable).
-- A server is enabled only when its program is installed.

return {
  'neovim/nvim-lspconfig',
  lazy = false, -- servers must be enabled before the first file opens
  dependencies = { 'mason-org/mason.nvim' }, -- puts installed servers on PATH
  config = function()
    local env = require('core.env')

    -- tell the servers what the completion plugin can do
    local ok, blink = pcall(require, 'blink.cmp')
    if ok then
      vim.lsp.config('*', { capabilities = blink.get_lsp_capabilities() })
    end

    for _, name in ipairs(require('core.lang').collect('servers')) do
      local cmd = (vim.lsp.config[name] or {}).cmd
      -- a cmd given as a function can't be checked, trust it
      if type(cmd) == 'function' or (type(cmd) == 'table' and env.has(cmd[1])) then
        vim.lsp.enable(name)
      end
    end

    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local function map(lhs, rhs, desc)
          vim.keymap.set('n', lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
        end
        map('gd', vim.lsp.buf.definition, 'Go to definition')
        map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
        map('<leader>cr', vim.lsp.buf.rename, 'Rename symbol')
      end,
    })
  end,
}
```

`lua/lang/lua.lua` — add Neovim API typings for lua_ls:

```lua
  plugins = {
    -- Neovim API typings for lua_ls, only in lua files
    { 'folke/lazydev.nvim', ft = 'lua', opts = {} },
  },
```

`lua/core/options.lua` — add a section after "UI":

```lua
-----------------------------------------------------------
-- Diagnostics (from language servers)
-----------------------------------------------------------

-- the full message only on the cursor line, other lines
-- show the sign and an underline
if vim.fn.has('nvim-0.11') == 1 then
  vim.diagnostic.config({
    virtual_text  = false,
    virtual_lines = { current_line = true },
    underline     = true,
    signs         = true,
    severity_sort = true,
  })
end
```

`lua/core/keymaps.lua` — header group list becomes:

```lua
-- <leader> is space, groups by first letter:
--   f  find
--   c  code
--   u  toggles
```

and add a section before "Help":

```lua
-----------------------------------------------------------
--  Code
-----------------------------------------------------------

nmap('<leader>cd', vim.diagnostic.open_float, 'Line diagnostics')
```

`lua/plugins/which-key.lua` — spec becomes:

```lua
    spec = {
      { '<leader>f', group = 'find' },
      { '<leader>c', group = 'code' },
      { '<leader>u', group = 'toggles' },
    },
```

`CHEATSHEET.md` — insert after "## Change the same thing in many places" section, before "## Commands":

```markdown
## Code

Needs the language server of the language, see `:LangInstall`.

| I want to                          | Keys                  |
|------------------------------------|-----------------------|
| Go to the definition               | `gd`, back with `Ctrl-o` |
| Show the documentation             | `K`                   |
| List the references                | `grr`                 |
| Rename the symbol                  | `Space c r`           |
| Fix or refactor (code action)      | `Space c a`           |
| Show the diagnostics of the line   | `Space c d`           |
| Next / previous diagnostic         | `]d` / `[d`           |

The full diagnostic message shows below the cursor line only; other lines
show a sign and an underline.
```

and add to the "Commands" table:

```markdown
| `:LangInstall`       | Install servers and formatters of all languages |
| `:Mason`             | Installed servers and tools            |
| `:checkhealth vim.lsp` | Which servers run for this buffer    |
```

`README.md`, section "Installation", after the paragraph "Clone this repo …" add:

```markdown
Language servers and formatters are installed per user with
`:LangInstall` (needs network, and `npm` / `python3` for some of them).
A language whose server is missing still gets highlighting.
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `tests/run.sh`
Expected: `N passed, 0 failed`. If `lsp init.lua` shows `none` with the fake server: check whether lazydev's `workspace/configuration` request reaches the fake server; the fake server answers every request, so look at `:LspLog` in an interactive run with `PATH=$tmp/bin-fake-lsp:…`.

- [ ] **Step 6: Manual check (network needed, not part of the suite)**

Run `nvim`, `:LangInstall`, wait for the notices, restart, open `lua/core/env.lua`: `:checkhealth vim.lsp` lists `lua_ls` attached, `K` on `vim.fn` shows documentation (lazydev typings).

- [ ] **Step 7: Commit**

```bash
git add lua/plugins/mason.lua lua/plugins/lsp.lua lua/lang/lua.lua lua/core/options.lua \
  lua/core/keymaps.lua lua/plugins/which-key.lua tests/fake-lsp.lua tests/extra/lsp.lua \
  tests/run.sh CHEATSHEET.md README.md lazy-lock.json
git commit -m "Add language servers for Lua, C/C++ and Python"
```

---

### Task 4: Completion with blink.cmp

**Files:**
- Create: `lua/plugins/blink.lua`
- Create: `tests/extra/completion.lua`
- Modify: `tests/run.sh`
- Modify: `CHEATSHEET.md` (section "Code")

**Interfaces:**
- Consumes: `probe_put`, `run` (Task 1). `lsp.lua` (Task 3) already asks `blink.cmp` for capabilities via `pcall`.
- Produces: insert-mode `<Tab>` accepts a completion; `<CR>` stays unmapped by the completion plugin.

- [ ] **Step 1: Write the failing test**

`tests/extra/completion.lua`:

```lua
-- reports the completion setup as a user would meet it in insert mode
vim.cmd.enew()
vim.api.nvim_exec_autocmds('InsertEnter', { buffer = 0, modeline = false })

local function mapped(lhs)
  local map = vim.fn.maparg(lhs, 'i', false, true)
  return next(map) and 'mapped' or 'no'
end
probe_put('insert <Tab>', mapped('<Tab>'))
probe_put('insert <CR>', mapped('<CR>'))

local ok, config = pcall(require, 'blink.cmp.config')
probe_put('completion sources', ok and table.concat(config.sources.default, ',') or 'none')
probe_put('lsp completion capabilities',
  vim.lsp.config['*'] and vim.lsp.config['*'].capabilities ~= nil)
```

In `tests/run.sh`, after the section "local.lua switches off cpp" add:

```bash
#-----------------------------------------------------------
section "completion"
#-----------------------------------------------------------
run PROBE_EXTRA="$repo/tests/extra/completion.lua"
expect_exit_0
expect_messages 0
expect_line "insert <Tab>=mapped"
expect_line "insert <CR>=no"
expect_line "completion sources=lsp,path,snippets,buffer"
expect_line "lsp completion capabilities=true"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `tests/run.sh`
Expected: FAIL for `insert <Tab>=mapped`, `completion sources=…`, `lsp completion capabilities=true`.

- [ ] **Step 3: Implement** — `lua/plugins/blink.lua`:

```lua
-----------------------------------------------------------
--
-- Configuration for blink.cmp
-- completion menu while typing
--
-----------------------------------------------------------

-- Tab accepts, Enter always inserts a new line (super-tab preset).
-- Snippets come from friendly-snippets and run on neovim's own
-- snippet engine.

return {
  'saghen/blink.cmp',
  version = '1.*', -- release builds ship a prebuilt fuzzy matcher
  lazy = false, -- loads its parts lazily itself
  dependencies = { 'rafamadriz/friendly-snippets' },
  opts = {
    keymap = { preset = 'super-tab' },
    sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
    completion = { documentation = { auto_show = true } },
    -- without the prebuilt matcher (offline host) use the lua one, silently
    fuzzy = { implementation = 'prefer_rust' },
  },
}
```

`lsp.lua` must see blink when it builds the capabilities: add `'saghen/blink.cmp'` to the `dependencies` of `lua/plugins/lsp.lua`:

```lua
  dependencies = {
    'mason-org/mason.nvim', -- puts installed servers on PATH
    'saghen/blink.cmp',     -- completion capabilities for the servers
  },
```

A dependency switched off in `local.lua` is skipped by lazy.nvim, and the `pcall(require, 'blink.cmp')` in `lsp.lua` handles that case.

If `insert <Tab>` is still `no`: blink sets its insert-mode keymaps per buffer on a different event. Find the event in `lua/blink/cmp/keymap/init.lua` of the plugin and trigger that one in `tests/extra/completion.lua` instead of `InsertEnter`; keep the assertions unchanged.

`CHEATSHEET.md`, section "Code", add rows:

```markdown
| Accept a completion                | `Tab`                 |
| Next / previous completion         | `Ctrl-n` / `Ctrl-p`   |
| Close the completion menu          | `Ctrl-e`              |
| Jump to the next snippet field     | `Tab`                 |
```

- [ ] **Step 4: Run test to verify it passes**

Run: `tests/run.sh`
Expected: `N passed, 0 failed`.

- [ ] **Step 5: Manual check**

Open `lua/core/env.lua`, type `vim.ap` in insert mode: the menu shows `api`; `Tab` accepts; with the menu open `Enter` inserts a new line. Then rename the downloaded matcher (`~/.local/share/nvim/lazy/blink.cmp/target`) and restart: no warning, completion still works; rename it back.

- [ ] **Step 6: Commit**

```bash
git add lua/plugins/blink.lua lua/plugins/lsp.lua tests/extra/completion.lua tests/run.sh CHEATSHEET.md lazy-lock.json
git commit -m "Add completion with blink.cmp"
```

---

### Task 5: Formatting with conform.nvim, project-aware format on save

**Files:**
- Create: `lua/plugins/conform.lua`
- Modify: `lua/core/env.lua` (`format_on_save` per host)
- Modify: `lua/local.lua.example`
- Create: `tests/extra/format.lua`
- Modify: `tests/run.sh`
- Modify: `CHEATSHEET.md` (section "Code", "State" line, "Later" table), `README.md` ("Hosts"), `docs/prd-ide.md` (status line)

**Interfaces:**
- Consumes: `lang.collect_map('formatters')`, `lang.collect_map('format_config')` (Task 2), `probe_put`, `run`, `fresh_project` (Task 1).
- Produces:
  - `require('core.env').format_on_save -> boolean` (default `true`, `local.lua`: `format_on_save = false`).
  - `<leader>cf` format buffer (ignores project config), `<leader>uf` toggle format on save for the session.

- [ ] **Step 1: Write the failing tests**

`tests/extra/format.lua`:

```lua
-- saves files in $PROBE_PROJECT and reports their first line;
-- the fake formatters prepend '-- formatted'
local base = vim.env.PROBE_PROJECT

local function save(file)
  vim.cmd.edit(base .. '/' .. file)
  vim.cmd.write()
  return vim.fn.readfile(base .. '/' .. file)[1]
end

probe_put('save with config', save('with-config/a.lua'))
probe_put('save without config', save('without-config/a.lua'))
probe_put('save pyproject with ruff', save('ruff-project/a.py'))
probe_put('save pyproject without ruff', save('other-project/a.py'))

-- the manual key formats regardless of project configuration
vim.cmd.edit(base .. '/without-config/b.lua')
vim.cmd.normal(' cf')
probe_put('manual format', vim.api.nvim_buf_get_lines(0, 0, 1, false)[1])

-- the toggle flips format on save for the session
vim.cmd.normal(' uf')
probe_put('save after toggle', save('with-config/c.lua'))
```

In `tests/run.sh`, after the `bin-fake-lsp` block add:

```bash
# PATH with fake formatters (and git, cc): they prepend a line
mkdir -p "$tmp/bin-fake-fmt"
printf '#!/bin/sh\necho "-- formatted"\ncat\n' >"$tmp/bin-fake-fmt/fake-fmt"
chmod +x "$tmp/bin-fake-fmt/fake-fmt"
for formatter in stylua ruff clang-format; do
  ln -s fake-fmt "$tmp/bin-fake-fmt/$formatter"
done

format_project() {
  fresh_project
  local p="$tmp/project"
  mkdir -p "$p/with-config" "$p/without-config" "$p/ruff-project" "$p/other-project"
  touch "$p/with-config/.stylua.toml"
  printf '[tool.ruff]\nline-length = 100\n' >"$p/ruff-project/pyproject.toml"
  printf '[project]\nname = "x"\n' >"$p/other-project/pyproject.toml"
  for f in with-config/a.lua with-config/c.lua without-config/a.lua without-config/b.lua \
           ruff-project/a.py other-project/a.py; do
    echo "x = 1" >"$p/$f"
  done
}
```

After the section "completion" add:

```bash
#-----------------------------------------------------------
section "format on save"
#-----------------------------------------------------------
format_project
echo "return { plugins = { ['nvim-lspconfig'] = false } }" >"$cfg/lua/local.lua"
run PATH="$tmp/bin-fake-fmt:$tmp/bin-no-ts" PROBE_PROJECT="$tmp/project" \
  PROBE_EXTRA="$repo/tests/extra/format.lua"
rm -f "$cfg/lua/local.lua"
expect_exit_0
expect_messages 1 "Format on save: off"
expect_line "save with config=-- formatted"
expect_line "save without config=x = 1"
expect_line "save pyproject with ruff=-- formatted"
expect_line "save pyproject without ruff=x = 1"
expect_line "manual format=-- formatted"
expect_line "save after toggle=x = 1"
expect_line "map n <leader>cf=desc"
expect_line "map n <leader>uf=desc"

#-----------------------------------------------------------
section "format on save off in local.lua"
#-----------------------------------------------------------
format_project
echo "return { format_on_save = false, plugins = { ['nvim-lspconfig'] = false } }" >"$cfg/lua/local.lua"
run PATH="$tmp/bin-fake-fmt:$tmp/bin-no-ts" PROBE_PROJECT="$tmp/project" \
  PROBE_EXTRA="$repo/tests/extra/format.lua"
expect_exit_0
expect_line "save with config=x = 1"
expect_line "manual format=-- formatted"
expect_line "save after toggle=-- formatted"
rm -f "$cfg/lua/local.lua"

#-----------------------------------------------------------
section "formatter missing"
#-----------------------------------------------------------
format_project
run PATH="$tmp/bin-no-ts" PROBE_PROJECT="$tmp/project" \
  PROBE_EXTRA="$repo/tests/extra/format.lua"
expect_exit_0
expect_line "save with config=x = 1"
expect_line "save pyproject with ruff=x = 1"
```

`expect_messages` is not asserted in "formatter missing": the manual format key may report that no formatter is available, which is wanted there.

In `tests/probe.lua` add `{ 'n', '<leader>cf' }, { 'n', '<leader>uf' }` to the `maps` list.

The fake `ruff` is not a language server, but `lsp.lua` would start it as one (`ruff server`) and fill the messages with protocol errors. Every format scenario therefore switches off nvim-lspconfig in `local.lua`; this also exercises a plugin switched off per host.

- [ ] **Step 2: Run tests to verify they fail**

Run: `tests/run.sh`
Expected: FAIL for `save with config=-- formatted`, `save pyproject with ruff=-- formatted`, `manual format=-- formatted`, the two map lines and the message count.

- [ ] **Step 3: Implement**

`lua/core/env.lua` — the overrides default and the new field:

```lua
local overrides = { plugins = {}, langs = {}, format_on_save = true }
```

```lua
-- format files on save (only in projects that configure the formatter)
M.format_on_save = overrides.format_on_save ~= false
```

`lua/local.lua.example` — add before the closing brace:

```lua

  -- format on save in projects that configure a formatter
  -- format_on_save = false,
```

`lua/plugins/conform.lua`:

```lua
-----------------------------------------------------------
--
-- Configuration for conform.nvim
-- formats code with the formatters the language files list
--
-----------------------------------------------------------

-- On save a file is formatted only if its project carries a
-- configuration for the formatter (e.g. .stylua.toml), so foreign
-- projects are never reformatted by accident. Space c f formats
-- anyway, Space u f switches format on save for the session.

local format_on_save = require('core.env').format_on_save

-- does the file at path contain text
local function contains(path, text)
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and table.concat(lines, '\n'):find(text, 1, true) ~= nil
end

-- formatters for buf that are installed and configured in its project
local function project_formatters(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then
    return {}
  end
  local lang = require('core.lang')
  local configs = lang.collect_map('format_config')
  local result = {}
  for _, formatter in ipairs(lang.collect_map('formatters')[vim.bo[buf].filetype] or {}) do
    local info = require('conform').get_formatter_info(formatter, buf)
    for _, marker in ipairs(configs[formatter] or {}) do
      local file, text = marker, nil
      if type(marker) == 'table' then
        file, text = marker[1], marker[2]
      end
      local found = vim.fs.find(file, { path = vim.fs.dirname(name), upward = true })[1]
      if info.available and found and (not text or contains(found, text)) then
        result[#result + 1] = formatter
        break
      end
    end
  end
  return result
end

return {
  'stevearc/conform.nvim',
  event = 'BufWritePre',
  cmd = 'ConformInfo',
  keys = {
    {
      '<leader>cf',
      function()
        require('conform').format({ lsp_format = 'fallback' })
      end,
      desc = 'Format buffer',
    },
    {
      '<leader>uf',
      function()
        format_on_save = not format_on_save
        vim.notify('Format on save: ' .. (format_on_save and 'on' or 'off'))
      end,
      desc = 'Toggle format on save',
    },
  },
  opts = function()
    return {
      formatters_by_ft = require('core.lang').collect_map('formatters'),
      format_on_save = function(buf)
        if not format_on_save then
          return
        end
        local formatters = project_formatters(buf)
        if #formatters == 0 then
          return
        end
        return { formatters = formatters, lsp_format = 'never', timeout_ms = 1000 }
      end,
    }
  end,
}
```

Check the conform formatter name for clang-format before running: `ls ~/.local/share/nvim/lazy/conform.nvim/lua/conform/formatters/ | grep clang`. If the file is `clang_format.lua`, rename `clang-format` to `clang_format` in `formatters` and `format_config` of `lua/lang/cpp.lua` and in the Task 2 test lines (`formatter c=…`, `formatter cpp=…`); the mason package name stays `clang-format`.

`CHEATSHEET.md`:
- section "Code", add rows:

```markdown
| Format the buffer                  | `Space c f`           |
| Format on save on / off            | `Space u f`           |
```

  and after the table:

```markdown
Saving formats a file only when its project configures the formatter
(`.stylua.toml`, `.clang-format`, `ruff.toml` or `[tool.ruff]` in
`pyproject.toml`). `Space c f` formats anyway.
```

- "State" line: `State: stage 2 of 6 (code intelligence).`
- "Later" table: delete the row for stage 2.

`README.md`, section "Hosts", after the `local.lua` paragraph add:

```markdown
`local.lua` can also switch off format on save for a host
(`format_on_save = false`); `Space u f` toggles it for the session.
```

`docs/prd-ide.md`, first status line: `Status: stage 2 in progress · Decided 2026-10-05`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `tests/run.sh`
Expected: `N passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add lua/plugins/conform.lua lua/core/env.lua lua/local.lua.example tests/extra/format.lua \
  tests/run.sh tests/probe.lua CHEATSHEET.md README.md docs/prd-ide.md lazy-lock.json
git commit -m "Format on save only in projects that configure the formatter"
```

---

### Task 6: Stage check

**Files:** none changed unless a check fails.

- [ ] **Step 1: Full suite** — `tests/run.sh` → `N passed, 0 failed` (includes the fallback tier: "neovim older than 0.12", "no git and no plugin manager").
- [ ] **Step 2: Health** — start `nvim`, open `lua/core/env.lua`, run `:checkhealth vim.lsp`: no errors other than servers not installed on this host.
- [ ] **Step 3: Lockfile** — `git log -p -1 -- lazy-lock.json` and earlier commits contain mason.nvim, nvim-lspconfig, lazydev.nvim, blink.cmp, friendly-snippets and conform.nvim; `git status` is clean.
