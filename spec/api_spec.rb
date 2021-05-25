require 'spec_helper'
require 'appmap_depends'

describe 'Depends API' do
  describe '.modified' do
    it 'is empty by default' do
      test_list = AppMap::Depends.modified(appmap_dir: TEST_DIR, base_dir: BASE_DIR)
      expect(test_list).to be_empty
    end

    it 'detects modification of a dependent file' do
      FileUtils.touch 'spec/fixtures/app/models/user.rb'
      test_list = AppMap::Depends.modified(appmap_dir: TEST_DIR, base_dir: BASE_DIR)
      expect(test_list.to_a).to eq(%w[spec/fixtures/spec/user_spec.rb])
    end
  end

  describe '.inspect_test_files' do
    it 'reports metadata, added, removed, changed, failed' do
      test_report = AppMap::Depends.inspect_test_files(appmap_dir: TEST_DIR, test_file_patterns: %w[spec/fixtures/spec/*_spec.rb])
      expect(test_report.metadata_files).to eq(%w[spec/fixtures/user_page_scenario/metadata.json spec/fixtures/revoke_api_key/metadata.json])
      expect(test_report.added).to be_empty
      expect(test_report.removed).to be_empty
      expect(test_report.changed).to be_empty
      expect(test_report.failed.to_a).to eq(%w[spec/fixtures/spec/user_spec.rb])
    end
    it 'detects an added test' do
      FileUtils.touch 'spec/tmp/new_spec.rb'
      test_report = AppMap::Depends.inspect_test_files(appmap_dir: TEST_DIR, test_file_patterns: %w[spec/fixtures/spec/*_spec.rb spec/tmp/*_spec.rb])
      expect(test_report.added.to_a).to eq(%w[spec/tmp/new_spec.rb])
    end
    it 'detects a removed test' do
      FileUtils.mv 'spec/fixtures/spec/user_spec.rb', 'spec/tmp/'
      begin
        test_report = AppMap::Depends.inspect_test_files(appmap_dir: TEST_DIR, test_file_patterns: %w[spec/fixtures/spec/*_spec.rb spec/tmp/*_spec.rb])
        expect(test_report.removed.to_a).to eq(%w[spec/fixtures/spec/user_spec.rb])
      ensure
        FileUtils.mv 'spec/tmp/user_spec.rb', 'spec/fixtures/spec/'
      end
    end
    it 'detects a changed test' do
      FileUtils.touch 'spec/fixtures/spec/user_spec.rb'
      test_report = AppMap::Depends.inspect_test_files(appmap_dir: TEST_DIR, test_file_patterns: %w[spec/fixtures/spec/*_spec.rb])
      expect(test_report.changed.to_a).to eq(%w[spec/fixtures/spec/user_spec.rb])
    end
    it 'removes AppMaps whose source file has been removed' do
      appmap = JSON.parse(File.read('spec/fixtures/revoke_api_key.appmap.json'))
      appmap['metadata']['source_location'] = 'spec/tmp/new_spec.rb'
      new_spec_file = 'spec/fixtures/revoke_api_key_2.appmap.json'
      File.write new_spec_file, JSON.pretty_generate(appmap)

      begin
        update_appmap_index
        test_report = AppMap::Depends.inspect_test_files(appmap_dir: TEST_DIR, test_file_patterns: %w[spec/fixtures/spec/*_spec.rb])
        expect(test_report.removed.to_a).to eq(%w[spec/tmp/new_spec.rb])

        test_report.clean_appmaps

        expect(File.exists?(new_spec_file)).to be_falsey
      ensure
        FileUtils.rm_f new_spec_file if File.exists?(new_spec_file)
        FileUtils.rm_rf new_spec_file.split('.')[0]
      end
    end
  end

  describe '.remove_out_of_date_appmaps' do
    it 'is a nop in normal circumstances' do
      since = Time.now
      removed = AppMap::Depends.remove_out_of_date_appmaps(since, appmap_dir: TEST_DIR, base_dir: BASE_DIR)
      expect(removed).to be_empty
    end

    it "removes an out-of-date AppMap that hasn't been brought up to date" do
      # This AppMap will be modified before the 'since' time
      appmap_path = "spec/fixtures/user_page_scenario.appmap.json"
      appmap = File.read(appmap_path)

      sleep 0.01
      since = Time.now
      sleep 0.01

      # Touch the rest of the AppMaps so that they are modified after +since+
      Dir.glob('spec/fixtures/*.appmap.json').each do |path|
        next if path == appmap_path
        FileUtils.touch path
      end

      sleep 0.01
      # Make the AppMaps out of date
      FileUtils.touch 'spec/fixtures/app/models/user.rb'
      sleep 0.01

      begin
        # At this point, we would run tests to bring the AppMaps up to date
        # Then once the tests have finished, remove any AppMaps that weren't refreshed
        removed = AppMap::Depends.remove_out_of_date_appmaps(since, appmap_dir: TEST_DIR, base_dir: BASE_DIR)
        expect(removed).to eq([ appmap_path.split('.')[0] ])  
      ensure
        File.write(appmap_path, appmap)        
      end
    end
  end
end
