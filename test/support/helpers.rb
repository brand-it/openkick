class Minitest::Test
  include ActiveJob::TestHelper

  def setup
    [Product, Store].each do |model|
      setup_model(model)
    end
  end

  protected

  def setup_animal
    setup_model(Animal)
  end

  def setup_region
    setup_model(Region)
  end

  def setup_speaker
    setup_model(Speaker)
  end

  def setup_model(model)
    # reindex once
    ($setup_model ||= {})[model] ||= model.reindex || true

    # clear every time
    Openkick.callbacks(:bulk) do
      model.destroy_all
    end
  end

  def store(documents, model = default_model, reindex: true)
    if reindex
      with_callbacks(:bulk) do
        with_transaction(model) do
          model.create!(documents.shuffle)
        end
      end
      model.openkick_index.refresh
    else
      Openkick.callbacks(false) do
        with_transaction(model) do
          model.create!(documents.shuffle)
        end
      end
    end
  end

  def store_names(names, model = default_model, reindex: true)
    store(names.map { |name| { name: } }, model, reindex:)
  end

  # no order
  def assert_search(term, expected, options = {}, model = default_model)
    assert_equal expected.sort, model.search(term, **options).map(&:name).sort
  end

  def assert_search_relation(expected, relation)
    assert_equal expected.sort, relation.map(&:name).sort
  end

  def assert_order(term, expected, options = {}, model = default_model)
    assert_equal expected, model.search(term, **options).map(&:name)
  end

  def assert_order_relation(expected, relation)
    assert_equal expected, relation.map(&:name)
  end

  def assert_equal_scores(term, options = {}, model = default_model)
    assert_equal 1, model.search(term, **options).hits.map { |a| a['_score'] }.uniq.size
  end

  def assert_first(term, expected, options = {}, model = default_model)
    assert_equal expected, model.search(term, **options).map(&:name).first
  end

  def assert_misspellings(term, expected, misspellings = {}, model = default_model)
    options = {
      fields: %i[name color],
      misspellings:
    }

    assert_search(term, expected, options, model)
  end

  def assert_warns(message, &)
    _, stderr = capture_io(&)

    assert_match "[openkick] WARNING: #{message}", stderr
  end

  def with_options(options, model = default_model)
    previous_options = model.openkick_options.dup
    begin
      model.instance_variable_set(:@openkick_index_name, nil)
      model.openkick_options.merge!(options)
      model.reindex
      yield
    ensure
      model.instance_variable_set(:@openkick_index_name, nil)
      model.openkick_options.clear
      model.openkick_options.merge!(previous_options)
    end
  end

  def with_callbacks(value, &)
    if Openkick.callbacks?(default: nil).nil?
      Openkick.callbacks(value, &)
    else
      yield
    end
  end

  def with_transaction(model, &)
    if model.respond_to?(:transaction) && !mongoid?
      model.transaction(&)
    else
      yield
    end
  end

  def activerecord?
    defined?(ActiveRecord)
  end

  def mongoid?
    defined?(Mongoid)
  end

  def default_model
    Product
  end

  def ci?
    ENV.fetch('CI', nil)
  end

  # for Active Job helpers
  def tagged_logger; end
end
