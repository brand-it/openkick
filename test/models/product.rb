class Product
  openkick \
    synonyms: [
      %w[clorox bleach],
      %w[burger hamburger],
      %w[bandaid bandages],
      %w[UPPERCASE lowercase],
      'lightbulb => led,lightbulb',
      'lightbulb => halogenlamp'
    ],
    suggest: %i[name color],
    conversions: [:conversions],
    locations: %i[location multiple_locations],
    text_start: [:name],
    text_middle: [:name],
    text_end: [:name],
    word_start: [:name],
    word_middle: [:name],
    word_end: [:name],
    highlight: [:name],
    filterable: %i[name color description],
    similarity: 'BM25',
    match: ENV['MATCH'] ? ENV['MATCH'].to_sym : nil

  attr_accessor :conversions, :user_ids, :aisle, :details

  class << self
    attr_accessor :dynamic_data
  end

  def search_data
    return self.class.dynamic_data.call if self.class.dynamic_data

    serializable_hash.except('id', '_id').merge(
      conversions:,
      user_ids:,
      location: { lat: latitude, lon: longitude },
      multiple_locations: [{ lat: latitude, lon: longitude }, { lat: 0, lon: 0 }],
      aisle:,
      details:
    )
  end

  def should_index?
    name != 'DO NOT INDEX'
  end

  def search_name
    {
      name:
    }
  end
end
