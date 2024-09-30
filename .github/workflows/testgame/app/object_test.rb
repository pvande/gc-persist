__puts__ "Testing Objects"

class MyClass
  def initialize(x, y, z)
    @a, @b, @c = x, y, z
  end

  def sum
    @a + @b + @c
  end
end

assert_equal(true, ESCAPE(MyClass.new(1, 2, 3)).frozen?, "Objects are not frozen")

assert_equal(6, ESCAPE(MyClass.new(1, 2, 3)).sum, "Escaped objects are broken")

# Verifying Object with Integer ivar Behavior
before, after, list = experiment { 100.times.map { |i| MyClass.new(2, 3, 4) } }
assert_equal(before[:T_OBJECT].to_i + 100, after[:T_OBJECT], "Objects are not tracked by the GC")

# Testing Object with Integer ivar Escape
before, after, list = experiment { 100.times.map { |i| ESCAPE(MyClass.new(2, 3, 4)) } }
assert_equal(before[:T_OBJECT], after[:T_OBJECT], "Escaped objects are being tracked by the GC")
assert_equal(9, list.last.sum, "Escaped objects are broken")

# Verifying Object with Float ivar Behavior
before, after, list = experiment { 100.times.map { |i| MyClass.new(2.0, 3.0, 4.0) } }
assert_equal(before[:T_OBJECT].to_i + 100, after[:T_OBJECT], "Objects are not tracked by the GC")
assert_equal(before[:T_FLOAT].to_i + 300, after[:T_FLOAT], "Object ivars are not tracked by the GC")

# Testing Object with Float ivar Escape
before, after, list = experiment { 100.times.map { |i| ESCAPE(MyClass.new(2.0, 3.0, 4.0)) } }
assert_equal(before[:T_OBJECT], after[:T_OBJECT], "Escaped objects are being tracked by the GC")
assert_equal(before[:T_FLOAT], after[:T_FLOAT], "Escaped object ivars are being tracked by the GC")
assert_equal(9.0, list.last.sum, "Escaped objects are broken")

# Verifying Object with String ivar Behavior
before, after, list = experiment { 100.times.map { |i| MyClass.new("a", "b", "c") } }
assert_equal(before[:T_OBJECT].to_i + 100, after[:T_OBJECT], "Objects are not tracked by the GC")
assert_equal(before[:T_STRING].to_i + 300, after[:T_STRING], "Object ivars are not tracked by the GC")

# Testing Object with String ivar Escape
before, after, list = experiment { 100.times.map { |i| ESCAPE(MyClass.new("a", "b", "c")) } }
assert_equal(before[:T_OBJECT], after[:T_OBJECT], "Escaped objects are being tracked by the GC")
assert_equal(before[:T_STRING], after[:T_STRING], "Escaped object ivars are being tracked by the GC")
assert_equal("abc", list.last.sum, "Escaped objects are broken")

# Verifying Object with Array ivar Behavior
before, after, list = experiment { 100.times.map { |i| MyClass.new([:a], [:b], [:c]) } }
assert_equal(before[:T_OBJECT].to_i + 100, after[:T_OBJECT], "Objects are not tracked by the GC")
assert_equal(before[:T_ARRAY].to_i + 301, after[:T_ARRAY], "Object ivars are not tracked by the GC")

# Testing Object with Array ivar Escape
before, after, list = experiment { 100.times.map { |i| ESCAPE(MyClass.new([:a], [:b], [:c])) } }
assert_equal(before[:T_OBJECT], after[:T_OBJECT], "Escaped objects are being tracked by the GC")
assert_equal(before[:T_ARRAY] + 1, after[:T_ARRAY], "Escaped object ivars are being tracked by the GC")
assert_equal([:a, :b, :c], list.last.sum, "Escaped objects are broken")
