module Rails
  def self.env
    ENV.fetch('RACK_ENV', nil)
  end
end

tenants = %w[tenant1 tenant2]
Apartment.configure do |config|
  config.tenant_names = tenants
  config.database_schema_file = false
  config.excluded_models = %w[Product Store Region Speaker Animal Dog Cat Sku Song Band]
end

class Tenant < ActiveRecord::Base
  openkick index_prefix: -> { Apartment::Tenant.current }
end

tenants.each do |tenant|
  begin
    Apartment::Tenant.create(tenant)
  rescue Apartment::TenantExists
    # do nothing
  end
  Apartment::Tenant.switch!(tenant)

  ActiveRecord::Migration.create_table :tenants, force: true do |t|
    t.string :name
    t.timestamps null: true
  end

  Tenant.reindex
end

Apartment::Tenant.reset
