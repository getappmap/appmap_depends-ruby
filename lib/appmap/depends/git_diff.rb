module AppMap
  module Depends
    class GitDiff
      attr_reader :head, :base_branches

      def initialize(base_branches: [], base: nil, head: nil)
        @base_branches = base_branches
        @base = base
        @head = head
      end

      def base=(base)
        @base = base
      end

      def base
        return @base if @base

        git_exists = -> { system('git --version 2>&1 > /dev/null') }
        detect_branch = ->(branch) { `git branch -a`.split("\n").map(&:strip).member?(branch) }
        detect_base = lambda do
          return nil unless git_exists.()

          @base_branches.find(&detect_branch)
        end
        @base = detect_base.()
        raise "Unable to detect base branch. Specify it explicitly as a task argument." unless @base
        @base
      end

      def modified_files
        warn "Using base #{base.inspect}" if Depends.verbose
        warn "Using head #{head.inspect}" if head && Depends.verbose

        branches = [ head, base ].compact
        diff_cmd = [ 'git', 'diff', '--name-only', branches.join('..') ]

        if Depends.verbose
          warn diff_cmd.join(' ')
          warn "Files modified #{head ? 'in ' + head : 'locally'} compared to #{base}:"
        end

        stdout, stderr, status = Open3.capture3(*diff_cmd)
        if status.exitstatus != 0
          warn stdout
          warn stderr
          raise CommandError.new(diff_cmd)
        end
        stdout.split("\n")
      end
    end
  end
end
