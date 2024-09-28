__puts__ "Testing Strings"

assert_equal(true, ESCAPE("").frozen?, "Strings are not frozen")

assert_equal("a", ESCAPE("a"), "Escaped short strings are broken")
assert_equal("a" * 48, ESCAPE("a" * 48), "Escaped long strings are broken")

# Verifying Short String Behavior
before, after, list = experiment { 100.times.map { |i| i.to_s } }
assert_equal(before[:T_STRING] + 100, after[:T_STRING], "Strings are not tracked by the GC")

# Testing Short String Escape
before, after, list = experiment { 100.times.map { |i| ESCAPE(i.to_s) } }
assert_equal(before[:T_STRING], after[:T_STRING], "Escaped strings are being tracked by the GC")
assert_equal(%w[0 1 2 3 4], list.take(5), "Escaped strings are broken")
assert_equal("01234", list.take(5).reduce(:+), "Escaped strings are broken")

# Testing Long Escaped String Literal Slicing
_, _, escaped = experiment { ESCAPE("lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor") }
assert_equal("ipsum", escaped[6, 5], "Escaped strings are broken")

# Testing Long Escaped String Copy Slicing
original = "lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod"
escaped = ESCAPE(original)

GC.start
assert_equal("ipsum", escaped[6, 5], "Escaped strings are broken")

original = nil
GC.start
assert_equal("ipsum", escaped[6, 5], "Escaped strings are broken")

# Stress Test: Short Strings
"abcdefghijklmnopqrstuvwxyz".each_char do |a|
  "abcdefghijklmnopqrstuvwxyz".each_char do |b|
    ESCAPE(a + b)
  end
end

# Stress Test: Long Strings
"abcdefghijklmnopqrstuvwxyz".each_char do |a|
  "abcdefghijklmnopqrstuvwxyz".each_char do |b|
    ESCAPE((a * 16) + (b * 16))
  end
end
