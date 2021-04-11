# frozen_string_literal: true

require 'rake'
require 'rake/tasklib'
require 'appmap/depends/base_task'

module AppMap
  module Depends
    class ModifiedTask < BaseTask
      Command = Struct.new(:verbose, :appmap_dir, :base_dir) do
        include SystemCommand
        
        def run_task
          detect_nodejs
          detect_appmap_js
          index_appmaps

          cmd = [ %Q(env NODE_OPTIONS="--trace-warnings" #{APPMAP_JS} #{debug ? '--verbose' : ''} depends --field source_location) ]
          cmd << "--base-dir #{base_dir}" if base_dir
          system_cmd cmd.join(' ')
        end
      end

      attr_accessor :base_dir

      def initialize(*args)
        super args.shift || :'depends'

        @base_dir = nil
      end

      def description
        'Prints the file names of all test cases that depend on a file which is newer than the AppMap'
      end

      def define_command(task_args)
        Command.new(Rake.verbose == true, appmap_dir).tap do |cmd|
          cmd.base_dir = base_dir if base_dir
        end
      end
    end
  end
end
