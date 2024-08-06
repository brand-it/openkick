namespace :openkick do
  desc "reindex a model (specify CLASS)"
  task reindex: :environment do
    class_name = ENV["CLASS"]
    abort "USAGE: rake openkick:reindex CLASS=Product" unless class_name

    model =
      begin
        Openkick.load_model(class_name)
      rescue Openkick::Error => e
        abort e.message
      end

    puts "Reindexing #{model.name}..."
    model.reindex
    puts "Reindex successful"
  end

  namespace :reindex do
    desc "reindex all models"
    task all: :environment do
      # eager load models to populate Openkick.models
      if Rails.respond_to?(:autoloaders) && Rails.autoloaders.zeitwerk_enabled?
        # fix for https://github.com/rails/rails/issues/37006
        Zeitwerk::Loader.eager_load_all
      else
        Rails.application.eager_load!
      end

      Openkick.models.each do |model|
        puts "Reindexing #{model.name}..."
        model.reindex
      end
      puts "Reindex complete"
    end
  end
end
