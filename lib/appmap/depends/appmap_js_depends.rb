require 'shellwords'
require 'appmap/depends/appmap_js'

module AppMap
  module Depends
    # +Command+ wraps the Node +depends+ command.
    class AppMapJSDepends
      include AppMapJS

      # Directory to scan for AppMaps.
      attr_accessor :appmap_dir
      # Directory name to prefix to the list of modified files which is provided to +depends+.
      attr_accessor :base_dir

      def initialize
        @appmap_dir = Depends::DEFAULT_APPMAP_DIR
        @base_dir = false
      end

      # Ensures that all dependencies are available.
      def validate
        detect_nodejs
        detect_appmap_js
      end

      # Returns the source_location field of every AppMap that is "out of date" with respect to one of the
      # +modified_files+.
      def depends(modified_files = nil)
        validate

        index_appmaps(appmap_dir)

        cmd = %w[depends --field source_location]
        cmd += [ '--appmap-dir', appmap_dir ] if appmap_dir
        cmd += [ '--base-dir', base_dir ] if base_dir

        options = {}
        if modified_files
          cmd << '--stdin-files'
          options[:stdin_data] = modified_files.map(&:shellescape).join("\n")
          warn "Checking modified files: #{modified_files.join(' ')}" if Depends.verbose
        end

        stdout, = appmap_js_command cmd, options
        stdout.split("\n")
      end
    end
  end
end
