__puts__ "Testing Floats"

# Verifying Float Behavior
before, after, list = experiment { 100.times.map { |i| i.to_f } }
assert_equal(before[:T_FLOAT].to_i + 100, after[:T_FLOAT], "Floats are not tracked by the GC")

expected_sum = list.sum

# Testing Float Escape
before, after, list = experiment { 100.times.map { |i| ESCAPE(i.to_f) } }
assert_equal(before[:T_FLOAT], after[:T_FLOAT], "Escaped floats are being tracked by the GC")
assert_equal([0.0, 1.0, 2.0, 3.0, 4.0], list.take(5), "Escaped floats are broken")
assert_equal(expected_sum, list.sum, "Escaped floats are broken")
