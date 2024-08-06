require "bundler/setup"
Bundler.require(:default)
require "active_record"
require "active_job"
require "benchmark"
require "active_support/notifications"

ActiveSupport::Notifications.subscribe "request.openkick" do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  puts "Import: #{event.duration.round}ms"
end

ActiveJob::Base.queue_adapter = :sidekiq

Openkick.redis = Redis.new

ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.time_zone_aware_attributes = true
# ActiveRecord::Base.establish_connection adapter: "sqlite3", database: "/tmp/openkick"
ActiveRecord::Base.establish_connection "postgresql://localhost/openkick_demo_development"
# ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveJob::Base.logger = nil

class Product < ActiveRecord::Base
  openkick batch_size: 1000

  def search_data
    {
      name: name,
      color: color,
      store_id: store_id
    }
  end
end

if ENV["SETUP"]
  total_docs = 100000

  ActiveRecord::Migration.create_table :products, force: :cascade do |t|
    t.string :name
    t.string :color
    t.integer :store_id
  end

  records = []
  total_docs.times do |i|
    records << {
      name: "Product #{i}",
      color: ["red", "blue"].sample,
      store_id: rand(10)
    }
  end
  Product.insert_all(records)

  puts "Imported"
end

result = nil
report = nil
stats = nil

Product.openkick_index.delete rescue nil

GC.start
GC.disable
start_mem = GetProcessMem.new.mb

time =
  Benchmark.realtime do
    # result = RubyProf.profile do
    # report = MemoryProfiler.report do
    # stats = AllocationStats.trace do
    reindex = Product.reindex #(async: true)
    # p reindex
    # end

    # 60.times do |i|
    #   if reindex.is_a?(Hash)
    #     docs = Openkick::Index.new(reindex[:index_name]).total_docs
    #   else
    #     docs = Product.openkick_index.total_docs
    #   end
    #   puts "#{i}: #{docs}"
    #   if docs == total_docs
    #     break
    #   end
    #   p Openkick.reindex_status(reindex[:index_name]) if reindex.is_a?(Hash)
    #   sleep(1)
    #   # Product.openkick_index.refresh
    # end
  end

puts
puts "Time: #{time.round(1)}s"

if result
  printer = RubyProf::GraphPrinter.new(result)
  printer.print(STDOUT, min_percent: 5)
end

if report
  puts report.pretty_print
end

if stats
  puts result.allocations(alias_paths: true).group_by(:sourcefile, :class).to_text
end
