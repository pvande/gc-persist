__puts__ "Testing Hashes"

assert_equal(true, ESCAPE({}).frozen?, "Hashes are not frozen")

assert_equal(3, ESCAPE(Hash.new(3))[:x], "Hashes aren't keeping default values")
assert_equal(3.0, ESCAPE(Hash.new(3.0))[:x], "Hashes aren't escaping default values")
# @TODO: ESCAPE(Proc)
# assert_equal(3.0, ESCAPE(Hash.new { 3.0 })[:x], "Hashes aren't keeping default value procs")

# Verifying Small Hash Behavior
before, after, list = experiment { 2048.times.map { |i| { x: i } } }
assert_equal(before[:T_HASH] + 2048, after[:T_HASH], "Hashes are not tracked by the GC")

# Testing Small Hash Escape
before, after, list = experiment { 2048.times.map { |i| ESCAPE(x: i) } }
assert_equal(before[:T_HASH], after[:T_HASH], "Escaped hashes are being tracked by the GC")
assert_equal([0, 1, 2, 3, 4], list.take(5).map { |hash| hash[:x] }, "Escaped hashes are broken")
assert_equal([0, 1, 2, 3, 4], list.take(5).map(&:x), "Escaped hashes are broken")
assert_equal(2048, list.map(&:size).sum, "Escaped hashes are broken")

# Testing Small Hash Escape with Escapable Keys
before, after, list = experiment { 2048.times.map { |i| ESCAPE({ i.to_f => i }) } }
assert_equal(before[:T_FLOAT], after[:T_FLOAT], "Escaped hash keys are being tracked by the GC")
assert_equal(2048.times.to_a.sum, list.flat_map(&:keys).sum, "Escaped hash keys are broken")

# Testing Small Hash Escape with Escapable Values
before, after, list = experiment { 2048.times.map { |i| ESCAPE({ i => i.to_f }) } }
assert_equal(before[:T_FLOAT], after[:T_FLOAT], "Escaped hash values are being tracked by the GC")
assert_equal(2048.times.to_a.sum, list.flat_map(&:values).sum, "Escaped hash values are broken")

# Testing Small Hash Escape
before, after, (original, a, b, c) = experiment do
  canonical = { x: 1 }
  [ canonical, ESCAPE(canonical), ESCAPE(canonical), ESCAPE(canonical) ]
end

assert_equal(before[:T_HASH] + 1, after[:T_HASH], "Escaped hash values are being tracked by the GC")

original[:x] = 10
assert_equal(1, a[:x], "Escaped hash still references the original hash")
assert_equal(1, b[:x], "Escaped hash still references the original hash")
assert_equal(1, c[:x], "Escaped hash still references the original hash")

assert_equal(a.object_id, b.object_id, "Escaped hashes aren't deduplicated")
assert_equal(a.object_id, c.object_id, "Escaped hashes aren't deduplicated")

# Testing Large Hash Escape
letters = ("a".."z")
sample = letters.take(5)
before, after, list = experiment do
  2048.times.map { |i| ESCAPE(letters.map(&:to_sym).each_with_index.to_h) }
end
assert_equal(before[:T_HASH], after[:T_HASH], "Escaped hashes are being tracked by the GC")
assert_equal([0, 1, 2, 3, 4], list[32].values_at(*sample.map(&:to_sym)), "Escaped hashes are broken")
assert_equal([0, 1, 2, 3, 4], sample.map { |x| list[32].send(x.to_sym) }, "Escaped hashes are broken")
assert_equal(2048 * letters.count, list.map(&:size).sum, "Escaped hashes are broken")

# Testing Large Hash Escape with Escapable Keys
before, after, list = experiment do
  2048.times.map { |i| ESCAPE(letters.map(&:to_sym).map.with_index { |k, v| [v.to_f, k] }.to_h) }
end
assert_equal(before[:T_FLOAT], after[:T_FLOAT], "Escaped hash keys are being tracked by the GC")
assert_equal(2048 * letters.count.times.to_a.sum, list.flat_map(&:keys).sum, "Escaped hash keys are broken")

# Testing Large Hash Escape with Escapable Values
before, after, list = experiment do
  2048.times.map { |i| ESCAPE(letters.map(&:to_sym).map.with_index { |k, v| [k, v.to_f] }.to_h) }
end
assert_equal(before[:T_FLOAT], after[:T_FLOAT], "Escaped hash values are being tracked by the GC")
assert_equal(2048 * letters.count.times.to_a.sum, list.flat_map(&:values).sum, "Escaped hash values are broken")

# Testing Large Hash Escape
before, after, (original, a, b, c) = experiment do
  canonical = letters.map(&:to_sym).each_with_index.to_h
  [ canonical, ESCAPE(canonical), ESCAPE(canonical), ESCAPE(canonical) ]
end

assert_equal(before[:T_HASH] + 1, after[:T_HASH], "Escaped hash values are being tracked by the GC")

original[:x] = 10
assert_equal(23, a[:x], "Escaped hash still references the original hash")
assert_equal(23, b[:x], "Escaped hash still references the original hash")
assert_equal(23, c[:x], "Escaped hash still references the original hash")

assert_equal(a.object_id, b.object_id, "Escaped hashes aren't deduplicated")
assert_equal(a.object_id, c.object_id, "Escaped hashes aren't deduplicated")

# Testing Defaulted Hash Escape
before, after, (original, a, b, c) = experiment do
  canonical = Hash.new({})
  [ canonical, ESCAPE(canonical), ESCAPE(canonical), ESCAPE(canonical) ]
end

assert_equal(before[:T_HASH] + 2, after[:T_HASH], "Escaped hash values are being tracked by the GC")

original[:x][:i] = 10
assert_equal({}, a[:x], "Escaped hash still references the original hash")
assert_equal({}, b[:x], "Escaped hash still references the original hash")
assert_equal({}, c[:x], "Escaped hash still references the original hash")

assert_equal(a.object_id, b.object_id, "Escaped hashes aren't deduplicated")
assert_equal(a.object_id, c.object_id, "Escaped hashes aren't deduplicated")
