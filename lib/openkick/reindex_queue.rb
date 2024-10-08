module Openkick
  class ReindexQueue
    attr_reader :name

    def initialize(name)
      @name = name

      raise Error, 'Openkick.redis not set' unless Openkick.redis
    end

    # supports single and multiple ids
    def push(record_ids)
      Openkick.with_redis { |r| r.call('LPUSH', redis_key, record_ids) }
    end

    def push_records(records)
      record_ids =
        records.map do |record|
          # always pass routing in case record is deleted
          # before the queue job runs
          routing = record.search_routing if record.respond_to?(:search_routing)

          # escape pipe with double pipe
          value = escape(record.id.to_s)
          value = "#{value}|#{escape(routing)}" if routing
          value
        end

      push(record_ids)
    end

    # TODO: use reliable queuing
    def reserve(limit: 1000)
      if supports_rpop_with_count?
        Openkick.with_redis { |r| r.call('RPOP', redis_key, limit) }.to_a
      else
        record_ids = []
        Openkick.with_redis do |r|
          while record_ids.size < limit && (record_id = r.call('RPOP', redis_key))
            record_ids << record_id
          end
        end
        record_ids
      end
    end

    def clear
      Openkick.with_redis { |r| r.call('DEL', redis_key) }
    end

    def length
      Openkick.with_redis { |r| r.call('LLEN', redis_key) }
    end

    private

    def redis_key
      "openkick:reindex_queue:#{name}"
    end

    def supports_rpop_with_count?
      redis_version >= Gem::Version.new('6.2')
    end

    def redis_version
      @redis_version ||=
        Openkick.with_redis do |r|
          info = r.call('INFO')
          matches = /redis_version:(\S+)/.match(info)
          Gem::Version.new(matches[1])
        end
    end

    def escape(value)
      value.to_s.gsub('|', '||')
    end
  end
end
