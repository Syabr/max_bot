# frozen_string_literal: true

module Max
  module Bot
    module Json
      module_function

      def decode_response(response)
        raw = response.body.to_s
        data =
          if raw.empty?
            {}
          else
            ::JSON.parse(raw)
          end

        unless response.success?
          body = data.is_a?(Hash) ? deep_symbolize(data) : data
          raise ApiError.new("HTTP #{response.status}", status: response.status, body: body)
        end

        deep_symbolize(data)
      rescue ::JSON::ParserError => e
        raise ApiError.new("Invalid JSON: #{e.message}", status: response.status, body: raw)
      end

      def deep_symbolize(obj)
        case obj
        in Hash
          obj.each_with_object({}) { |(k, v), h| h[k.to_sym] = deep_symbolize(v) }
        in Array
          obj.map { |e| deep_symbolize(e) }
        else
          obj
        end
      end
    end
  end
end
