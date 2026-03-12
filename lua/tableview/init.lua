local M = {}
local config = require("tableview.config")
local reader = require("tableview.reader")
local formatter = require("tableview.formatter")
local display = require("tableview.display")
local highlights = require("tableview.highlights")

function M.open(filename, buf)
	if not filename or filename == "" then
		vim.notify("TableView: No filename provided", vim.log.levels.ERROR)
		return
	end

	if filename:match("^TableView:") then
		return
	end

	local filepath = vim.fn.fnamemodify(filename, ":p")
	local ext = filepath:match("%.([^%.]+)$")
	ext = ext and ext:lower()

	if not ext or not reader.supports(ext) then
		vim.notify("TableView: Unsupported format: " .. (ext or "none"), vim.log.levels.ERROR)
		return
	end

	reader.read(filepath, ext, function(json_text, err)
		if err then
			vim.notify("TableView: " .. err, vim.log.levels.ERROR)
			return
		end

		local ok, data = pcall(vim.json.decode, json_text)
		if not ok or not data or #data == 0 then
			vim.notify("TableView: No data found", vim.log.levels.WARN)
			return
		end

		-- Extract headers in original column order from raw JSON
		local headers = {}
		local seen = {}
		for key in json_text:gmatch('"([^"]+)"%s*:') do
			if not seen[key] then
				seen[key] = true
				table.insert(headers, key)
			end
		end

		-- Extract rows as arrays in header order
		local rows = {}
		for _, record in ipairs(data) do
			local row = {}
			for i, h in ipairs(headers) do
				local val = record[h]
				if val == nil or val == vim.NIL then
					row[i] = "NULL"
				elseif type(val) == "table" then
					row[i] = vim.json.encode(val)
				else
					row[i] = tostring(val)
				end
			end
			table.insert(rows, row)
		end

		local formatted = formatter.format(headers, rows, config.options)
		display.show(formatted.lines, formatted.highlights, filepath, buf)
	end)
end

function M.close()
	local buf = vim.api.nvim_get_current_buf()
	local name = vim.api.nvim_buf_get_name(buf)
	if name:match("^TableView:") then
		vim.api.nvim_buf_delete(buf, {})
	end
end

function M.setup(opts)
	config.setup(opts)
	highlights.setup()

	local group = vim.api.nvim_create_augroup("tableview", { clear = true })
	for _, ext in ipairs(config.options.auto_open) do
		vim.api.nvim_create_autocmd("BufReadCmd", {
			group = group,
			pattern = "*." .. ext,
			callback = function(ev)
				M.open(ev.file, ev.buf)
			end,
		})
	end
end

return M
