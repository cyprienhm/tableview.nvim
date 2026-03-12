local M = {}

local ns = vim.api.nvim_create_namespace("tableview")

local type_to_hl = {
	header = "TableViewHeader",
	border = "TableViewBorder",
	number = "TableViewNumber",
	string = "TableViewString",
	null = "TableViewNull",
	boolean = "TableViewBoolean",
}

local did_setup = false

function M.setup()
	if did_setup then
		return
	end
	local config = require("tableview.config").options
	for name, opts in pairs(config.highlights) do
		vim.api.nvim_set_hl(0, name, opts)
	end
	did_setup = true
end

function M.apply(buf, highlight_data)
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	local line_count = vim.api.nvim_buf_line_count(buf)

	for _, hl in ipairs(highlight_data) do
		local hl_group = type_to_hl[hl.type]
		if hl_group and hl.line < line_count then
			vim.api.nvim_buf_set_extmark(buf, ns, hl.line, hl.col_start, {
				end_col = hl.col_end,
				hl_group = hl_group,
			})
		end
	end
end

return M
