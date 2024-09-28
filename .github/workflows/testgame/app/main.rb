$gtk.ffi_misc.gtk_dlopen("gc-escape")

$before = {}
$after = {}
$allocated = nil

def self.experiment(&block)
  $allocated = nil
  GC.start
  ObjectSpace.count_objects($before)

  $allocated = yield

  GC.start
  ObjectSpace.count_objects($after)

  return $before, $after, $allocated
rescue Exception => e
  __puts__ e.message
  __puts__ "Backtrace:", *e.backtrace
  exit 1
end

def self.assert_equal(expected, actual, msg)
  return if expected == actual
  raise "#{msg}: expected #{expected.inspect}, got #{actual.inspect}"
end

begin
  assert_equal(true, GC.respond_to?(:escape), "Library failed to load")

  require "app/float_test.rb"
  require "app/string_test.rb"
  require "app/hash_test.rb"
rescue Exception => e
  __puts__ e.message
  __puts__ *e.backtrace
  exit 2
end

$gtk.write_file('success', 'success')
exit 0
