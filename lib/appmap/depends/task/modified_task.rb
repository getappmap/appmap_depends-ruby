# frozen_string_literal: true

module AppMap
  module Depends
    module Task
      class ModifiedTask < BaseTask
        DEFAULT_OUTPUT_FILE = File.join('tmp', 'appmap_depends_modified.txt')

        attr_accessor :base_dir

        def initialize(*args)
          super args.shift || :'depends:modified'

          @appmap_dir = Depends::DEFAULT_APPMAP_DIR
          @base_dir = nil
          @output_file = DEFAULT_OUTPUT_FILE
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
            test_files = depends.depends
            test_files = prune_directory_prefix(test_files)
            File.write(@output_file, test_files.join("\n"))
            if test_files.blank?
              warn 'Tests are up to date'
            else
              warn 'Out of date files:'
              warn test_files.join(' ')
            end
          end          
        end
      end
    end
  end
end
