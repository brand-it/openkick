module Openkick
  class Relation
    NO_DEFAULT_VALUE = Object.new

    delegate :body, :params, to: :query
    delegate_missing_to :private_execute

    attr_reader :model
    alias klass model

    def initialize(model, term = '*', **options)
      @model = model
      @term = term
      @options = options

      # generate query to validate options
      query
    end

    # same as Active Record
    def inspect
      entries = results.first(11).map!(&:inspect)
      entries[10] = '...' if entries.size == 11
      "#<#{self.class.name} [#{entries.join(', ')}]>"
    end

    def limit(value)
      clone.limit!(value)
    end

    def limit!(value)
      check_loaded
      @options[:limit] = value
      self
    end

    def offset(value = NO_DEFAULT_VALUE)
      # TODO: remove in Openkick 6
      if value == NO_DEFAULT_VALUE
        private_execute.offset
      else
        clone.offset!(value)
      end
    end

    def offset!(value)
      check_loaded
      @options[:offset] = value
      self
    end

    def page(value)
      clone.page!(value)
    end

    def page!(value)
      check_loaded
      @options[:page] = value
      self
    end

    def per_page(value = NO_DEFAULT_VALUE)
      # TODO: remove in Openkick 6
      if value == NO_DEFAULT_VALUE
        private_execute.per_page
      else
        clone.per_page!(value)
      end
    end

    def per_page!(value)
      check_loaded
      @options[:per_page] = value
      self
    end

    def where(value = NO_DEFAULT_VALUE)
      if value == NO_DEFAULT_VALUE
        Where.new(self)
      else
        clone.where!(value)
      end
    end

    def where!(value)
      check_loaded
      @options[:where] = if @options[:where]
                           { _and: [@options[:where], ensure_permitted(value)] }
                         else
                           ensure_permitted(value)
                         end
      self
    end

    def rewhere(value)
      clone.rewhere!(value)
    end

    def rewhere!(value)
      check_loaded
      @options[:where] = ensure_permitted(value)
      self
    end

    def order(*values)
      clone.order!(*values)
    end

    def order!(*values)
      values = values.first if values.size == 1 && values.first.is_a?(Array)
      check_loaded
      (@options[:order] ||= []).concat(values)
      self
    end

    def reorder(*values)
      clone.reorder!(*values)
    end

    def reorder!(*values)
      check_loaded
      @options[:order] = values
      self
    end

    def select(*values, &)
      if block_given?
        private_execute.select(*values, &)
      else
        clone.select!(*values)
      end
    end

    def select!(*values)
      check_loaded
      (@options[:select] ||= []).concat(values)
      self
    end

    def reselect(*values)
      clone.reselect!(*values)
    end

    def reselect!(*values)
      check_loaded
      @options[:select] = values
      self
    end

    # experimental
    def includes(*values)
      clone.includes!(*values)
    end

    # experimental
    def includes!(*values)
      check_loaded
      (@options[:includes] ||= []).concat(values)
      self
    end

    # experimental
    def only(*keys)
      Relation.new(@model, @term, **@options.slice(*keys))
    end

    # experimental
    def except(*keys)
      Relation.new(@model, @term, **@options.except(*keys))
    end

    # experimental
    def load
      private_execute
      self
    end

    def loaded?
      !@execute.nil?
    end

    def respond_to_missing?(method_name, include_all)
      Results.new(nil, nil, nil).respond_to?(method_name, include_all) || super
    end

    # TODO: uncomment in 6.0
    # def to_yaml
    #   private_execute.to_a.to_yaml
    # end

    private

    def private_execute
      @execute ||= query.execute
    end

    def query
      @query ||= Query.new(@model, @term, **@options)
    end

    def check_loaded
      raise Error, 'Relation loaded' if loaded?

      # reset query since options will change
      @query = nil
    end

    # provides *very* basic protection from unfiltered parameters
    # this is not meant to be comprehensive and may be expanded in the future
    def ensure_permitted(obj)
      obj.to_h
    end

    def initialize_copy(other)
      super
      @execute = nil
    end
  end
end
