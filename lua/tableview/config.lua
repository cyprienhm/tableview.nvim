local M = {}

M.defaults = {
	max_rows = 100,
	column_width_cap = 50,
	duckdb_path = "duckdb",
	auto_open = { "parquet", "arrow", "feather", "xlsx" },
	highlights = {
		TableViewHeader = { default = true, link = "Title" },
		TableViewBorder = { default = true, link = "Comment" },
		TableViewNumber = { default = true, link = "Number" },
		TableViewString = { default = true, link = "String" },
		TableViewNull = { default = true, link = "Comment" },
		TableViewBoolean = { default = true, link = "Boolean" },
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
