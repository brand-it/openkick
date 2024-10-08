require_relative 'test_helper'

class IndexOptionsTest < Minitest::Test
  def setup
    Song.destroy_all
  end

  def test_case_sensitive
    with_options({ case_sensitive: true }) do
      store_names %w[Test test]

      assert_search 'test', ['test'], { misspellings: false }
    end
  end

  def test_no_stemming
    with_options({ stem: false }) do
      store_names %w[milk milks]

      assert_search 'milks', ['milks'], { misspellings: false }
    end
  end

  def test_no_stem_exclusion
    with_options({}) do
      store_names %w[animals anime]

      assert_search 'animals', %w[animals anime], { misspellings: false }
      assert_search 'anime', %w[animals anime], { misspellings: false }
      assert_equal ['anim'], Song.openkick_index.tokens('anime', analyzer: 'openkick_index')
      assert_equal ['anim'], Song.openkick_index.tokens('anime', analyzer: 'openkick_search2')
    end
  end

  def test_stem_exclusion
    with_options({ stem_exclusion: ['anime'] }) do
      store_names %w[animals anime]

      assert_search 'animals', ['animals'], { misspellings: false }
      assert_search 'anime', ['anime'], { misspellings: false }
      assert_equal ['anime'], Song.openkick_index.tokens('anime', analyzer: 'openkick_index')
      assert_equal ['anime'], Song.openkick_index.tokens('anime', analyzer: 'openkick_search2')
    end
  end

  def test_no_stemmer_override
    with_options({}) do
      store_names %w[animals animations]

      assert_search 'animals', %w[animals animations], { misspellings: false }
      assert_search 'animations', %w[animals animations], { misspellings: false }
      assert_equal ['anim'], Song.openkick_index.tokens('animations', analyzer: 'openkick_index')
      assert_equal ['anim'], Song.openkick_index.tokens('animations', analyzer: 'openkick_search2')
    end
  end

  def test_stemmer_override
    with_options({ stemmer_override: ['animations => animat'] }) do
      store_names %w[animals animations]

      assert_search 'animals', ['animals'], { misspellings: false }
      assert_search 'animations', ['animations'], { misspellings: false }
      assert_equal ['animat'], Song.openkick_index.tokens('animations', analyzer: 'openkick_index')
      assert_equal ['animat'], Song.openkick_index.tokens('animations', analyzer: 'openkick_search2')
    end
  end

  def test_special_characters
    with_options({ special_characters: false }) do
      store_names ['jalapeño']

      assert_search 'jalapeno', [], { misspellings: false }
    end
  end

  def test_index_name
    with_options({ index_name: 'songs_v2' }) do
      assert_equal 'songs_v2', Song.openkick_index.name
    end
  end

  def test_index_name_callable
    with_options({ index_name: -> { 'songs_v2' } }) do
      assert_equal 'songs_v2', Song.openkick_index.name
    end
  end

  def test_index_prefix
    with_options({ index_prefix: 'hello' }) do
      assert_equal 'hello_songs_test', Song.openkick_index.name
    end
  end

  def test_index_prefix_callable
    with_options({ index_prefix: -> { 'hello' } }) do
      assert_equal 'hello_songs_test', Song.openkick_index.name
    end
  end

  def default_model
    Song
  end
end
