local M = {}

local function escape_sql(s)
	return s:gsub("'", "''")
end

local format_queries = {
	csv = function(path, limit)
		return string.format("SELECT * FROM read_csv('%s') LIMIT %d", escape_sql(path), limit)
	end,
	tsv = function(path, limit)
		return string.format("SELECT * FROM read_csv('%s', delim='\\t') LIMIT %d", escape_sql(path), limit)
	end,
	parquet = function(path, limit)
		return string.format("SELECT * FROM '%s' LIMIT %d", escape_sql(path), limit)
	end,
	json = function(path, limit)
		return string.format("SELECT * FROM read_json('%s') LIMIT %d", escape_sql(path), limit)
	end,
	jsonl = function(path, limit)
		return string.format("SELECT * FROM read_json('%s') LIMIT %d", escape_sql(path), limit)
	end,
	xlsx = function(path, limit)
		return string.format("SELECT * FROM '%s' LIMIT %d", escape_sql(path), limit)
	end,
	arrow = function(path, limit)
		return string.format("SELECT * FROM '%s' LIMIT %d", escape_sql(path), limit)
	end,
	feather = function(path, limit)
		return string.format("SELECT * FROM '%s' LIMIT %d", escape_sql(path), limit)
	end,
}

function M.supports(ext)
	return format_queries[ext] ~= nil
end

function M.read(filepath, ext, callback)
	local config = require("tableview.config").options

	if vim.fn.executable(config.duckdb_path) == 0 then
		callback(nil, "DuckDB not found. Install it: https://duckdb.org/install")
		return
	end

	local query_fn = format_queries[ext]
	if not query_fn then
		callback(nil, "Unsupported format: " .. ext)
		return
	end

	local query = query_fn(filepath, config.max_rows)

	vim.system({ config.duckdb_path, "-json", "-c", query }, { text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				callback(nil, result.stderr or "DuckDB error")
				return
			end
			callback(result.stdout, nil)
		end)
	end)
end

return M
