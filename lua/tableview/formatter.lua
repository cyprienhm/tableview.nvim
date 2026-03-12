local M = {}

local function truncate(s, w)
	if vim.fn.strdisplaywidth(s) <= w then
		return s
	end
	local chars = vim.fn.strchars(s)
	for i = chars - 1, 0, -1 do
		local sub = vim.fn.strcharpart(s, 0, i)
		if vim.fn.strdisplaywidth(sub) <= w - 1 then
			return sub .. "~"
		end
	end
	return "~"
end

local function align(s, w, alignment)
	local pad = w - vim.fn.strdisplaywidth(s)
	if pad <= 0 then
		return s
	end
	if alignment == "right" then
		return string.rep(" ", pad) .. s
	elseif alignment == "center" then
		local left = math.floor(pad / 2)
		local right = pad - left
		return string.rep(" ", left) .. s .. string.rep(" ", right)
	end
	return s .. string.rep(" ", pad)
end

local function classify(value)
	if value == "NULL" or value == "" then
		return "null"
	elseif value == "true" or value == "false" then
		return "boolean"
	elseif tonumber(value) ~= nil then
		return "number"
	end
	return "string"
end

function M.format(headers, rows, opts)
	local cap = opts.column_width_cap or 50
	local lines = {}
	local highlights = {}

	-- Column widths
	local widths = {}
	for i, h in ipairs(headers) do
		widths[i] = vim.fn.strdisplaywidth(h)
	end
	for _, row in ipairs(rows) do
		for i, cell in ipairs(row) do
			local w = vim.fn.strdisplaywidth(cell)
			if not widths[i] or w > widths[i] then
				widths[i] = w
			end
		end
	end
	for i, w in ipairs(widths) do
		if w > cap then
			widths[i] = cap
		end
	end

	-- Border line
	local border_parts = { "+" }
	for _, w in ipairs(widths) do
		table.insert(border_parts, string.rep("-", w + 2))
		table.insert(border_parts, "+")
	end
	local border_line = table.concat(border_parts)

	local function add_border()
		table.insert(lines, border_line)
		table.insert(highlights, {
			line = #lines - 1,
			col_start = 0,
			col_end = #border_line,
			type = "border",
		})
	end

	-- Top border
	add_border()

	-- Header row: track byte positions by building string incrementally
	local header_line = "|"
	local header_hl = {}
	for i, h in ipairs(headers) do
		local t = truncate(h, widths[i])
		local cell = " " .. align(t, widths[i], "center") .. " "
		local col_start = #header_line
		header_line = header_line .. cell
		local col_end = #header_line
		header_line = header_line .. "|"
		table.insert(header_hl, {
			line = #lines,
			col_start = col_start,
			col_end = col_end,
			type = "header",
		})
	end
	table.insert(lines, header_line)
	for _, hl in ipairs(header_hl) do
		table.insert(highlights, hl)
	end

	-- Header-data separator
	add_border()

	-- Data rows
	for _, row in ipairs(rows) do
		local data_line = "|"
		local row_hl = {}

		for i = 1, #headers do
			local cell = row[i] or ""
			local cell_type = classify(cell)
			local t = truncate(cell, widths[i])

			local cell_align = "left"
			if cell_type == "number" then
				cell_align = "right"
			elseif cell_type == "null" or cell_type == "boolean" then
				cell_align = "center"
			end

			local padded = " " .. align(t, widths[i], cell_align) .. " "
			local col_start = #data_line
			data_line = data_line .. padded
			local col_end = #data_line
			data_line = data_line .. "|"

			table.insert(row_hl, {
				line = #lines,
				col_start = col_start,
				col_end = col_end,
				type = cell_type,
			})
		end

		table.insert(lines, data_line)
		for _, hl in ipairs(row_hl) do
			table.insert(highlights, hl)
		end
	end

	-- Bottom border
	add_border()

	return { lines = lines, highlights = highlights }
end

return M
