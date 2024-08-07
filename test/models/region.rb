class Region
  openkick \
    geo_shape: [:territory]

  attr_accessor :territory

  def search_data
    {
      name:,
      text:,
      territory:
    }
  end
end
