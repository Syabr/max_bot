# frozen_string_literal: true

require 'net/http'
require 'securerandom'
require 'uri'

module Max
  module Bot
    # Multipart +data=@file+ upload to the URL returned by +POST /uploads+.
    # Uses stdlib Net::HTTP to avoid Faraday multipart dependency (which requires
    # the external faraday-multipart gem in Faraday 2.x).
    # @see https://dev.max.ru/docs-api/methods/POST/uploads
    module MultipartUpload
      module_function

      def post_file(upload_url:, path:, authorization:, filename: nil)
        raise ArgumentError, 'upload_url must be a non-empty String' if upload_url.to_s.strip.empty?

        filename ||= File.basename(path)
        filename = filename.to_s.gsub(/["\r\n]/, '_')

        uri = URI(upload_url)
        boundary = "----maxbot#{SecureRandom.hex(16)}"
        file_content = File.binread(path)
        body = +''
        body << "--#{boundary}\r\n"
        body << %(Content-Disposition: form-data; name="data"; filename="#{filename}"\r\n)
        body << "Content-Type: application/octet-stream\r\n\r\n"
        body << file_content
        body << "\r\n--#{boundary}--\r\n"

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.open_timeout = Bot.configuration.connection_open_timeout
        http.read_timeout = Bot.configuration.connection_timeout

        request = Net::HTTP::Post.new(uri.request_uri)
        request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
        request['Authorization'] = authorization.to_s if authorization && !authorization.to_s.empty?
        request.body = body

        response = http.request(request)
        unless response.is_a?(Net::HTTPSuccess)
          raise ApiError.new(
            "Upload failed HTTP #{response.code}",
            status: response.code.to_i,
            body: { message: response.body }
          )
        end

        response.body.to_s
      end
    end
  end
end
