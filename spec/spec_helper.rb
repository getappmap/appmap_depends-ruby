$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require 'appmap_depends'
require 'rspec'

TEST_DIR = 'spec/fixtures'
BASE_DIR = TEST_DIR

def update_appmap_index
  system 'node ./node_modules/@appland/cli/src/cli.js index --appmap-dir spec/fixtures' \
    or raise "Failed to update AppMap index"
end

RSpec.configure do |rspec|
  AppMap::Depends.verbose(true) if ENV['DEBUG']

  rspec.before do
    Dir.glob('spec/fixtures/*.appmap.json').each { |fname| FileUtils.touch fname }
    update_appmap_index

    FileUtils.rm_rf 'spec/tmp'
    FileUtils.mkdir_p 'spec/tmp'
  end
end
