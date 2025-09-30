local M = {}
local highlights = require("tableview.highlights")

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

return M
