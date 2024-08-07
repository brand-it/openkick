class Speaker
  openkick \
    conversions: %w[conversions_a conversions_b],
    search_synonyms: [
      %w[clorox bleach],
      %w[burger hamburger],
      %w[bandaids bandages],
      %w[UPPERCASE lowercase],
      'led => led,lightbulb',
      'halogen lamp => lightbulb',
      ['United States of America', 'USA']
    ],
    word_start: [:name]

  attr_accessor :conversions_a, :conversions_b, :aisle

  def search_data
    serializable_hash.except('id', '_id').merge(
      conversions_a:,
      conversions_b:,
      aisle:
    )
  end
end
