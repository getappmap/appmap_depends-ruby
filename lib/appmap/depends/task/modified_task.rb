# frozen_string_literal: true

module AppMap
  module Depends
    module Task
      class ModifiedTask < BaseTask
        attr_accessor :appmap_dir, :base_dir

        def initialize(*args)
          super args.shift || :'depends:modified'

          @appmap_dir = Depends::DEFAULT_APPMAP_DIR
          @base_dir = nil
        end

        def description
          'Prints the file names of all test cases that depend on a file which is newer than the AppMap'
        end

        def define_command(task_args)
          appmap_dir = task_args[:appmap_dir] || @appmap_dir
          base_dir = task_args[:base_dir] || @base_dir

          depends = AppMap::Depends::AppMapJSDepends.new
          depends.appmap_dir = appmap_dir
          depends.base_dir = base_dir if base_dir
          lambda do
            warn 'Out of date files:'
            puts depends.depends.join("\n")
          end          
        end
      end
    end
  end
end
