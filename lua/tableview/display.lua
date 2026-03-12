local M = {}
local highlights = require("tableview.highlights")

function M.show(lines, highlight_data, filename, existing_buf)
	local buf

	if existing_buf then
		buf = existing_buf
	else
		local buf_name = "TableView://" .. filename
		local found = vim.fn.bufnr(buf_name)
		if found ~= -1 then
			buf = found
		else
			buf = vim.api.nvim_create_buf(true, false)
			vim.api.nvim_buf_set_name(buf, buf_name)
		end
	end

	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	highlights.apply(buf, highlight_data)

	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
	vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
	vim.api.nvim_set_option_value("filetype", "tableview", { buf = buf })

	if not existing_buf then
		vim.api.nvim_win_set_buf(0, buf)
	end

	vim.keymap.set("n", "q", "<cmd>bdelete<cr>", { buffer = buf, noremap = true, silent = true })
end

return M
