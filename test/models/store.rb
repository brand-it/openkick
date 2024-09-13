class Store
  openkick(
    routing: true,
    merge_mappings: true,
    mappings: {
      properties: {
        name: { type: 'text' }
      }
    }
  )

  after_commit_reindex :products, partial: :store_name_data

  def search_document_id
    id
  end

  def search_routing
    name
  end
end
