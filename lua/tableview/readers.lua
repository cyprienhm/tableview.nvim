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
lines.append(header_line)

col_pos = 1
for col_name, width in maxpercol.items():
    highlights.append({
        "line": len(lines) - 1,
        "col_start": col_pos,
        "col_end": col_pos + width + 2,
        "type": "header"
    })
    col_pos += width + 3

lines.append(border_line)

for i, row in df.iterrows():
    row_line = "|"
    line_highlights = []
    col_pos = 1

    for col in df.columns:
        width = maxpercol[col]
        elt = row[col]
        is_null = elt is None or str(elt) == 'nan'

        if is_null:
            elt = "nan"
            cell_type = "null"
        else:
            col_dtype = str(display_table.schema.field(col).type)
            if any(t in col_dtype.lower() for t in ['int', 'float', 'double', 'decimal']):
                cell_type = "number"
            elif 'bool' in col_dtype.lower():
                cell_type = "boolean"
            else:
                cell_type = "string"

        cell_str = f" {str(elt): ^{width}} "
        row_line += cell_str + "|"

        line_highlights.append({
            "line": len(lines),
            "col_start": col_pos,
            "col_end": col_pos + width + 2,
            "type": cell_type
        })
        col_pos += width + 3

    lines.append(row_line)
    highlights.extend(line_highlights)

lines.append(border_line)

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
lines.append(header_line)

col_pos = 1
for col_name, width in maxpercol.items():
    highlights.append({
        "line": len(lines) - 1,
        "col_start": col_pos,
        "col_end": col_pos + width + 2,
        "type": "header"
    })
    col_pos += width + 3

lines.append(border_line)

for i, row in df.iterrows():
    row_line = "|"
    line_highlights = []
    col_pos = 1

    for col in df.columns:
        width = maxpercol[col]
        elt = row[col]
        is_null = pd.isna(elt)

        if is_null:
            elt = "nan"
            cell_type = "null"
        else:
            dtype = str(df[col].dtype)
            if dtype.startswith(('int', 'float', 'uint', 'complex')):
                cell_type = "number"
            elif dtype == 'bool':
                cell_type = "boolean"
            else:
                cell_type = "string"

        cell_str = f" {str(elt): ^{width}} "
        row_line += cell_str + "|"

        line_highlights.append({
            "line": len(lines),
            "col_start": col_pos,
            "col_end": col_pos + width + 2,
            "type": cell_type
        })
        col_pos += width + 3

    lines.append(row_line)
    highlights.extend(line_highlights)

lines.append(border_line)

result = {"lines": lines, "highlights": highlights}
print(json.dumps(result))
]],
		filename,
		delimiter
	)

	return execute_python_formatting(python_code)
end

return M
