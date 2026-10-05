# PRD: Neovim as a complete IDE

Status: stage 1 in progress · Decided 2026-10-05

## Architecture Overview

```
                         ┌───────────────────────────┐
                         │         init.lua          │
                         │ options + keymaps, then   │
                         │ version / git gate        │
                         └─────────────┬─────────────┘
              nvim < 0.12 or no git    │    nvim >= 0.12
        ┌──────────────────────────────┴───────────────┐
        ▼                                              ▼
┌───────────────────┐                      ┌───────────────────────┐
│ Tier 1: fallback  │                      │   lazy.nvim (plugins) │
│ options + keymaps │                      │   pinned by lockfile  │
│ built-in colours  │                      └───────────┬───────────┘
└───────────────────┘                                  │ every plugin asks
                                                       ▼
┌───────────────────┐   overrides   ┌──────────────────────────────────┐
│ local.lua         │──────────────▶│ core.env                         │
│ (per host,        │               │ "is this plugin / language /     │
│  not in git)      │               │  external tool available here?"  │
└───────────────────┘               └────────────────┬─────────────────┘
                                                     │
                 ┌───────────────────────────────────┤
                 ▼                                   ▼
┌─────────────────────────────┐      ┌──────────────────────────────────┐
│ Tier 2: pure-Lua plugins    │      │ Tier 3: tool-dependent plugins   │
│ which-key, file tree,       │      │ parsers, language servers,       │
│ statusline, git signs ...   │      │ formatters, debuggers, tests     │
└─────────────────────────────┘      └────────────────┬─────────────────┘
                                                      │ asks "what is needed?"
                                                      ▼
                                     ┌──────────────────────────────────┐
                                     │ core.lang                        │
                                     │ collects one file per language   │
                                     └────────────────┬─────────────────┘
                                                      ▼
                          ┌──────────┬──────────┬──────────┬───────────┐
                          │ lang/lua │ lang/cpp │lang/python│ lang/...  │
                          └──────────┴──────────┴──────────┴───────────┘

External tools (all optional): git, tree-sitter CLI, C compiler, mason
packages (servers, formatters, debug adapters), cmake, lazygit, Claude Code
```

## Problem Statement

The config has a plugin manager, a file tree, a fuzzy finder, syntax
highlighting and a colour scheme. It has no language servers, completion,
formatting, debugging, test running, git integration or statusline, so real
development work still needs a second editor. Several parts are also broken or
stale: the syntax highlighting plugin sits on a branch that does not support
the installed Neovim, one plugin spec uses another plugin manager's syntax, no
leader key exists, and a hard-coded interpreter path from a Linux machine
points at the wrong Python on macOS.

The config must run on several machines: macOS and Linux workstations, remote
hosts over SSH where Neovim runs on the host, and occasionally locked-down
work machines without root, without some toolchains, or with an old Neovim.

## Solution

A hand-written config that picks the best plugin for each job, where every
plugin can be switched off on its own. What loads on a host is decided in
three tiers:

1. **Fallback.** Neovim older than 0.12, or no usable `git`: only options and
   keymaps load, with a built-in colour scheme and a one-line notice.
2. **Pure-Lua plugins** always load.
3. **Tool-dependent features** load only when their external tool is present.
   A missing tool is skipped silently.

An untracked per-host file can switch off individual plugins, whole languages
and (later) AI assistance, for cases detection cannot see.

Language support is organised by language: one file declares everything a
language needs, so adding Rust, TypeScript or Elixir later means adding one
file.

### Language tiers

| Tier | Languages | Gets |
|---|---|---|
| 1 | C/C++ (CMake), Python, Lua | highlighting, language server, formatting, debugger, tests |
| 2 | LaTeX, JavaScript/HTML, Markdown, Bash, Zsh, JSON/YAML/TOML | highlighting, language server, formatting |
| Later | Rust, TypeScript, Elixir | one new language file each |

## User Stories

1. As a user on a host with an old Neovim, I want the config to start cleanly with my options and keymaps, so that I can still edit comfortably there.
   - AC1: with the 0.12 feature check reporting false, headless startup exits 0 and the plugin manager is not loaded.
   - AC2: in that mode `mapleader` is a space, `<C-h>` is mapped in normal mode, and `jk` is mapped in insert mode.
   - AC3: exactly one notice naming the required version is emitted.

2. As a user on a host without `git` or network, I want startup to degrade instead of aborting, so that the editor is still usable.
   - AC1: when the plugin manager cannot be obtained, startup exits 0 in fallback mode and Neovim is not terminated by the config.

3. As a user on a host missing a toolchain, I want tool-dependent features skipped silently, so that I am not greeted by errors.
   - AC1: with no `tree-sitter` executable on `PATH`, headless startup emits no error message and no parser installation is attempted.
   - AC2: filetypes whose parser ships with Neovim (Lua, C, Markdown, Vimscript, help) still get tree-sitter highlighting in that situation.

4. As a user with several machines, I want to switch off plugins and languages per host without touching tracked files, so that one repository serves all hosts.
   - AC1: a per-host file that disables a plugin by name causes that plugin not to be loaded.
   - AC2: a per-host file that disables a language removes that language's entries from every collected list.
   - AC3: with no per-host file present, startup emits no warning.
   - AC4: a per-host file with a syntax error produces one warning and startup continues with defaults.

5. As a user, I want identical plugin versions everywhere, so that a fresh clone behaves like my main machine.
   - AC1: the plugin lockfile is tracked by git.

6. As a user, I want all support for one language declared in one place, so that adding a language is one new file.
   - AC1: adding a language file that names a parser makes that parser appear in the collected parser list without any other file changing.
   - AC2: collected lists contain no duplicates.
   - AC3: a language file that fails to load produces one warning and the other languages still load.

7. As a user, I want syntax highlighting that works on current Neovim, so that code is readable.
   - AC1: opening a Lua, C, C++ or Python buffer starts a tree-sitter highlighter for it.
   - AC2: opening a filetype with no installed parser raises no error.

8. As a user, I want a leader key with mnemonic groups and an on-screen menu, so that I can find commands without memorising them.
   - AC1: `<leader>ff`, `<leader>fg`, `<leader>fG`, `<leader>fb` and `<leader>fk` are mapped and each has a description.
   - AC2: `<C-p>` and `<C-b>` remain mapped to file search and the file tree.
   - AC3: `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` move between windows.

9. As a user working over SSH, I want yanked text to reach my local clipboard, so that copying works like it does locally.
   - AC1: with `SSH_TTY` set, the clipboard provider is the OSC 52 copy provider and paste reads the internal register without querying the terminal.
   - AC2: without `SSH_TTY`, no custom clipboard provider is set.

10. As a user, I want `:checkhealth` free of noise from unused providers, so that real problems stand out.
    - AC1: the Python, Ruby, Node and Perl providers are disabled and no interpreter path is hard-coded.

11. As a developer, I want code intelligence for my languages, so that I can navigate, complete and fix code in the editor. *(stage 2)*
    - AC1: opening a Lua, C/C++ or Python file attaches the configured language server when its executable exists, and attaches nothing and reports no error when it does not.
    - AC2: the completion menu offers language-server, path, buffer and snippet items; `Tab` accepts and `Enter` inserts a newline.
    - AC3: the full diagnostic message is shown only for the cursor line; other lines show sign and underline.

12. As a developer, I want formatting that respects foreign projects, so that I never reformat a file by accident. *(stage 2)*
    - AC1: saving a file formats it only when its project contains a configuration for that formatter.
    - AC2: the manual format key formats regardless of project configuration.
    - AC3: a toggle switches format-on-save for the session.

13. As a user, I want a familiar editor surface, so that I always see where I am. *(stage 3)*
    - AC1: a statusline and a tab line of open buffers are shown; closing a buffer keeps the window layout.
    - AC2: project diagnostics and a symbol outline open in a list panel.
    - AC3: a terminal toggles on one key.
    - AC4: `Ctrl-/` toggles comments, a key adds a cursor on the next match, and commands and document symbols are searchable.

14. As a developer, I want git inside the editor, so that I can review and stage without leaving it. *(stage 4)*
    - AC1: changed lines are marked in the sign column and hunks can be navigated, staged and reset.
    - AC2: the lazygit key exists only when `lazygit` is installed.
    - AC3: a diff view and a single-file history view can be opened.

15. As a developer, I want to build, run, debug and test from the editor, so that the whole loop stays in one place. *(stage 5)*
    - AC1: project tasks are discovered and run in the background with errors sent to the quickfix list.
    - AC2: for CMake projects, preset, build type and target can be selected and the compile database is placed where the C/C++ language server finds it.
    - AC3: breakpoints, stepping and variable inspection work for C/C++ and Python; launch configurations are read from the project.
    - AC4: the test under the cursor, the file and the whole suite can be run for pytest and for CTest-registered Catch2 and GoogleTest tests.

16. As a user, I want the remaining languages and optional AI assistance, so that occasional work is covered too. *(stage 6)*
    - AC1: each tier 2 language has a language file providing highlighting, a language server and a formatter where one exists.
    - AC2: the AI integration is not loaded unless the per-host file enables it.

## Implementation Decisions

**Foundation**

- Minimum Neovim for anything beyond the fallback tier is 0.12. The rewritten highlighting plugin requires it, and a second code path for 0.11 would never be tested.
- Options and generic keymaps load before the version gate and use only long-standing APIs, so they work in the fallback tier.
- Plugin-specific keymaps live with their plugin, not in the generic keymap file, so that no mapping points at a missing command.
- One module answers every availability question (executable present, plugin enabled, language enabled, SSH session). The plugin manager's global default condition consults it, so a per-host override needs no change to any plugin file.
- The per-host file is optional and untracked; an example is tracked.
- Leader is space, local leader is comma. Groups: `f` find, `c` code, `d` debug, `g` git, `r` run, `t` test, `x` diagnostics, `b` buffer, `u` toggles, `a` AI.
- Language files are plain data: filetypes, parsers, language servers, installer packages, formatters, linters, debug adapter, plus an optional list of language-specific plugins. A collector module reads the language directory and exposes flattened, de-duplicated lists per field.
- The plugin lockfile is tracked.
- All remote-plugin providers are disabled.
- Over SSH, copying uses OSC 52; pasting uses the terminal's own paste, because querying the terminal clipboard is usually blocked and hangs.

**Code intelligence (stage 2)**

- Language servers are configured through Neovim's native API; the community config collection is used only as data. A server is enabled only when its executable exists.
- Servers and tools are installed per user by mason, with no root needed.
- Servers: clangd; basedpyright and ruff; lua_ls with Neovim API typings; texlab; bashls (also attached to Zsh); jsonls, yamlls, taplo; marksman; vtsls; html.
- Completion: blink.cmp with the `super-tab` preset and friendly-snippets on the built-in snippet engine.
- Formatting: conform.nvim; linting beyond language servers: nvim-lint.
- Format-on-save only when the project carries a formatter configuration; session toggle and per-host default.

**Surface (stage 3)**

- lualine, bufferline, trouble, which-key.
- snacks.nvim, enabling only: terminal, word highlighting, indent guides, buffer delete, lazygit. Its picker is not used; fzf-lua stays.
- nvim-autopairs, nvim-surround, multicursor.nvim on `Ctrl-N`.

**Git (stage 4):** gitsigns, lazygit in a float, diffview.

**Run and debug (stage 5)**

- overseer.nvim as the task runner for all languages; cmake-tools.nvim as a C/C++ language plugin.
- nvim-dap with codelldb and debugpy, nvim-dap-ui and inline values; launch configurations come from the project's `.vscode/launch.json`.
- neotest with the Python adapter and the CTest adapter. Fallback if the CTest adapter is unreliable: run `ctest` as a task.

**AI (stage 6):** claudecode.nvim, off unless enabled per host.

## Testing Decisions

- A good test here asserts what a user would observe after startup: exit code, emitted messages, whether a mapping or highlighter exists, which plugins loaded. It does not assert how a module is written.
- Verification runs Neovim headless against the real config. Tiers are exercised by changing the environment, not the code: the version check is overridden from the command line for tier 1, and `PATH` is narrowed for tier 3.
- After every stage: startup emits no error, `:checkhealth` shows no new problems, and the fallback tier still starts.
- The two modules with logic of their own, the availability module and the language collector, are the ones worth checking directly (per-host overrides, de-duplication, a broken language file).
- There is no prior test code in this repository.

## Out of Scope

- Full LaTeX workflow: vimtex, PDF viewer integration, SyncTeX, custom snippets. LaTeX is tier 2.
- Shared navigation between Neovim windows and tmux panes; it needs changes to the tmux config, which lives outside this repository.
- Inline AI completion while typing.
- Rust, TypeScript and Elixir language files.
- Support for Neovim 0.11 beyond the fallback tier.
- Editing files on a remote host from a local Neovim.

## Further Notes

**Stages.** Each stage is built on its own branch and used for a few days before the next one starts.

| # | Stage | Contents |
|---|---|---|
| 1 | Foundation | cleanup, leader and keymap scheme, version gate, per-host file, lockfile, tree-sitter rewrite, language collector, which-key, clipboard over SSH |
| 2 | Code intelligence | mason, language servers, completion, formatting and linting, diagnostic display; Lua, C/C++, Python |
| 3 | Surface | statusline, buffer tabs, lists, terminal, editing comfort, Sublime Text habits |
| 4 | Git | signs, lazygit, diff view |
| 5 | Run and debug | tasks, CMake, debugger, tests |
| 6 | Rest | tier 2 languages, AI integration |

**To verify when the stage arrives**

- Zsh (stage 6): whether a tree-sitter parser exists and whether the shell formatter handles Zsh. Zsh gets a syntax check instead of shellcheck, which does not support it.
- CTest test adapter (stage 5): reliability with Catch2 and GoogleTest.
- Every plugin: that it supports Neovim 0.12 and is still maintained.

**Setup outside this repository**

- `tree-sitter` CLI 0.26.1 or newer and a C compiler, for parser installation.
- A Nerd Font in the local terminal.
- For copy over SSH: `set -g set-clipboard on` in the host's tmux config, and in iTerm2 "Applications in terminal may access clipboard".
- The user's tmux config binds `C-l` globally (passes the key through, then clears history). This works with window navigation in Neovim but must change before tmux pane navigation can share the same keys.

**Background.** The user's key habits come from Sublime Text and a US keyboard layout in the terminal.
