# tableview.nvim

a plugin to open parquet, xlsx, arrow, feather, csv, tsv, json, jsonl files
using DuckDB in the background.

![Screenshot](docs/example.png)

## Installation

### Prerequisite

install DuckDB: https://duckdb.org/install

### `vim.pack` (Neovim 0.12)
```lua
vim.pack.add({ src = "https://github.com/cyprienhm/tableview.nvim" })
```

then you can

```lua
require("tableview").setup()
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  "cyprienhm/tableview.nvim",
  opts = {},
}
```

## Usage

open a data file in a new buffer. You can open the file like any other file:
`:e table.parquet`

you can also use `:TableViewOpen`
`:TableViewOpen table.parquet`

or `require("tableview").open`:
`:lua require("tableview").open("./table.parquet")`

## Configuration

The defaults are:
```lua
require("tableview").setup({
  max_rows = 100,
  column_width_cap = 50,
  duckdb_path = "duckdb",
  auto_open = { "parquet", "arrow", "feather", "xlsx" },
  highlights = {
    TableViewHeader = { default = true, link = "Title" },
    TableViewBorder = { default = true, link = "Comment" },
    TableViewNumber = { default = true, link = "Number" },
    TableViewString = { default = true, link = "String" },
    TableViewNull = { default = true, link = "Comment" },
    TableViewBoolean = { default = true, link = "Boolean" },
  },
})
```
