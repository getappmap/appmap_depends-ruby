# Archived

This project is archived because the functionality has moved to [https://github.com/applandinc/appmap-ruby](https://appland.com/docs/reference/appmap-ruby.html).

# About

This gem provides Rake tasks called `depends:modified` and `depends:diff`. These Rake tasks automatically compute a list of test cases that need to be re-run based on which source files have been modified. They use [AppMap](https://github.com/applandinc/appmap-ruby) data files, which contain information about test case dependencies on source files, to perform this feat.

`appmap_depends` depends on an NPM package called [@appland/cli](https://www.npmjs.com/package/@appland/cli), which does most of the heavy lifting of processing AppMap data.

# How it works

The Rake tasks `depends:modified` and `depends:diff` require Node.js and the NPM package `@appland/cli`.

Each task looks at which source files have been locally modified. The difference between `depends:modified` and `depends:diff` is what source files are considered modified; this difference is described in detail in the next section. The Rake task then scans the AppMaps to figure out which ones are out-of-date with respect to the source files. This is possible since each AppMap contains a `classMap`, which lists all the source files that are included in the recording. Each AppMap has a `source_location` field, which identifies the test case file that was run to generate the AppMap. `depends` prints the list of test case files to standard out.

The `depends:modified` task looks at which source files have been locally modified. This task is used in local development. Run it as you work with the code.

The `depends:diff` task looks at source files that are modified relative to a base `git` branch. This task is used in CI. Run it before running the full test suite, so that the tests which are most likely to fail will be run first. If any of the tests in this batch fail, fail the build until the developer fixes the tests, then run the full test suite.

## Installation

Add this line to your application's Gemfile:

```ruby
group :development, :test do
  gem 'appmap_depends'
end
```

And then execute:

```sh-session
$ bundle install
```

# Usage

## Defining the Rake tasks

You need to define the Rake tasks. In Rails, this is done by creating a file like `lib/tasks/appmap.rake`.

In the file, check if `appmap_depends` is loaded, and then configure the Rake tasks.

```ruby
namespace :appmap do
  def depends_tasks
    namespace :depends do
      task :modified do
        @appmap_modified_files = AppMap::Depends.modified
        AppMap::Depends.report_list 'Out of date', @appmap_modified_files
      end

      task :diff do
        @appmap_modified_files = AppMap::Depends.diff(base: BASE_BRANCH)
        AppMap::Depends.report_list 'Out of date', @appmap_modified_files
      end

      task :test_file_report do
        @appmap_test_file_report = AppMap::Depends.inspect_test_files
        @appmap_test_file_report.report
      end

      def run_minitest(test_files)
        raise "RAILS_ENV must be 'test'" unless Rails.env.test?
        $LOAD_PATH << 'test'
        test_files.each do |test_file|
          load test_file
        end
        $ARGV.replace []
        Minitest.autorun
      end

      run_rspec(test_files)
        system({ 'RAILS_ENV' => 'test', 'APPMAP' => 'true' }, "bundle exec rspec --format Fuubar #{test_files.map(&:shellescape).join(' ')}")
      end

      task :update_appmaps do
        @appmap_test_file_report.clean_appmaps

        @appmap_modified_files += @appmap_test_file_report.modified_files

        if @appmap_modified_files.blank?
          warn 'AppMaps are up to date'
          next
        end

        AppMap::Depends.run_tests(@appmap_modified_files) do |test_files|
          warn 'To generate AppMaps, uncomment run_minitest or run_rspec as appropriate for your project'
          # run_minitest(test_files)
          # run_rspec(test_files)
        end
      end
    end

    desc 'Bring AppMaps up to date with local file modifications, and updated derived data such as Swagger files'
    task :modified => [ :'depends:modified', :'depends:test_file_report', :'depends:update_appmaps', :swagger ]

    desc 'Bring AppMaps up to date with file modifications relative to the base branch'
    task :diff, [ :base ] => [ :'depends:diff', :'depends:update_appmaps', :swagger, :'swagger:uptodate' ]
  end
end

if %w[test development].member?(Rails.env)
  depends_tasks

  desc 'Bring AppMaps up to date with local file modifications, and updated derived data such as Swagger files'
  task :appmap => :'appmap:depends:modified'
end
```

## Running in CI

In the CI environment, run the `appmap:depends:diff` task to compute the list of changed test files, and then
run those tests directly using the test command.

### RSpec

This is easy with RSpec, just pipe the modified files to the `rspec` command:

```sh-session
$ bundle exec rake appmap:depends:diff | tee /dev/tty | xargs env APPMAP=true bundle exec rspec
```

### Minitest

Minitest doesn't have a "run the tests" command that's analagous to `rspec`. You can define a Rask task which computes the changed test files and then uses the
Rake task `Rails::TestUnit::Runner` to run the tests.

```ruby
namespace :appmap
  if %w[test development].member?(Rails.env)
    desc 'Run minitest tests that are modified relative to the base branch'
    task :'test:diff' => :'test:prepare' do
        task = AppMap::Depends::DiffTask.new
        # This line is only needed if the base is not 'remotes/origin/main' or 'remotes/origin/master'
        task.base = BASE_BRANCH
        files = task.files
        if Rake.verbose == true
          warn 'Out of date tests:'
          warn files.join(' ')
        end
        $: << "test"
        Rails::TestUnit::Runner.rake_run(files)
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/applandinc/appmap_depends-ruby.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
