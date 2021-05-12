# frozen_string_literal: true

module AppMap
  module Depends
    module Task
      class DiffTask < BaseTask
        DEFAULT_OUTPUT_FILE = File.join('tmp', 'appmap_depends_diff.txt')
        DEFAULT_BASE_BRANCHES = %w[remotes/origin/main remotes/origin/master]

        attr_accessor :base, :head, :base_branches, :modified_files, :verbose

        def initialize(*args)
          super args.shift || :'depends:diff'

          @verbose = false
          @modified_files = nil
          @base = nil
          @head = nil
          @base_branches = DEFAULT_BASE_BRANCHES
          @output_file = DEFAULT_OUTPUT_FILE
        end

        def description
          'Prints the file names of all test cases that depend on a file which is modified from the base branch'
        end

        def define_command(task_args = {})
          base = task_args[:base] || @base
          head = task_args[:head]
          
          diff = AppMap::Depends::GitDiff.new(base_branches: @base_branches, base: base, head: head)
          modified_files = diff.modified_files

          appmap_dir = task_args[:appmap_dir] || @appmap_dir
          base_dir = task_args[:base_dir] || @base_dir

          depends = AppMap::Depends::AppMapJSDepends.new
          depends.appmap_dir = appmap_dir
          depends.base_dir = base_dir if base_dir

          lambda do
            test_files = depends.depends(modified_files)
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

