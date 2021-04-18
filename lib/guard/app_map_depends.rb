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
      @depends_verbose = AppMap::Depends.verbose
    end

    def delay
      options[:delay] || DEFAULT_DELAY
    end

    def start
      @run_thread = start_thread
      AppMap::Depends.verbose(true) if @options[:debug]
    end

    def stop
      @run_thread.kill if @run_thread
      @run_thread = nil
      AppMap::Depends.verbose(@depends_verbose)
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
      depends.appmap_dir = options[:appmap_dir] if options[:appmap_dir]
      depends.base_dir = options[:watch_dir] if options[:watch_dir]
      files = depends.depends(paths.map{|p| File.expand_path(p)})
      files.each do |file|
        full_path = File.join(options[:test_dir] || '.', file)
        Compat::UI.info "Guard::AppMapDepends touching: #{full_path}"

        FileUtils.touch full_path, nocreate: true
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
