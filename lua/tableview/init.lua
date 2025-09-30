local M = {}
local readers = require("tableview.readers")
local display = require("tableview.display")

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
	display.display_formatted_content(content, filename)
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
