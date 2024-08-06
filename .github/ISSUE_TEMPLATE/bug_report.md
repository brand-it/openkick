---
name: Bug report
about: Create a report to help us improve
title: ''
labels: bug report
assignees: ''

---

**First**
Search existing issues to see if it’s been reported and make sure you’re on the latest version.

**Describe the bug**
A clear and concise description of the bug.

**To reproduce**
Use this code to reproduce when possible:

```ruby
require "bundler/inline"

gemfile do
  source "https://rubygems.org"

  gem "activerecord", require: "active_record"
  gem "activejob", require: "active_job"
  gem "sqlite3"
  gem "openkick", git: "https://github.com/ankane/openkick.git"
  # uncomment one
  # gem "elasticsearch"
  # gem "opensearch-ruby"
end

puts "Openkick version: #{Openkick::VERSION}"
puts "Server version: #{Openkick.server_version}"

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
ActiveJob::Base.queue_adapter = :inline

ActiveRecord::Schema.define do
  create_table :products do |t|
    t.string :name
  end
end

class Product < ActiveRecord::Base
  openkick
end

Product.reindex
Product.create!(name: "Test")
Product.search_index.refresh
p Product.search("test", fields: [:name]).response
```

**Additional context**
Add any other context.
