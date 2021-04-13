require 'appmap/depends/version'

module AppMap
  module Depends
    DEFAULT_APPMAP_DIR = 'tmp/appmap'

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

def guard_defined?
  require 'guard'
  true
rescue LoadError
  false
end

require 'appmap/depends/command_error'
require 'appmap/depends/git_diff'
require 'appmap/depends/appmap_js_depends'

if rake_defined?
  require 'appmap/depends/task/base_task'
  require 'appmap/depends/task/diff_task'
  require 'appmap/depends/task/modified_task'
end

if guard_defined?
  require 'guard/app_map_depends'
end
