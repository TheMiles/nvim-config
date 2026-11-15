#!/usr/bin/env bash
#-----------------------------------------------------------
#  Startup tests for the nvim config
#-----------------------------------------------------------
#
# Starts nvim headless against a copy of this config in a temp
# directory and checks what a user would observe: exit code,
# messages, mappings, loaded plugins, highlighting.
# Hosts are simulated by changing the environment (PATH, data
# directory, SSH_TTY), never by changing the config.
#
# Plugins and parsers come from the real data directory (symlinked),
# mason packages do not. Run nvim once normally before running the tests.
#
# usage: tests/run.sh            run all tests
#        NVIM=/path/to/nvim tests/run.sh

set -u

repo=$(cd "$(dirname "$0")/.." && pwd)
probe="$repo/tests/probe.lua"
nvim_bin=${NVIM:-$(command -v nvim)}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# config copy: tests add lua/local.lua and language files here
mkdir -p "$tmp/config"
cp -R "$repo" "$tmp/config/nvim"
rm -rf "$tmp/config/nvim/.git" "$tmp/config/nvim/lua/local.lua"
cfg="$tmp/config/nvim"

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

# PATH with git and a C compiler, but without tree-sitter
mkdir -p "$tmp/bin-no-ts"
for tool in git cc gcc clang; do
  if command -v "$tool" >/dev/null; then
    ln -s "$(command -v "$tool")" "$tmp/bin-no-ts/$tool"
  fi
done
# PATH without anything
mkdir -p "$tmp/bin-empty"
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

failed=0
passed=0
output=
status=

# start nvim, extra environment as arguments: run VAR=value ...
run() {
  output=$(env XDG_CONFIG_HOME="$tmp/config" XDG_DATA_HOME="$tmp/data" "$@" \
    "$nvim_bin" --headless --cmd "luafile $probe" 2>"$tmp/stderr")
  status=$?
}

ok() {
  passed=$((passed + 1))
}

fail() {
  failed=$((failed + 1))
  echo "  FAIL: $1"
}

# expect_line "key=value": output contains exactly this line
expect_line() {
  if grep -qxF -- "$1" <<<"$output"; then ok; else fail "expected '$1'"; fi
}

# expect_no_line "key=value": output does not contain this line
expect_no_line() {
  if grep -qxF -- "$1" <<<"$output"; then fail "unexpected '$1'"; else ok; fi
}

expect_exit_0() {
  if [ "$status" -eq 0 ]; then ok; else fail "exit code $status"; fi
}

# expect_messages n [pattern]: exactly n messages, all matching pattern
expect_messages() {
  local count
  count=$(grep -c '^message=' <<<"$output")
  if [ "$count" -eq "$1" ]; then ok; else fail "expected $1 message(s), got $count:$(grep '^message=' <<<"$output" | sed 's/^/\n    /')"; fi
  if [ $# -gt 1 ] && [ "$count" -gt 0 ]; then
    if grep '^message=' <<<"$output" | grep -qv -- "$2"; then fail "message not matching '$2'"; else ok; fi
  fi
}

section() {
  echo "$1"
}

#-----------------------------------------------------------
section "normal startup"
#-----------------------------------------------------------
run PROBE_FT=lua,c,cpp,python,zzz_unknown
expect_exit_0
expect_messages 0
expect_line "lazy_loaded=true"
expect_line "mapleader= "
for m in "<C-h>" "<C-j>" "<C-k>" "<C-l>" "<C-p>" "<C-b>" \
         "<leader>ff" "<leader>fg" "<leader>fG" "<leader>fb" "<leader>fk"; do
  expect_line "map n $m=desc"
done
expect_line "map i jk=desc"
for ft in lua c cpp python; do
  expect_line "highlight $ft=on"
done
expect_line "highlight zzz_unknown=off"
expect_line "clipboard=none"
expect_line "servers=clangd,lua_ls,basedpyright,ruff"
expect_line "mason=clangd,clang-format,lua-language-server,stylua,basedpyright,ruff"
expect_line "formatter c=clang-format"
expect_line "formatter cpp=clang-format"
expect_line "formatter lua=stylua"
expect_line "formatter python=ruff_format"
for p in python3 ruby node perl; do
  expect_line "provider $p=0"
done

#-----------------------------------------------------------
section "neovim older than 0.12"
#-----------------------------------------------------------
run PROBE_OLD_NVIM=1
expect_exit_0
expect_line "lazy_loaded=false"
expect_line "mapleader= "
expect_line "map n <C-h>=desc"
expect_line "map i jk=desc"
expect_messages 1 "0.12"

#-----------------------------------------------------------
section "no git and no plugin manager"
#-----------------------------------------------------------
mkdir -p "$tmp/data-empty"
run XDG_DATA_HOME="$tmp/data-empty" PATH="$tmp/bin-empty"
expect_exit_0
expect_line "lazy_loaded=false"
expect_line "map n <C-h>=desc"
expect_messages 1 "plugin manager not available"

#-----------------------------------------------------------
section "no tree-sitter cli"
#-----------------------------------------------------------
run PATH="$tmp/bin-no-ts" PROBE_FT=lua,c,markdown,vim,help
expect_exit_0
expect_messages 0
expect_line "ts_install_calls=0"
for ft in lua c markdown vim help; do
  expect_line "highlight $ft=on"
done

#-----------------------------------------------------------
section "ssh session"
#-----------------------------------------------------------
run SSH_TTY=/dev/null
expect_exit_0
expect_line "clipboard=OSC 52 (copy only)"
expect_line "paste=probe"

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

#-----------------------------------------------------------
section "local.lua switches off a plugin and a language"
#-----------------------------------------------------------
cat >"$cfg/lua/local.lua" <<'EOF'
return { plugins = { ['fzf-lua'] = false }, langs = { python = false } }
EOF
run
expect_exit_0
expect_messages 0
expect_line "plugin fzf-lua=off"
expect_line "plugin nvim-tree.lua=loaded"
expect_line "map n <C-p>=no"
if grep '^parsers=' <<<"$output" | grep -qw python; then fail "python parser still collected"; else ok; fi
rm -f "$cfg/lua/local.lua"

#-----------------------------------------------------------
section "local.lua with a syntax error"
#-----------------------------------------------------------
echo "return { plugins = {" >"$cfg/lua/local.lua"
run
expect_exit_0
expect_messages 1 "local.lua ignored"
expect_line "plugin fzf-lua=loaded"
rm -f "$cfg/lua/local.lua"

#-----------------------------------------------------------
section "language files"
#-----------------------------------------------------------
# without tree-sitter, so the made up parser is not installed
cat >"$cfg/lua/lang/zz_new.lua" <<'EOF'
return {
  treesitter = { 'zz_probe', 'lua', 'c' },
  formatters = { zz_ft = { 'zz_fmt' }, lua = { 'zz_other' } },
}
EOF
echo "return { treesitter = {" >"$cfg/lua/lang/zz_broken.lua"
run PATH="$tmp/bin-no-ts"
expect_exit_0
expect_messages 1 "zz_broken.lua ignored"
parsers=$(grep '^parsers=' <<<"$output" | cut -d= -f2)
if tr ',' '\n' <<<"$parsers" | grep -qx zz_probe; then ok; else fail "new parser not collected: $parsers"; fi
if tr ',' '\n' <<<"$parsers" | grep -qx python; then ok; else fail "other languages missing: $parsers"; fi
dups=$(tr ',' '\n' <<<"$parsers" | sort | uniq -d)
if [ -z "$dups" ]; then ok; else fail "duplicate parsers: $dups"; fi
expect_line "formatter zz_ft=zz_fmt"
# lua.lua sorts before zz_new.lua, so its entry wins
expect_line "formatter lua=stylua"
rm -f "$cfg/lua/lang/zz_new.lua" "$cfg/lua/lang/zz_broken.lua"

#-----------------------------------------------------------
section "repository"
#-----------------------------------------------------------
if git -C "$repo" ls-files --error-unmatch lazy-lock.json >/dev/null 2>&1; then ok; else fail "lazy-lock.json not tracked"; fi
if grep -rqE "python3?_host_prog" "$repo/init.lua" "$repo/lua"; then fail "interpreter path hard-coded"; else ok; fi

echo
echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
