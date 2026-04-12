# frozen_string_literal: true

require 'uri'

module Max
  module Bot
    # HTTP facade for the MAX Bot API (+platform-api.max.ru+).
    #
    # @see https://dev.max.ru/docs-api
    class Api
      DEFAULT_URL = 'https://platform-api.max.ru'

      UPLOAD_TYPES = %w[image video audio file].freeze

      attr_reader :token, :base_url, :http

      def initialize(token, url: DEFAULT_URL, http: nil)
        raise ArgumentError, 'token must be a non-empty String' if token.nil? || token.to_s.strip.empty?

        @token = token.to_s
        @base_url = url.to_s.chomp('/')
        @http = http || Http.new(@token, @base_url)
      end

      # --- Messages -------------------------------------------------

      # POST /messages — https://dev.max.ru/docs-api/methods/POST/messages
      def send_message(text = nil, chat_id: nil, user_id: nil, attachment: nil, attachments: nil, format: nil,
                       notify: nil, disable_link_preview: nil, link: nil)
        assert_recipient!(chat_id, user_id)

        combined = RequestBuilders.combine_attachments(attachment, attachments)
        assert_message_payload!(text, combined, link)

        http.post(
          '/messages',
          query: RequestBuilders.message_query(
            chat_id: chat_id,
            user_id: user_id,
            disable_link_preview: disable_link_preview
          ),
          body: RequestBuilders.message_body(
            text: text,
            attachments: combined,
            format: format,
            notify: notify,
            link: link
          )
        )
      end

      # POST /uploads — https://dev.max.ru/docs-api/methods/POST/uploads
      def create_upload(type:)
        t = normalize_upload_type!(type)
        http.post('/uploads', query: { type: t })
      end

      def upload_file(type:, path:, filename: nil)
        slot = create_upload(type: type)
        upload_url = slot[:url]
        if upload_url.nil? || upload_url.to_s.empty?
          raise ApiError.new('Upload response missing url', body: slot)
        end

        raw = MultipartUpload.post_file(
          upload_url: upload_url,
          path: path,
          filename: filename,
          authorization: token
        )

        parse_upload_response(raw).merge(slot)
      end

      # Uploads local file then POST /messages with the resulting attachment.
      def send_media(type:, path:, text: nil, filename: nil, chat_id: nil, user_id: nil, **message_opts)
        data = upload_file(type: type, path: path, filename: filename)
        att = RequestBuilders.media_attachment_from_upload(type, data)

        send_message(
          text,
          chat_id: chat_id,
          user_id: user_id,
          attachment: att,
          **message_opts
        )
      end

      # --- Updates & subscriptions ------------------------------------

      # GET /updates — https://dev.max.ru/docs-api/methods/GET/updates
      def get_updates(marker: nil, limit: nil, timeout: nil, types: nil)
        query = RequestBuilders.updates_query(marker: marker, limit: limit, timeout: timeout, types: types)
        http.get('/updates', query: query)
      end

      # GET /subscriptions
      def subscriptions
        http.get('/subscriptions')
      end

      # POST /subscriptions — https://dev.max.ru/docs-api/methods/POST/subscriptions
      def set_webhook(url:, update_types: nil, secret: nil)
        assert_valid_url!(url, 'set_webhook url')
        body = RequestBuilders.subscription_body(url: url, update_types: update_types, secret: secret)
        http.post('/subscriptions', body: body)
      end

      # DELETE /subscriptions — https://dev.max.ru/docs-api/methods/DELETE/subscriptions
      def delete_webhook(webhook_url)
        http.delete('/subscriptions', query: { url: webhook_url })
      end

      # --- Chats ----------------------------------------------------

      # GET /chats — https://dev.max.ru/docs-api/methods/GET/chats
      def chats(count: nil, marker: nil)
        query = RequestBuilders.chats_query(count: count, marker: marker)
        http.get('/chats', query: query)
      end

      # GET /chats/{chatId} — https://dev.max.ru/docs-api/methods/GET/chats/{chatId}
      def chat(chat_id)
        raise ArgumentError, 'chat_id must be a non-empty value' if chat_id.nil? || chat_id.to_s.strip.empty?

        http.get("/chats/#{chat_id}")
      end

      # --- Bot info -------------------------------------------------

      # GET /bots — https://dev.max.ru/docs-api/methods/GET/bots
      def me
        http.get('/bots')
      end

      # --- Message management ---------------------------------------

      # GET /messages/{messageId} — https://dev.max.ru/docs-api/methods/GET/messages/{messageId}
      def get_message(message_id)
        raise ArgumentError, 'message_id must be a non-empty value' if message_id.nil? || message_id.to_s.strip.empty?

        http.get("/messages/#{message_id}")
      end

      # PUT /messages/{messageId} — https://dev.max.ru/docs-api/methods/PUT/messages/{messageId}
      def edit_message(message_id, text = nil, attachment: nil, attachments: nil, format: nil,
                       link: nil)
        raise ArgumentError, 'message_id must be a non-empty value' if message_id.nil? || message_id.to_s.strip.empty?

        combined = RequestBuilders.combine_attachments(attachment, attachments)

        http.put(
          "/messages/#{message_id}",
          body: RequestBuilders.message_body(
            text: text,
            attachments: combined,
            format: format,
            notify: nil,
            link: link
          )
        )
      end

      # DELETE /messages/{messageId} — https://dev.max.ru/docs-api/methods/DELETE/messages/{messageId}
      def delete_message(message_id)
        raise ArgumentError, 'message_id must be a non-empty value' if message_id.nil? || message_id.to_s.strip.empty?

        http.delete("/messages/#{message_id}")
      end

      # POST /messages/callback — https://dev.max.ru/docs-api/methods/POST/messages/callback
      def answer_callback(callback_query_id, text: nil, show_alert: nil, url: nil)
        raise ArgumentError, 'callback_query_id must be a non-empty value' if callback_query_id.nil? || callback_query_id.to_s.strip.empty?

        http.post(
          '/messages/callback',
          body: RequestBuilders.callback_body(
            callback_query_id: callback_query_id,
            text: text,
            show_alert: show_alert,
            url: url
          )
        )
      end

      private

      def assert_recipient!(chat_id, user_id)
        return unless chat_id.nil? && user_id.nil?

        raise ArgumentError, 'send_message requires chat_id: or user_id:'
      end

      def assert_message_payload!(text, combined_attachments, link)
        return unless text.nil? && combined_attachments.nil? && link.nil?

        raise ArgumentError, 'send_message requires at least one of: text, attachments, attachment, link'
      end

      def assert_valid_url!(value, label)
        uri = URI.parse(value.to_s)
        unless uri.is_a?(URI::HTTP) && uri.host && !uri.host.empty?
          raise ArgumentError, "#{label} must be a valid HTTP(S) URL"
        end
      end

      def normalize_upload_type!(type)
        t = type.to_s
        unless UPLOAD_TYPES.include?(t)
          raise ArgumentError, "upload type must be one of #{UPLOAD_TYPES.join(', ')}"
        end

        t
      end

      def parse_upload_response(raw)
        stripped = raw.to_s.strip
        return {} if stripped.empty?

        ::JSON.parse(stripped, symbolize_names: true)
      end
    end
  end
end
