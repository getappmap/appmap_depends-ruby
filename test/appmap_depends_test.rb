require "test_helper"

class AppmapDependsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::AppMap::Depends::VERSION
  end
end
