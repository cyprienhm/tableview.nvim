vim.api.nvim_create_user_command("TableViewOpen", function(opts)
	require("tableview").open(opts.args)
end, { nargs = 1, complete = "file", desc = "Open file in TableView" })
