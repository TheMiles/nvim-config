# Cheat sheet

How to get things done with this config. Open it in nvim with `Space h`.

`<leader>` is `Space`. Press it and wait: a menu shows what comes next.

State: stage 1 of 6 (foundation). Sections marked *later* list what the
coming stages add, see [docs/prd-ide.md](docs/prd-ide.md).

## Find things

| I want to                           | Keys               |
|-------------------------------------|--------------------|
| Open a file by name                 | `Ctrl-p` or `Space f f` |
| Search text in the project, live    | `Space f g`        |
| Search text, then filter the hits   | `Space f G`        |
| Switch to an open buffer by name    | `Space f b`        |
| Look up a keybinding                | `Space f k`        |
| Search in the current file          | `/`, then `n` / `N` |
| Search the word under the cursor    | `*` forward, `#` backward |
| Clear the search highlight          | `Esc`              |

Inside the search window: type to filter, `Ctrl-j` / `Ctrl-k` or arrows to
move, `Enter` to open, `Esc` to close.

## Move between files and windows

| I want to                        | Keys                      |
|----------------------------------|---------------------------|
| Show / hide the file tree        | `Ctrl-b`                  |
| Next / previous buffer           | `Shift-l` / `Shift-h`     |
| Go to the window left / right    | `Ctrl-h` / `Ctrl-l`       |
| Go to the window below / above   | `Ctrl-j` / `Ctrl-k`       |
| Split window side by side / stacked | `:vsplit` / `:split`   |
| Close the window                 | `:q`                      |

In the file tree: `Enter` open, `a` new file (end with `/` for a directory),
`r` rename, `d` delete, `x` cut, `c` copy, `p` paste, `R` refresh,
`Ctrl-v` / `Ctrl-x` open in a vertical / horizontal split, `Ctrl-t` open in a
new tab, `q` close, `g?` help.

## Move in a file

| Key        | Does what                    | Key        | Does what               |
|------------|------------------------------|------------|-------------------------|
| `h` `l`    | Left, right                  | `j` `k`    | Down, up                |
| `w` `b`    | Next / previous word         | `e`        | End of word             |
| `0` `$`    | Line start / end             | `^`        | First non blank char    |
| `f<c>` `F<c>` | Next / previous `<c>` in line | `%`     | Matching bracket        |
| `gg` `G`   | Buffer start / end           | `<n>G`     | Line `<n>`              |
| `Ctrl-d` `Ctrl-u` | Half a page down / up | `Ctrl-f`   | A page down             |
| `{` `}`    | Paragraph up / down          | `(` `)`    | Sentence up / down      |
| `m<c>`     | Bookmark position in `<c>`   | `` `<c> `` | Jump to bookmark `<c>`  |
| `` `` ``   | Toggle last two positions    | `` `. ``   | Last edit               |

## Edit

| I want to                         | Keys                          |
|-----------------------------------|-------------------------------|
| Leave insert or terminal mode     | `jk` or `Esc`                 |
| Insert before / after the cursor  | `i` / `a`                     |
| Insert at line start / end        | `I` / `A`                     |
| New line below / above            | `o` / `O`                     |
| Change the word                   | `ciw`                         |
| Change to the end of the line     | `C`                           |
| Change inside brackets or quotes  | `ci(`, `ci{`, `ci"`           |
| Replace one character             | `r`                           |
| Join the next line                | `J`                           |
| Upper / lower case a word         | `gUw` / `guw`                 |
| Comment a line / a selection      | `gcc` / select, then `gc`     |
| Indent a selection                | select, then `>` or `<` (selection stays) |
| Fix the indentation of a line     | `==`                          |
| Undo / redo                       | `u` / `Ctrl-r`                |
| Repeat the last change            | `.`                           |

## Copy and paste

| I want to                          | Keys                 |
|------------------------------------|----------------------|
| Copy a line / `<n>` lines          | `yy` / `y<n>y`       |
| Copy the word / inside brackets    | `yiw` / `yi{`        |
| Copy to line end / up to `<c>`     | `y$` / `yt<c>`       |
| Delete (cut), same targets         | `dd`, `diw`, `d$`, ... |
| Paste after / before the cursor    | `p` / `P`            |
| Select characters / lines / a block | `v` / `V` / `Ctrl-v` |
| Paste a register while typing      | `Ctrl-r <register>`  |

Yank and delete use the system clipboard. In a ssh session yank reaches the
local clipboard; to paste from it there use the terminal's paste (`Cmd-v`).

## Change the same thing in many places

Sublime's `Ctrl-d` has no single counterpart yet (a multi cursor plugin comes
in stage 3). These work everywhere:

| I want to                               | Keys                                   |
|-----------------------------------------|----------------------------------------|
| Change this word, then the next ones one by one | `*`, `cgn`, type, `Esc`, then `.` for each further match (`n` skips one) |
| Edit a column on several lines          | `Ctrl-v`, select down, `I` or `A`, type, `Esc` |
| Replace in the whole file               | `:%s/old/new/g` (add `c` to confirm each) |
| Replace in the selection                | select, `:s/old/new/g`                 |
| Delete all lines matching / not matching | `:g/pattern/d` / `:v/pattern/d`       |
| Record and replay a macro               | `q<c>` ... `q`, then `@<c>`            |

## Commands

| Command              | Does what                              |
|----------------------|----------------------------------------|
| `:read <path>`       | Insert a file into the buffer          |
| `:read !<command>`   | Insert the output of a command         |
| `:sort` / `:sort!`   | Sort lines ascending / descending      |
| `:Lazy`              | Plugin manager panel                   |
| `:Lazy sync`         | Install, clean and update plugins      |
| `:TSUpdate`          | Update the syntax parsers              |
| `:checkhealth`       | Is everything set up on this host      |

## Later

| Stage | Adds                                                        | Keys start with |
|-------|-------------------------------------------------------------|-----------------|
| 2     | Go to definition, rename, completion, formatting, diagnostics | `Space c`, `Space x` |
| 3     | Statusline, buffer tabs, terminal, multi cursor, command palette | `Space b`, `Ctrl-\`, `Ctrl-n` |
| 4     | Git signs, lazygit, diff view                               | `Space g`       |
| 5     | Build and run, debugger, tests                              | `Space r`, `Space d`, `Space t` |
| 6     | More languages, Claude Code                                 | `Space a`       |
