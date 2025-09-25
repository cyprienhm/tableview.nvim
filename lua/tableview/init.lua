local M = {}

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

local function read_parquet(filename)
	local python_code = string.format(
		[[
import pyarrow.parquet as pq
table = pq.read_table('%s')

print(f"Shape: ({table.num_rows}, {table.num_columns})")
print("Columns:")
for i, col_name in enumerate(table.column_names):
    col_type = table.schema.field(i).type
    print(f"  {col_name}: {col_type}")
print()

# Show only first 100 rows
display_table = table.slice(0, min(100, table.num_rows))
print(display_table.to_pandas().to_csv(index=False))
]],
		filename
	)

	local result = vim.system({ "python3", "-c", python_code }, {
		stdout_buffered = true,
		stderr_buffered = true,
	}):wait()

	if result.code == 0 then
		return result.stdout, nil
	end

	return nil, "Python or pyarrow not available."
end

local function read_csv(filename, delimiter)
	delimiter = delimiter or ","
	local file = io.open(filename, "r")
	if not file then
		return nil, "Could not open file"
	end

	local content = file:read("*a")
	file:close()
	return content, nil
end

local function parse_csv_to_table(content, delimiter)
	delimiter = delimiter or ","
	local lines = {}
	for line in content:gmatch("[^\r\n]+") do
		local fields = {}
		local field = ""
		local in_quotes = false

		for i = 1, #line do
			local char = line:sub(i, i)
			if char == '"' then
				in_quotes = not in_quotes
			elseif char == delimiter and not in_quotes then
				table.insert(fields, field)
				field = ""
			else
				field = field .. char
			end
		end
		table.insert(fields, field)
		table.insert(lines, fields)
	end
	return lines
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
		content, err = read_csv(filename, ",")
	elseif format == "tsv" then
		content, err = read_csv(filename, "\t")
	else
		vim.notify("TableView: Unsupported file format", vim.log.levels.ERROR)
		return
	end

	if err then
		vim.notify("TableView: " .. err, vim.log.levels.ERROR)
		return
	end

	local data = parse_csv_to_table(content)
	if #data == 0 then
		vim.notify("TableView: No data found", vim.log.levels.ERROR)
		return
	end

	M.display_table(data, filename)
end

local function calculate_column_widths(data)
	local widths = {}
	for _, row in ipairs(data) do
		for j, cell in ipairs(row) do
			local len = string.len(tostring(cell))
			widths[j] = math.max(widths[j] or 0, len)
		end
	end
	return widths
end

local function format_table_lines(data)
	local widths = calculate_column_widths(data)
	local lines = {}

	for i, row in ipairs(data) do
		local formatted_cells = {}
		for j, cell in ipairs(row) do
			local padded = string.format("%-" .. widths[j] .. "s", tostring(cell))
			table.insert(formatted_cells, padded)
		end
		table.insert(lines, table.concat(formatted_cells, " │ "))

		if i == 1 then
			local separator_cells = {}
			for j = 1, #row do
				table.insert(separator_cells, string.rep("─", widths[j]))
			end
			table.insert(lines, table.concat(separator_cells, "─┼─"))
		end
	end

	return lines
end

function M.display_table(data, filename)
	local buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
	vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
	vim.api.nvim_buf_set_name(buf, "TableView: " .. vim.fn.fnamemodify(filename, ":t"))

	local lines = format_table_lines(data)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

	vim.api.nvim_win_set_buf(0, buf)

	local keymaps = {
		{ "n", "q", "<cmd>bdelete<cr>" },
		{ "n", "<C-c>", "<cmd>bdelete<cr>" },
		{ "n", "j", "j" },
		{ "n", "k", "k" },
		{ "n", "h", "h" },
		{ "n", "l", "l" },
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
