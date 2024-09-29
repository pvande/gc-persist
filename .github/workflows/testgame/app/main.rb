$gtk.ffi_misc.gtk_dlopen("gc-escape")

$before = {}
$after = {}
$allocated = nil
$retain = []

def self.experiment(&block)
  $allocated = nil

  # Flush the GC arena and take count.
  ObjectSpace.count_objects($before)

  # Run the experiment.
  $allocated = yield

  # Flush the GC arena.
  # This writes an identifiable value to every free slot in the arena; if data
  # from the arena is still referenced by the experiment, this will make
  # identification easier.
  ObjectSpace.count_objects($after)
  GC.disable
  idx, target = 0, $after[:FREE]
  while idx < target
    $retain[idx] = -9000.0
    idx += 1
  end
  GC.enable
  $retain.clear

  # Flush the GC arena and count again.
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
  require "app/range_test.rb"
  require "app/hash_test.rb"
rescue Exception => e
  __puts__ e.message
  __puts__ *e.backtrace
  exit 2
end

$gtk.write_file('success', 'success')
exit 0
