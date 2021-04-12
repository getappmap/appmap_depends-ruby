# `appmap_depends`

This gem provides Rake tasks called `depends` and `depends:diff`. These Rake tasks automatically compute a list of test cases that need to be re-run based on which source files have been modified. They use [AppMap](https://github.com/applandinc/appmap-ruby) data files, which contain information about test case dependencies on source files, to perform this feat.

`appmap_depends` depends on an NPM package called [@appland/appmap](https://www.npmjs.com/package/@appland/appmap-js), which does most of the heavy lifting of processing AppMap data.

# How it works

The Rake tasks `depends` and `depends:diff` require Node.js and the NPM package `@appland/appmap`.

Each task looks at which source files have been locally modified. The difference between `depends` and `depends:diff` is what source files are considered modified; this difference is described in detail in the next section. The Rake task then scans the AppMaps to figure out which ones are out-of-date with respect to the source files. This is possible since each AppMap contains a `classMap`, which lists all the source files that are included in the recording. Each AppMap has a `source_location` field, which identifies the test case file that was run to generate the AppMap. `depends` prints the list of test case files to standard out.

The `depends` task looks at which source files have been locally modified. This task is used in local development. Run it as you work with the code.

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

## Defining the `appmap:depends` Rake tasks

You need to define the `appmap:depends` Rake tasks. In Rails, this is done by creating a file like `lib/tasks/appmap.rake`.

In the file, check if `appmap_depends` is loaded, and then configure the Rake tasks.

```ruby
namespace :appmap do
  if %w[development test].member?(Rails.env)
    # appmap:depends - use in local development
    AppMap::Depends::ModifiedTask.new.define

    # appmap:depends:diff - use in CI
    AppMap::Depends::DiffTask.new.define
  end
end
```

## Configuring Guard

Running `appmap:depends` or `appmap:depends:diff` will just print a list of modified files to stdout. What you generally want to do is run those tests using `minitest` or `rspec`.

When developing locally, a very handy way to do this is with `guard`. Install the `guard` gem and then configure the `Guardfile` to run the test cases when the test files are modified.

For example:

```ruby
# Re-run tests an update AppMap files when dependent files are modified.
guard :minitest, spring: "env APPMAP=true bin/rails test", all_on_start: false do
  # Retest any modified minitest file
  watch(%r{^test/(.*)/?(.*)_test\.rb$})

  # ... other Guard clauses here - for example, re-run all tests when test_helper.rb is modified
  watch('test/test_helper.rb') { 'test' }
end
```

## Running in development

In development, you'll start by running Guard. It will look something like this:

```sh-session
14:45:34 - INFO - Guard::Minitest 2.4.6 is running, with Minitest::Unit 5.11.3!
14:45:34 - INFO - Guard is now watching at '/Users/myname/source/land-of-apps/sample_app_6th_ed'
[1] guard(main)> 
```

Then, in a separate terminal, use `appmap:depends` to touch all the modified test cases:

```sh-session
$ bundle exec rake appmap:depends | tee /dev/tty | xargs touch
Out of date tests:
/Users/myname/source/land-of-apps/sample_app_6th_ed/test/integration/password_resets_test.rb
/Users/myname/source/land-of-apps/sample_app_6th_ed/test/integration/users_signup_test.rb
/Users/myname/source/land-of-apps/sample_app_6th_ed/test/mailers/user_mailer_test.rb
```

In the Guard window, you'll see:

```sh-session
14:46:41 - INFO - Running: test/integration/users_signup_test.rb test/integration/password_resets_test.rb test/mailers/user_mailer_test.rb
Running via Spring preloader in process 34005
Configuring AppMap recorder for Minitest
Started with run options --seed 46658

  5/5: [=============================================================] 100% Time: 00:00:02, Time: 00:00:02

Finished in 2.35304s
5 tests, 48 assertions, 0 failures, 0 errors, 0 skips

[1] guard(main)> 
```

## Running in CI

In the CI environment, you won't use Guard. Instead, you'll use the `appmap:depends:diff` task to compute the list of changed test files, and then
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
