require_relative 'test_helper'

class MergedMsearchTest < Minitest::Test
  def test_match
    store_names ['Whole Milk', 'Fat Free Milk', 'Milk']

    results = MergedMsearch.search(
      [
        Store.search('Fat'),
        Store.search('Whole')
      ], limit: 2
    )

    assert_equal ['Fat Free Milk', 'Whole Milk'], results.map(&:name)
  end
end
