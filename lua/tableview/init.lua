local M = {}
local highlights = require("tableview.highlights")

local function detect_format(filename)
	local ext = filename:match("%.([^%.]+)$")
	if ext then
		ext = ext:lower()
		if ext == "parquet" then
			return "parquet"
		elseif ext == "csv" then
			return "csv"
		elseif ext == "tsv" then
			return "tsv"
		end
	end
	return "unknown"
end

local function execute_python_formatting(python_code)
	local result = vim.system({ "python3", "-c", python_code }, {
		stdout_buffered = true,
		stderr_buffered = true,
	}):wait()

	if result.code == 0 then
		return result.stdout, nil
	end

	return result.stderr, "Python error when reading file"
end

local function read_parquet(filename)
	local python_code = string.format(
		[[
import pyarrow.parquet as pq
import json

table = pq.read_table('%s')

lines = []
highlights = []

lines.append(f"Shape: ({table.num_rows}, {table.num_columns})")
lines.append("Columns:")
for i, col_name in enumerate(table.column_names):
    col_type = table.schema.field(i).type
    lines.append(f"  {col_name}: {col_type}")
lines.append("")

display_table = table.slice(0, min(100, table.num_rows))
df = display_table.to_pandas()

maxpercol = df.map(lambda x: len(str(x)) if x is not None else 3).max().to_dict()
maxpercol = {col_name: max(len(col_name), width) for col_name, width in maxpercol.items()}

border_line = "+" + "+".join(["-" * (width + 2) for width in maxpercol.values()]) + "+"
header_line = "|" + "|".join([f" {col_name: ^{width}} " for col_name, width in maxpercol.items()]) + "|"

lines.append(border_line)
highlights.append({"line": len(lines) - 1, "type": "border"})

lines.append(header_line)
highlights.append({"line": len(lines) - 1, "type": "header"})

lines.append(border_line)
highlights.append({"line": len(lines) - 1, "type": "border"})

for i, row in df.iterrows():
    row_line = "|"
    for col in df.columns:
        width = maxpercol[col]
        elt = row[col]
        if elt is None or str(elt) == 'nan':
            elt = "nan"
        row_line += f" {str(elt): ^{width}} |"
    lines.append(row_line)

lines.append(border_line)
highlights.append({"line": len(lines) - 1, "type": "border"})

result = {"lines": lines, "highlights": highlights}
print(json.dumps(result))
]],
		filename
	)

	return execute_python_formatting(python_code)
end

local function read_csv(filename, delimiter)
	if not delimiter then
		delimiter = "None"
	else
		delimiter = '"' .. delimiter .. '"'
	end

	local python_code = string.format(
		[[
import pandas as pd
import json

df = pd.read_csv('%s', sep=%s, nrows=100)

lines = []
highlights = []

lines.append(f"Shape: ({len(df)}, {len(df.columns)})")
lines.append("Columns:")
for col in df.columns:
    lines.append(f"  {col}: {df[col].dtype}")
lines.append("")

maxpercol = df.map(lambda x: len(str(x)) if x is not None else 3).max().to_dict()
maxpercol = {col_name: max(len(col_name), width) for col_name, width in maxpercol.items()}

border_line = "+" + "+".join(["-" * (width + 2) for width in maxpercol.values()]) + "+"
header_line = "|" + "|".join([f" {col_name: ^{width}} " for col_name, width in maxpercol.items()]) + "|"

lines.append(border_line)
highlights.append({"line": len(lines) - 1, "type": "border"})

lines.append(header_line)
highlights.append({"line": len(lines) - 1, "type": "header"})

lines.append(border_line)
highlights.append({"line": len(lines) - 1, "type": "border"})

for i, row in df.iterrows():
    row_line = "|"
    for col in df.columns:
        width = maxpercol[col]
        elt = row[col]
        if pd.isna(elt):
            elt = "nan"
        row_line += f" {str(elt): ^{width}} |"
    lines.append(row_line)

lines.append(border_line)
highlights.append({"line": len(lines) - 1, "type": "border"})

result = {"lines": lines, "highlights": highlights}
print(json.dumps(result))
]],
		filename,
		delimiter
	)

	return execute_python_formatting(python_code)
end

function M.open(filename)
	if not filename or filename == "" then
		vim.notify("TableView: No filename provided", vim.log.levels.ERROR)
		return
	end

	local format = detect_format(filename)
	local content, err

	if format == "parquet" then
		content, err = read_parquet(filename)
	elseif format == "csv" then
		content, err = read_csv(filename)
	elseif format == "tsv" then
		content, err = read_csv(filename, "\t")
	else
		vim.notify("TableView: Unsupported file format", vim.log.levels.ERROR)
		return
	end
	if err then
		vim.notify("TableView: " .. err, vim.log.levels.ERROR)
	end
	M.display_formatted_content(content, filename)
end

function M.display_formatted_content(content, filename)
	local buf_name = "TableView: " .. vim.fn.fnamemodify(filename, ":t")
	local existing_buf = vim.fn.bufnr(buf_name)

	local buf
	if existing_buf ~= -1 then
		buf = existing_buf
		vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	else
		buf = vim.api.nvim_create_buf(true, true)
		vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
		vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
		vim.api.nvim_buf_set_name(buf, buf_name)
	end

	local data = vim.json.decode(content)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, data.lines)
	highlights.setup()
	highlights.apply_structured_highlights(buf, data.highlights)

	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	vim.api.nvim_set_option_value("filetype", "tableview", { buf = buf })

	vim.api.nvim_win_set_buf(0, buf)

	local keymaps = {
		{ "n", "q", "<cmd>bdelete<cr>" },
	}

	for _, keymap in ipairs(keymaps) do
		vim.api.nvim_buf_set_keymap(buf, keymap[1], keymap[2], keymap[3], { noremap = true, silent = true })
	end
end

function M.close()
	local buf = vim.api.nvim_get_current_buf()
	local name = vim.api.nvim_buf_get_name(buf)
	if name:match("^TableView:") then
		vim.api.nvim_buf_delete(buf, {})
	end
end

function M.setup() end

return M
