require 'bundler/setup'
Bundler.require(:default)
require 'active_record'
require 'benchmark/ips'

ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.time_zone_aware_attributes = true
ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: '/tmp/openkick'

class Product < ActiveRecord::Base
  openkick batch_size: 1000

  def search_data
    {
      name:,
      color:,
      store_id:
    }
  end
end

if ENV['SETUP']
  total_docs = 1_000_000

  ActiveRecord::Migration.create_table :products, force: :cascade do |t|
    t.string :name
    t.string :color
    t.integer :store_id
  end

  records = []
  total_docs.times do |i|
    records << {
      name: "Product #{i}",
      color: %w[red blue].sample,
      store_id: rand(10)
    }
  end
  Product.insert_all(records)

  puts 'Imported'

  Product.reindex

  puts 'Reindexed'
end

query = Product.search('product', fields: [:name], where: { color: 'red', store_id: 5 }, limit: 10_000, load: false)

require 'pp'
pp query.body.as_json
puts

Benchmark.ips do |x|
  x.report { query.dup.execute }
end
