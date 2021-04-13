require 'guard'
require 'guard/compat/plugin'

module ::Guard
  class AppMapDepends < Plugin
    DEFAULT_DELAY = 5

    def initialize(options)
      super

      @options = options
      @path_lock = Mutex.new
      @paths = Set.new
    end

    def delay
      options[:delay] || DEFAULT_DELAY
    end

    def start
      @run_thread = start_thread
    end

    def stop
      @run_thread.kill if @run_thread
      @run_thread = nil
    end

    def run_on_modifications(paths)
      compute_diff(paths)
    end
    def run_on_additions(paths)
      compute_diff(paths)
    end
    def run_on_removals(paths)
      compute_diff(paths)
    end

    # Touch all test files that depend on 'paths'
    def compute_diff(paths)
      @paths += paths
    end

    def process_paths(paths)
      Compat::UI.info "Guard::AppMapDepends received paths: #{paths.join(' ')}"

      require 'appmap_depends'
      depends = AppMap::Depends::AppMapJSDepends.new
      files = depends.depends(paths)
      files.each do |file|
        FileUtils.touch file, nocreate: true
      end
    end

    def start_thread
      Thread.new do
        while true
          paths = nil
          @path_lock.synchronize do
            paths = @paths.to_a
            @paths = Set.new
          end

          unless paths.empty?
            Compat::UI.info "Guard::AppMapDepends processing: #{paths.join(' ')}"
            process_paths(paths)
          end

          Compat::UI.debug "Guard::AppMapDepends sleeping for #{delay}"
          sleep delay
        end
      end
    end
  end
end
