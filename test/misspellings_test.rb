require_relative 'test_helper'

class MisspellingsTest < Minitest::Test
  def test_false
    store_names %w[abc abd aee]

    assert_search 'abc', ['abc'], misspellings: false
  end

  def test_distance
    store_names %w[abbb aabb]

    assert_search 'aaaa', ['aabb'], misspellings: { distance: 2 }
  end

  def test_prefix_length
    store_names %w[ap api apt any nap ah ahi]
    if prefix_length_misspellings_off?
      assert_search 'ap', ['ap'], misspellings: { prefix_length: 2 }
    else
      assert_search 'ap', %w[ap api apt], misspellings: { prefix_length: 2 }
    end

    assert_search 'api', %w[ap api apt], misspellings: { prefix_length: 2 }
  end

  def test_prefix_length_operator
    store_names %w[ap api apt any nap ah aha]
    if prefix_length_misspellings_off?
      assert_search 'ap ah', %w[ap ah], operator: 'or', misspellings: { prefix_length: 2 }
    else
      assert_search 'ap ah', %w[ap ah api apt aha], operator: 'or', misspellings: { prefix_length: 2 }
    end

    assert_search 'api ahi', %w[ap api apt ah aha], operator: 'or', misspellings: { prefix_length: 2 }
  end

  def test_fields_operator
    store [
      { name: 'red', color: 'red' },
      { name: 'blue', color: 'blue' },
      { name: 'cyan', color: 'blue green' },
      { name: 'magenta', color: 'red blue' },
      { name: 'green', color: 'green' }
    ]

    assert_search 'red blue', %w[red blue cyan magenta], operator: 'or', fields: ['color'], misspellings: false
  end

  def test_below_unmet
    store_names %w[abc abd aee]

    assert_search 'abc', %w[abc abd], misspellings: { below: 2 }
  end

  def test_below_unmet_result
    store_names %w[abc abd aee]

    assert_predicate Product.search('abc', misspellings: { below: 2 }), :misspellings?
  end

  def test_below_met
    store_names %w[abc abd aee]

    assert_search 'abc', ['abc'], misspellings: { below: 1 }
  end

  def test_below_met_result
    store_names %w[abc abd aee]

    assert !Product.search('abc', misspellings: { below: 1 }).misspellings?
  end

  def test_field_correct_spelling_still_works
    store [{ name: 'Sriracha', color: 'blue' }]

    assert_misspellings 'Sriracha', ['Sriracha'], { fields: %i[name color] }
    assert_misspellings 'blue', ['Sriracha'], { fields: %i[name color] }
  end

  def test_field_enabled
    store [{ name: 'Sriracha', color: 'blue' }]

    assert_misspellings 'siracha', ['Sriracha'], { fields: [:name] }
    assert_misspellings 'clue', ['Sriracha'], { fields: [:color] }
  end

  def test_field_disabled
    store [{ name: 'Sriracha', color: 'blue' }]

    assert_misspellings 'siracha', [], { fields: [:color] }
    assert_misspellings 'clue', [], { fields: [:name] }
  end

  def test_field_with_transpositions
    store [{ name: 'Sriracha', color: 'blue' }]

    assert_misspellings 'lbue', [], { transpositions: false, fields: [:color] }
  end

  def test_field_with_edit_distance
    store [{ name: 'Sriracha', color: 'blue' }]

    assert_misspellings 'crue', ['Sriracha'], { edit_distance: 2, fields: [:color] }
  end

  def test_field_multiple
    store [
      { name: 'Greek Yogurt', color: 'white' },
      { name: 'Green Onions', color: 'yellow' }
    ]

    assert_misspellings 'greed', ['Greek Yogurt', 'Green Onions'], { fields: %i[name color] }
    assert_misspellings 'mellow', ['Green Onions'], { fields: %i[name color] }
  end

  def test_field_requires_explicit_search_fields
    store_names ['Sriracha']
    assert_raises(ArgumentError) do
      assert_search 'siracha', ['Sriracha'], { misspellings: { fields: [:name] } }
    end
  end

  def test_field_word_start
    store_names ['Sriracha']

    assert_search 'siracha', ['Sriracha'], fields: [{ name: :word_middle }], misspellings: { fields: [:name] }
  end

  private

  def prefix_length_misspellings_off?
    if Openkick.client.opensearch?
      Openkick.client.server_below?('2.0.0',
                                    true_version: true)
    else
      Openkick.client.server_below?('8.0.0')
    end
  end
end
