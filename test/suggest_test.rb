require_relative 'test_helper'

class SuggestTest < Minitest::Test
  def setup
    super
    Product.reindex
  end

  def test_basic
    store_names ['Great White Shark', 'Hammerhead Shark', 'Tiger Shark']

    assert_suggest 'How Big is a Tigre Shar', 'how big is a tiger shark', fields: [:name]
  end

  def test_perfect
    store_names ['Tiger Shark', 'Great White Shark']

    assert_suggest 'Tiger Shark', nil, fields: [:name] # no correction
  end

  def test_phrase
    store_names ['Big Tiger Shark', 'Tiger Sharp Teeth', 'Tiger Sharp Mind']

    assert_suggest 'How to catch a big tiger shar', 'how to catch a big tiger shark', fields: [:name]
  end

  def test_empty
    assert_suggest 'hi', nil
  end

  def test_without_option
    store_names ['hi'] # needed to prevent ElasticsearchException - seed 668
    assert_raises(RuntimeError) { Product.search('hi').suggestions }
  end

  def test_multiple_fields
    store [
      { name: 'Shark', color: 'Sharp' },
      { name: 'Shark', color: 'Sharp' }
    ]

    assert_suggest_all 'shar', %w[shark sharp]
  end

  def test_multiple_fields_highest_score_first
    store [
      { name: 'Tiger Shark', color: 'Sharp' }
    ]

    assert_suggest 'tiger shar', 'tiger shark'
  end

  def test_multiple_fields_same_value
    store [
      { name: 'Shark', color: 'Shark' }
    ]

    assert_suggest_all 'shar', ['shark']
  end

  def test_fields_option
    store [
      { name: 'Shark', color: 'Sharp' }
    ]

    assert_suggest_all 'shar', ['shark'], fields: [:name]
  end

  def test_fields_option_multiple
    store [
      { name: 'Shark' }
    ]

    assert_suggest 'shar', 'shark', fields: %i[name unknown]
  end

  def test_fields_partial_match
    store_names ['Great White Shark', 'Hammerhead Shark', 'Tiger Shark']

    assert_suggest 'How Big is a Tigre Shar', 'how big is a tiger shark', fields: [{ name: :word_start }]
  end

  def test_fields_partial_match_boost
    store_names ['Great White Shark', 'Hammerhead Shark', 'Tiger Shark']

    assert_suggest 'How Big is a Tigre Shar', 'how big is a tiger shark', fields: [{ 'name^2' => :word_start }]
  end

  def test_multiple_models
    skip # flaky test
    store_names ['Great White Shark', 'Hammerhead Shark', 'Tiger Shark']

    assert_equal 'how big is a tiger shark',
                 Openkick.search('How Big is a Tigre Shar', suggest: [:name], fields: [:name]).suggestions.first
  end

  def test_multiple_models_no_fields
    store_names ['Great White Shark', 'Hammerhead Shark', 'Tiger Shark']
    assert_raises(ArgumentError) { Openkick.search('How Big is a Tigre Shar', suggest: true) }
  end

  def test_star
    assert_empty Product.search('*', suggest: true).suggestions
  end

  protected

  def assert_suggest(term, expected, options = {})
    result = Product.search(term, suggest: true, **options).suggestions.first
    if expected.nil?
      assert_nil result
    else
      assert_equal expected, result
    end
  end

  # any order
  def assert_suggest_all(term, expected, options = {})
    assert_equal expected.sort, Product.search(term, suggest: true, **options).suggestions.sort
  end
end
