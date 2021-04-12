# frozen_string_literal: true

require 'rake'
require 'rake/tasklib'
require 'appmap/depends/base_task'

module AppMap
  module Depends
    class DiffTask < BaseTask
      DEFAULT_BASE_BRANCHES = %w[remotes/origin/main remotes/origin/master]

      Command = Struct.new(:verbose, :appmap_dir, :base, :head) do
        include SystemCommand

        def run
          cmd = prepare
          `#{cmd}`.split("\n")
        end

        def run_task
          cmd = prepare
          warn "Out of date tests:"
          system_cmd cmd
        end

        def prepare
          detect_nodejs
          detect_appmap_js
          index_appmaps

          warn "Using base #{base.inspect}" if verbose
          warn "Using head #{head.inspect}" if head && verbose

          branches = [ head, base ].compact
          diff_cmd = "git diff --name-only #{branches.join('..')}"

          if verbose
            warn "Files modified #{head ? 'in ' + head : 'locally'} compared to #{base}:"
            warn `#{diff_cmd}`
            warn ""
          end
          %(#{diff_cmd} | env NODE_OPTIONS="--trace-warnings" #{APPMAP_JS} #{debug ? '--verbose' : ''} depends --field source_location --stdin-files).tap do |cmd|
            warn cmd if verbose
          end
        end
      end

      attr_accessor :base, :base_branches

      def initialize(*args)
        super args.shift || :'depends:diff'

        @base = nil
        @base_branches = DEFAULT_BASE_BRANCHES
      end

      def files
        validate
        define_command.run
      end

      def validate
        git_exists = -> { system('git --version 2>&1 > /dev/null') }
        detect_branch = ->(branch) { `git branch -a`.split("\n").map(&:strip).member?(branch) }
        detect_base = lambda do
          return nil unless git_exists.()

          @base_branches.find(&detect_branch)
        end
        @base ||= detect_base.()
        raise "Unable to detect base branch. Specify it explicitly as a task argument." unless @base
      end

      def description
        'Prints the file names of all test cases that depend on a file which is modified from the base branch'
      end

      def define_command(task_args = {})
        Command.new(Rake.verbose == true, appmap_dir).tap do |cmd|
          cmd.base = task_args[:base] || @base
          cmd.head = task_args[:head]
        end
      end
    end
  end
end

