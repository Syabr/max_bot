# frozen_string_literal: true

module Max
  module Bot
    class Api
      # Query/body assembly for {Api} — keeps the public class thin and readable.
      module RequestBuilders
        class << self
          def combine_attachments(attachment, attachments)
            parts = []
            append_attachment_slot!(parts, attachment, :attachment)
            append_attachment_slot!(parts, attachments, :attachments)
            return if parts.empty?

            parts
          end

          def message_query(chat_id:, user_id:, disable_link_preview:)
            q = {}
            q[:chat_id] = chat_id unless chat_id.nil?
            q[:user_id] = user_id unless user_id.nil?
            q[:disable_link_preview] = disable_link_preview unless disable_link_preview.nil?
            q
          end

          def message_body(text:, attachments:, format:, notify:, link:)
            body = {}
            body[:text] = text unless text.nil?
            body[:attachments] = attachments unless attachments.nil?
            body[:format] = format if format
            body[:notify] = notify unless notify.nil?
            body[:link] = link unless link.nil?
            body
          end

          def updates_query(marker:, limit:, timeout:, types:)
            query = {}
            query[:marker] = marker unless marker.nil?
            query[:limit] = limit unless limit.nil?
            query[:timeout] = timeout unless timeout.nil?
            if types
              list = Array(types).compact
              query[:types] = list.join(',') unless list.empty?
            end
            query
          end

          def subscription_body(url:, update_types:, secret:)
            body = { url: url }
            body[:update_types] = update_types if update_types
            body[:secret] = secret if secret
            body
          end

          def chats_query(count:, marker:)
            query = {}
            query[:count] = count unless count.nil?
            query[:marker] = marker unless marker.nil?
            query
          end

          def media_attachment_from_upload(type, data)
            t = type.to_s
            payload = {}
            payload[:token] = data[:token] if data.key?(:token)
            payload[:url] = data[:url] if data.key?(:url)
            payload[:photos] = data[:photos] if data.key?(:photos)

            case t
            when 'image' then Attachments.image(**payload)
            when 'video' then Attachments.video(**payload)
            when 'audio' then Attachments.audio(**payload)
            when 'file' then Attachments.file(**payload)
            else
              raise ArgumentError, "unsupported media type: #{type}"
            end
          end

          private

          def append_attachment_slot!(parts, value, role)
            case value
            when Array
              parts.concat(value)
            when Hash
              parts << value
            when nil
              # skip
            else
              label = role == :attachment ? 'attachment:' : 'attachments:'
              raise ArgumentError, "#{label} must be a Hash or Array of Hash"
            end
          end
        end
      end
    end
  end
end
