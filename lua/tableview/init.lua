local M = {}
local highlights = require("tableview.highlights")
local readers = require("tableview.readers")

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

function M.open(filename)
	if not filename or filename == "" then
		vim.notify("TableView: No filename provided", vim.log.levels.ERROR)
		return
	end

	local format = detect_format(filename)
	local content, err

	if format == "parquet" then
		content, err = readers.read_parquet(filename)
	elseif format == "csv" then
		content, err = readers.read_csv(filename)
	elseif format == "tsv" then
		content, err = readers.read_csv(filename, "\t")
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
