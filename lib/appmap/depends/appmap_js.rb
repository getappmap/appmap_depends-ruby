APPMAP_JS = './node_modules/@appland/appmap/src/cli.js'

require 'open3'
require 'active_support'
require 'active_support/core_ext'

module AppMap
  module Depends
    # Utilities for invoking the +@appland/appmap+ CLI.
    module AppMapJS
      APPMAP_JS = './node_modules/@appland/cli/src/cli.js'

      def detect_nodejs
        do_fail('node', 'please install NodeJS') unless system('node --version 2>&1 > /dev/null')
        true
      end

      def detect_appmap_js
        do_fail(APPMAP_JS, 'please install @appland/cli from NPM') unless File.exists?(APPMAP_JS)
        true
      end

      def index_appmaps(appmap_dir)
        appmap_js_command [ 'index', '--appmap-dir', appmap_dir ]
        true
      end

      def do_fail(command, msg)
        command = command.join(' ') if command.is_a?(Array)
        warn [ command, msg ].join('; ') if Depends.verbose
        raise CommandError.new(command, msg)
      end

      def appmap_js_command(command, options = {})
        command.unshift << '--verbose' if Depends.verbose
        command.unshift APPMAP_JS
        command.unshift 'node'

        warn command.join(' ') if Depends.verbose
        stdout, stderr, status = Open3.capture3({ 'NODE_OPTIONS' => '--trace-warnings' }, *command, options)
        stdout_msg = stdout.split("\n").map {|line| "stdout: #{line}"}.join("\n") unless stdout.blank?
        stderr_msg = stderr.split("\n").map {|line| "stderr: #{line}"}.join("\n") unless stderr.blank?
        if Depends.verbose
          warn stdout_msg if stdout_msg
          warn stderr_msg if stderr_msg
        end
        unless status.exitstatus == 0
          raise CommandError.new(command, [ stdout_msg, stderr_msg ].compact.join("\n"))
        end
        [ stdout, stderr ]
      end
    end
  end
end
