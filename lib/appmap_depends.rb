require 'appmap/depends/version'

module AppMap
  module Depends
    # Default directory to scan for appmap.s
    DEFAULT_APPMAP_DIR = File.join('tmp', 'appmap')
    # Default file to write Rake task results.
    DEFAULT_OUTPUT_FILE = File.join('tmp', 'appmap_depends.txt')
    # Default base branches which will be checked for existance.
    DEFAULT_BASE_BRANCHES = %w[remotes/origin/main remotes/origin/master].freeze
    # Default pattern to enumerate test cases.
    DEFAULT_TEST_FILE_PATTERNS = [ 'spec/**/*_spec.rb', 'test/**/*_test.rb' ].freeze

    def self.verbose(arg = nil)
      @verbose = arg if arg
      @verbose
    end
  end
end

def rake_defined?
  require 'rake'
  true
rescue LoadError
  false
end

require 'appmap/depends/util'
require 'appmap/depends/command_error'
require 'appmap/depends/git_diff'
require 'appmap/depends/appmap_js_depends'
require 'appmap/depends/test_file_inspector'
require 'appmap/depends/api'

if rake_defined?
  AppMap::Depends.verbose(Rake.verbose == true)
end
