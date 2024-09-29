__puts__ "Testing Ranges"

assert_equal(true, ESCAPE(0..1).frozen?, "Ranges are not frozen")

assert_equal(0..1, ESCAPE(0..1), "Escaped ranges are broken")

# Verifying Integer Range Behavior
before, after, list = experiment { 100.times.map { |i| 0..1 } }
assert_equal(before[:T_RANGE].to_i + 100, after[:T_RANGE], "Ranges are not tracked by the GC")

# Testing Integer Range Escape
before, after, list = experiment { 100.times.map { |i| ESCAPE(0..1) } }
assert_equal(before[:T_RANGE], after[:T_RANGE], "Escaped ranges are being tracked by the GC")

# Verifying Float Range Behavior
before, after, list = experiment { 100.times.map { |i| (0.0)..(1.0) } }
assert_equal(before[:T_RANGE].to_i + 100, after[:T_RANGE], "Ranges are not tracked by the GC")
assert_equal(before[:T_FLOAT].to_i + 200, after[:T_FLOAT], "Range endpoints are not tracked by the GC")

# Testing Float Range Escape
before, after, list = experiment { 100.times.map { |i| ESCAPE((0.0)..(1.0)) } }
assert_equal(before[:T_RANGE], after[:T_RANGE], "Escaped ranges are being tracked by the GC")
assert_equal(before[:T_FLOAT], after[:T_FLOAT], "Escaped range endpoints are being tracked by the GC")

# Verifying String Range Behavior
before, after, list = experiment { 100.times.map { |i| "a".."z" } }
assert_equal(before[:T_RANGE].to_i + 100, after[:T_RANGE], "Ranges are not tracked by the GC")
assert_equal(before[:T_STRING].to_i + 200, after[:T_STRING], "Range endpoints are not tracked by the GC")

# Testing String Range Escape
before, after, list = experiment { 100.times.map { |i| ESCAPE("a".."z") } }
assert_equal(before[:T_RANGE], after[:T_RANGE], "Escaped ranges are being tracked by the GC")
assert_equal(before[:T_STRING], after[:T_STRING], "Escaped range endpoints are being tracked by the GC")
