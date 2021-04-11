# frozen_string_literal: true

require 'rake'
require 'rake/tasklib'

module AppMap
  module Depends
    APPMAP_JS = './node_modules/@appland/appmap/src/cli.js'

    module SystemCommand
      def detect_nodejs
        do_fail(%Q('node' not found; please install NodeJS)) unless system('node --version 2>&1 > /dev/null')
      end

      def detect_appmap_js
        do_fail(%Q('#{APPMAP_JS}' not found; please install @appland/appmap from NPM)) unless File.exists?(APPMAP_JS)
      end

      def index_appmaps
        system_cmd %Q(env NODE_OPTIONS="--trace-warnings" #{APPMAP_JS} #{debug ? '--verbose' : ''} index --appmap-dir #{appmap_dir})
      end

      def run_depends_command(cmd)
        warn cmd if verbose
        warn "Out of date tests:"
        system_cmd cmd
      end

      def do_fail(msg)
        warn msg if verbose
        exit $?.exitstatus || 1
      end

      def system_cmd(cmd)
        warn cmd if verbose
        raise "Command failed: #{cmd}" \
          unless system cmd
      end
    end

    class BaseTask < ::Rake::TaskLib
      attr_accessor :name, :appmap_dir, :base

      def initialize(name)
        @name = name
        @appmap_dir = Depends::DEFAULT_APPMAP_DIR
      end

      # Override to validate the task configuration.
      def validate
        true
      end

      # This bit of black magic - https://github.com/rspec/rspec-core/blob/main/lib/rspec/core/rake_task.rb#L110
      def define(args = [], &task_block)
        validate

        desc description unless ::Rake.application.last_description

        task(name, *args) do |_, task_args|
          RakeFileUtils.__send__(:verbose, Rake.verbose == true) do
            task_block.call(*[self, task_args].slice(0, task_block.arity)) if task_block
            define_command(task_args).run_task
          end
        end
      end
    end
  end
end
