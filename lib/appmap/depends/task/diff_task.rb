# frozen_string_literal: true

module AppMap
  module Depends
    module Task
      class DiffTask < BaseTask
        DEFAULT_BASE_BRANCHES = %w[remotes/origin/main remotes/origin/master]

        attr_accessor :base, :head, :base_branches, :modified_files, :verbose

        def initialize(*args)
          super args.shift || :'depends:diff'

          @verbose = false
          @modified_files = nil
          @base = nil
          @head = nil
          @base_branches = DEFAULT_BASE_BRANCHES
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
            warn 'Out of date files:'
            puts depends.depends(modified_files).join("\n")
          end          
        end
      end
    end
  end
end

