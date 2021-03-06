require 'active_record/fixtures'
desc "create initial records for enju_event"
namespace :enju_event do
  task :setup => :environment do
    Dir.glob(Rails.root.to_s + '/db/fixtures/enju_event/*.yml').each do |file|
      ActiveRecord::Fixtures.create_fixtures('db/fixtures/enju_event', File.basename(file, '.*'))
    end
  end

  desc "import events from a TSV file"
  task :event_import => :environment do
    EventImportFile.import
  end
end
