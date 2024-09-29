__puts__ "Testing Arrays"

assert_equal(true, ESCAPE([0, 1]).frozen?, "Arrays are not frozen")

assert_equal([0, 1], ESCAPE([0, 1]), "Escaped arrays are broken")
assert_equal((0..3).to_a.sum, ESCAPE((0..3).to_a).sum, "Escaped short arrays are broken")
assert_equal((0..100).to_a.sum, ESCAPE((0..100).to_a).sum, "Escaped long arrays are broken")

# Verifying Integer Array Behavior
before, after, list = experiment { 100.times.map { |i| [0, 1] } }
assert_equal(before[:T_ARRAY].to_i + 101, after[:T_ARRAY], "Arrays are not tracked by the GC")

# Testing Integer Array Escape
before, after, list = experiment { 100.times.map { |i| ESCAPE([0, 1]) } }
assert_equal(before[:T_ARRAY].to_i + 1, after[:T_ARRAY], "Escaped arrays are being tracked by the GC")

# Verifying Float Array Behavior
before, after, list = experiment { 100.times.map { |i| [0.0, 1.0, 2.0] } }
assert_equal(before[:T_ARRAY].to_i + 101, after[:T_ARRAY], "Arrays are not tracked by the GC")
assert_equal(before[:T_FLOAT].to_i + 300, after[:T_FLOAT], "Array values are not tracked by the GC")

# Testing Float Array Escape
before, after, list = experiment { 100.times.map { |i| ESCAPE([0.0, 1.0, 2.0]) } }
assert_equal(before[:T_ARRAY].to_i + 1, after[:T_ARRAY], "Escaped arrays are being tracked by the GC")
assert_equal(before[:T_FLOAT], after[:T_FLOAT], "Escaped array values are being tracked by the GC")

# Verifying String Array Behavior
before, after, list = experiment { 100.times.map { |i| %w[a b c] } }
assert_equal(before[:T_ARRAY].to_i + 101, after[:T_ARRAY], "Arrays are not tracked by the GC")
assert_equal(before[:T_STRING].to_i + 300, after[:T_STRING], "Array values are not tracked by the GC")

# Testing String Array Escape
before, after, list = experiment { 100.times.map { |i| ESCAPE(%w[a b c]) } }
assert_equal(before[:T_ARRAY].to_i + 1, after[:T_ARRAY], "Escaped arrays are being tracked by the GC")
assert_equal(before[:T_STRING], after[:T_STRING], "Escaped array values are being tracked by the GC")

# Verifying Hash Array Behavior
before, after, list = experiment { 100.times.map { |i| [{ x: 1 }, { x: 2 }, { x: 3 }] } }
assert_equal(before[:T_ARRAY].to_i + 101, after[:T_ARRAY], "Arrays are not tracked by the GC")
assert_equal(before[:T_HASH].to_i + 300, after[:T_HASH], "Array values are not tracked by the GC")

# Testing Hash Array Escape
before, after, list = experiment { 100.times.map { |i| ESCAPE([{ x: 1 }, { x: 2 }, { x: 3 }]) } }
assert_equal(before[:T_ARRAY].to_i + 1, after[:T_ARRAY], "Escaped arrays are being tracked by the GC")
assert_equal(before[:T_HASH], after[:T_HASH], "Escaped array values are being tracked by the GC")

# Testing Symbol Array Escape
before, after, list = experiment { 100.times.map { |i| ESCAPE(%i[a b c]) } }
assert_equal(before[:T_ARRAY].to_i + 1, after[:T_ARRAY], "Escaped arrays are being tracked by the GC")

# Testing Long Array Escapes
before, after, list = experiment { ESCAPE(100.times.map { |i| i.to_f }) }
assert_equal(before[:T_ARRAY], after[:T_ARRAY], "Escaped arrays are being tracked by the GC")
assert_equal(before[:T_FLOAT], after[:T_FLOAT], "Escaped array values are being tracked by the GC")
