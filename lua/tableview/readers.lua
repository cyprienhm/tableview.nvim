local M = {}

local function execute_python_formatting(python_code)
	local result = vim.system({ "python3", "-c", python_code }, {
		stdout_buffered = true,
		stderr_buffered = true,
	}):wait()

	if result.code == 0 then
		return result.stdout, nil
	end

	return result.stderr, "Python error when reading file"
end

function M.read_parquet(filename)
	local python_code = string.format(
		[[
import pyarrow.parquet as pq
import json

table = pq.read_table('%s')

lines = []
highlights = []

lines.append(f"Shape: ({table.num_rows}, {table.num_columns})")
lines.append("Columns:")
for i, col_name in enumerate(table.column_names):
    col_type = table.schema.field(i).type
    lines.append(f"  {col_name}: {col_type}")
lines.append("")

display_table = table.slice(0, min(100, table.num_rows))
df = display_table.to_pandas()

maxpercol = df.map(lambda x: len(str(x)) if x is not None else 3).max().to_dict()
maxpercol = {col_name: max(len(col_name), width) for col_name, width in maxpercol.items()}

border_line = "+" + "+".join(["-" * (width + 2) for width in maxpercol.values()]) + "+"
header_line = "|" + "|".join([f" {col_name: ^{width}} " for col_name, width in maxpercol.items()]) + "|"

lines.append(border_line)
highlights.append({"line": len(lines) - 1, "type": "border"})

lines.append(header_line)
highlights.append({"line": len(lines) - 1, "type": "header"})

lines.append(border_line)
highlights.append({"line": len(lines) - 1, "type": "border"})

for i, row in df.iterrows():
    row_line = "|"
    for col in df.columns:
        width = maxpercol[col]
        elt = row[col]
        if elt is None or str(elt) == 'nan':
            elt = "nan"
        row_line += f" {str(elt): ^{width}} |"
    lines.append(row_line)

lines.append(border_line)
highlights.append({"line": len(lines) - 1, "type": "border"})

result = {"lines": lines, "highlights": highlights}
print(json.dumps(result))
]],
		filename
	)

	return execute_python_formatting(python_code)
end

function M.read_csv(filename, delimiter)
	if not delimiter then
		delimiter = "None"
	else
		delimiter = '"' .. delimiter .. '"'
	end

	local python_code = string.format(
		[[
import pandas as pd
import json

df = pd.read_csv('%s', sep=%s, nrows=100)

lines = []
highlights = []

lines.append(f"Shape: ({len(df)}, {len(df.columns)})")
lines.append("Columns:")
for col in df.columns:
    lines.append(f"  {col}: {df[col].dtype}")
lines.append("")

maxpercol = df.map(lambda x: len(str(x)) if x is not None else 3).max().to_dict()
maxpercol = {col_name: max(len(col_name), width) for col_name, width in maxpercol.items()}

border_line = "+" + "+".join(["-" * (width + 2) for width in maxpercol.values()]) + "+"
header_line = "|" + "|".join([f" {col_name: ^{width}} " for col_name, width in maxpercol.items()]) + "|"

lines.append(border_line)
highlights.append({"line": len(lines) - 1, "type": "border"})

lines.append(header_line)
highlights.append({"line": len(lines) - 1, "type": "header"})

lines.append(border_line)
highlights.append({"line": len(lines) - 1, "type": "border"})

for i, row in df.iterrows():
    row_line = "|"
    for col in df.columns:
        width = maxpercol[col]
        elt = row[col]
        if pd.isna(elt):
            elt = "nan"
        row_line += f" {str(elt): ^{width}} |"
    lines.append(row_line)

lines.append(border_line)
highlights.append({"line": len(lines) - 1, "type": "border"})

result = {"lines": lines, "highlights": highlights}
print(json.dumps(result))
]],
		filename,
		delimiter
	)

	return execute_python_formatting(python_code)
end

return M
