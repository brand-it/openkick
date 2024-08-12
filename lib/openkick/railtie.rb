module Openkick
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/openkick.rake'
    end
  end
end
