local M = {}

local highlights = {
	TableViewHeader = { default = true, link = "Title" },
	TableViewBorder = { default = true, link = "Comment" },
	TableViewData = { default = true, link = "Normal" },
	TableViewNumber = { default = true, link = "Number" },
	TableViewString = { default = true, link = "String" },
	TableViewNull = { default = true, link = "Comment" },
	TableViewBoolean = { default = true, link = "Boolean" },
}

local type_to_hl = {
	header = "TableViewHeader",
	border = "TableViewBorder",
	data = "TableViewData",
	number = "TableViewNumber",
	string = "TableViewString",
	null = "TableViewNull",
	boolean = "TableViewBoolean",
}

function M.setup()
	for k, v in pairs(highlights) do
		vim.api.nvim_set_hl(0, k, v)
	end
end

function M.apply_structured_highlights(buf, highlight_data)
	local ns = vim.api.nvim_create_namespace("tableview")
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	for _, hl in ipairs(highlight_data) do
		local line_idx = hl.line
		local hl_group = type_to_hl[hl.type]

		if lines[line_idx + 1] and hl_group then
			vim.api.nvim_buf_set_extmark(buf, ns, line_idx, hl.col_start, {
				end_col = hl.col_end,
				hl_group = hl_group,
			})
		end
	end
end

return M
