local M = {}

local highlights = {
	TableViewHeader = { default = true, link = "Title" },
	TableViewBorder = { default = true, link = "Comment" },
	TableViewData = { default = true, link = "Normal" },
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
		local hl_group = hl.type == "header" and "TableViewHeader" or "TableViewBorder"

		if lines[line_idx + 1] then
			vim.api.nvim_buf_set_extmark(buf, ns, line_idx, 0, {
				end_col = #lines[line_idx + 1],
				hl_group = hl_group,
			})
		end
	end
end

return M
