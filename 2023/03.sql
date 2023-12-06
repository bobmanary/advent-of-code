/*
run with something like:

docker run --rm --name pg_aoc202303 \
  -v $(pwd)/inputs/03.txt:/tmp/03.txt \
  -v $(pwd)/03.sql:/tmp/03.sql \
  -e POSTGRES_PASSWORD=password postgres:16-alpine
docker exec -it pg_aoc202303 psql -U postgres -f /tmp/03.sql
docker stop pg_aoc202303
*/

DROP TABLE IF EXISTS raw_data, numbers, symbols;


CREATE TABLE raw_data(
  id integer generated always as identity,
  input_source character(4),
  line text
);

CREATE TABLE numbers (
  id integer generated always as identity,
  input_source character(4),
  x integer,
  y integer,
  number integer
);

CREATE TABLE symbols (
  id integer generated always as identity,
  input_source character(4),
  x integer,
  y integer,
  symbol character(1)
);


WITH test_string AS (
SELECT REGEXP_SPLIT_TO_TABLE(
'467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598..',
E'\\s+') AS line
)
INSERT INTO raw_data(input_source, line)
SELECT 'test', line
FROM test_string;


COPY raw_data (line) FROM '/tmp/03.txt';
UPDATE raw_data SET input_source = 'real' WHERE input_source IS NULL;



WITH rows_with_y_coords AS (
  SELECT
    input_source,
    id AS y,
    STRING_TO_TABLE(line, NULL) AS symbol
  FROM raw_data
),
rows_with_xy_coords AS (
  SELECT
    input_source,
    y,
    ROW_NUMBER() OVER (PARTITION BY y ORDER BY y) AS x,
    symbol
  FROM rows_with_y_coords
),
inserted_symbols AS (
  INSERT INTO symbols (x, y, input_source, symbol)
  SELECT x, y, input_source, symbol
  FROM rows_with_xy_coords
  WHERE
    NOT pg_input_is_valid(symbol, 'integer')
    AND symbol != '.'
  RETURNING x AS symbol_x, y AS symbol_y, input_source AS symbol_input_source
)
INSERT INTO numbers (x, y, input_source, number)
SELECT x, y, input_source, symbol::integer
FROM rows_with_xy_coords
WHERE pg_input_is_valid(symbol, 'integer');




WITH offsets AS (
  -- list grid coordinates surrounding 0,0
  SELECT * FROM JSON_TO_RECORDSET('[
    {"x": -1, "y": -1}, {"x": -1, "y": 0}, {"x": -1, "y": 1},
    {"x": 0, "y": -1},                     {"x": 0, "y": 1},
    {"x": 1, "y": -1},  {"x": 1, "y": 0},  {"x": 1, "y": 1}
  ]') AS unpacked (x integer, y integer)
),
adjacent_potential_cells AS (
  -- add number grid coordinates to offsets from 0,0 to get all coordinates
  -- around each number
  SELECT
    n.input_source,
    n.number,
    n.x AS nx,
    n.y AS ny,
    ARRAY[n.x + o.x, n.y + o.y] AS adjacent_xy
  FROM numbers n
  JOIN offsets o ON (1=1)
),
adjacent_symbols AS (
  SELECT * FROM symbols s
  WHERE ARRAY[s.x, s.y] IN (SELECT adjacent_xy FROM adjacent_potential_cells)
),
numbers_touching_symbols AS (
  -- get a list of all individual digits that are adjacent to a symbol
  SELECT ac.*, s.symbol, s.x AS sx, s.y AS sy
  FROM adjacent_potential_cells ac
  INNER JOIN symbols s
    ON ARRAY[s.x, s.y] = ac.adjacent_xy AND s.input_source = ac.input_source
  ORDER BY ny, nx
),

-- the next 3 queries solve the sql "gaps and islands" problem - group each
-- sequential series of rows (by x coordinate) into a single row to get the
-- complete number
islands AS (
  SELECT
    id,
    input_source,
    y,
    x,
    number,
    -- lag(x) looks at the previous row's value of x to see if current - previous == 1
    CASE x - LAG(x) OVER (PARTITION BY input_source, y ORDER BY x ASC)
      WHEN NULL THEN 1
      WHEN 1 THEN 0
      ELSE 1
    END AS island_start
  from numbers
),
island_ids AS (
  SELECT
    *,
    SUM(islands.island_start) OVER (ORDER BY islands.id ASC) AS island_id
  FROM islands
),
complete_numbers AS (
  SELECT
  input_source,
  y,
  min(x) AS starting_x,
  ARRAY_AGG(x) AS x_coords,
  STRING_AGG(island_ids.number::char, '')::INTEGER AS combined_number
FROM island_ids
GROUP BY island_id, y, input_source
ORDER BY input_source, y, island_id
),
part1_numbers AS (
  SELECT DISTINCT cn.*
  FROM complete_numbers cn
  INNER JOIN numbers_touching_symbols nts
    ON cn.input_source = nts.input_source
    AND cn.y = nts.ny
    AND nts.nx = ANY(cn.x_coords)
  ORDER BY cn.input_source, cn.y, starting_x
),
part1_sums AS (
  SELECT input_source, SUM(combined_number) AS sums
  FROM part1_numbers
  GROUP BY input_source
),
part2_numbers AS (
  SELECT DISTINCT ON (cn.input_source, cn.y, cn.starting_x)
    cn.input_source,
    sy,
    sx,
    combined_number
  FROM complete_numbers cn
  INNER JOIN numbers_touching_symbols nts
    ON cn.input_source = nts.input_source
    AND cn.y = nts.ny
    AND nts.nx = ANY(cn.x_coords)
    AND nts.symbol = '*'
),
part2_ratios AS (
  SELECT input_source, MIN(combined_number) * MAX(combined_number) AS gear_ratio
  FROM part2_numbers 
  GROUP BY input_source, sy, sx
  HAVING COUNT(1) = 2
),
part2_sums AS (
  SELECT input_source, SUM(gear_ratio) AS sums
  FROM part2_ratios
  GROUP BY input_source
)
SELECT
  p1.input_source,
  p1.sums AS part1,
  p2.sums AS part2
FROM part1_sums p1
LEFT JOIN part2_sums p2 ON p1.input_source = p2.input_source
;
