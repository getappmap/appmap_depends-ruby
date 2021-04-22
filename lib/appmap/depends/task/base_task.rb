# frozen_string_literal: true

require 'rake/tasklib'

module AppMap
  module Depends
    module Task
      class BaseTask < ::Rake::TaskLib
        attr_accessor :name, :appmap_dir, :base, :output_file

        def initialize(name)
          @name = name
          @appmap_dir = Depends::DEFAULT_APPMAP_DIR
        end

        def prune_directory_prefix(files)
          pwd = Dir.pwd
          files.map do |file|
            if file.index(pwd) == 0
              file[pwd.length + 1..-1]
            else
              file
            end
          end
        end

        # This bit of black magic - https://github.com/rspec/rspec-core/blob/main/lib/rspec/core/rake_task.rb#L110
        def define(args = [], &task_block)
          desc description unless ::Rake.application.last_description
          task(name, *args) do |_, task_args|
            Depends.verbose(Rake.verbose == true)
            RakeFileUtils.__send__(:verbose, Rake.verbose == true) do
              task_block.call(*[self, task_args].slice(0, task_block.arity)) if task_block
              define_command(task_args).call
            end
          end
        end
      end
    end
  end
end
