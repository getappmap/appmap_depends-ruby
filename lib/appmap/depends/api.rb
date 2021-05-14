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

    def inspect_test_files(appmap_dir = DEFAULT_APPMAP_DIR, test_file_patterns = DEFAULT_TEST_FILE_PATTERNS)
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

    protected

    def prune_directory_prefix(files)
      Util.normalize_path(files)
    end
  end
end
