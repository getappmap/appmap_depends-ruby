# frozen_string_literal: true

module AppMap
  module Depends
    extend self

    def modified(appmap_dir: DEFAULT_APPMAP_DIR, base_dir: nil)
      depends = AppMap::Depends::AppMapJSDepends.new(appmap_dir)
      depends.base_dir = base_dir if base_dir
      test_files = depends.depends

      Set.new prune_directory_prefix(test_files)
    end

    def diff(appmap_dir: DEFAULT_APPMAP_DIR, base_dir: nil, base_branches: DEFAULT_BASE_BRANCHES, base: nil, head: nil)
      diff = AppMap::Depends::GitDiff.new(base_branches: base_branches, base: base, head: head)
      modified_files = diff.modified_files

      depends = AppMap::Depends::AppMapJSDepends.new(appmap_dir)
      depends.base_dir = base_dir if base_dir
      test_files = depends.depends(modified_files)

      Set.new prune_directory_prefix(test_files)
    end

    def inspect_test_files(appmap_dir: DEFAULT_APPMAP_DIR, test_file_patterns: DEFAULT_TEST_FILE_PATTERNS)
      inspector = AppMap::Depends::TestFileInspector.new(appmap_dir, test_file_patterns)
      inspector.report
    end

    def report_list(title, files)
      warn [ title, files.to_a.sort.join(' ') ].join(': ') unless files.empty?
    end

    def run_tests(test_files, appmap_dir: DEFAULT_APPMAP_DIR, &block)
      test_files = test_files.to_a.sort
      warn "Running tests: #{test_files.join(' ')}"

      yield test_files

      system(%(./node_modules/@appland/cli/src/cli.js index --appmap-dir #{appmap_dir.shellescape}))  
    end

    # Remove out-of-date AppMaps which are unmodified +since+ the start time. This operation is used to remove AppMaps
    # that were previously generated from a test case that has been removed from a test file.
    #
    # * +since+ an instance of Time
    def remove_out_of_date_appmaps(since, appmap_dir: DEFAULT_APPMAP_DIR, base_dir: nil)
      since_ms = ( since.to_f * 1000 ).to_i

      depends = AppMap::Depends::AppMapJSDepends.new(appmap_dir)
      depends.base_dir = base_dir if base_dir
      depends.field = nil
      out_of_date_appmaps = depends.depends
      removed = []
      out_of_date_appmaps.each do |appmap_path|
        mtime_path = File.join(appmap_path, 'mtime')
        next unless File.exists?(mtime_path)

        appmap_mtime = File.read(mtime_path).to_i
        if appmap_mtime < since_ms
          Util.delete_appmap appmap_path
          removed << appmap_path
        end
      end
      removed.sort
    end

    protected

    def prune_directory_prefix(files)
      Util.normalize_path(files)
    end
  end
end
