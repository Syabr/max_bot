# frozen_string_literal: true

module Max
  module Bot
    # Convenience parsers aligned with the public MAX Bot API object shapes
    # (Update → message → body / recipient). Field names may evolve — treat as best-effort.
    module UpdateHelpers
      module_function

      def message_created?(update)
        update.is_a?(Hash) && update[:update_type].to_s == 'message_created'
      end

      def message_from(update)
        return unless update.is_a?(Hash)

        update[:message]
      end

      def message_text(message)
        return unless message.is_a?(Hash)

        case message[:body]
        in Hash => body
          body[:text] || body[:markdown]
        in String => body
          body
        end
      end

      # Returns either [:chat_id, id] or [:user_id, id] for send_message kwargs.
      # Supports:
      # - message_created payloads: { recipient: { chat_id/user_id } }
      # - bot_started payloads: { chat_id/user_id } (top-level update fields)
      def message_destination(payload)
        return unless payload.is_a?(Hash)

        recipient = payload[:recipient]
        source = recipient.is_a?(Hash) ? recipient : payload

        if source.key?(:chat_id) && !source[:chat_id].nil?
          [:chat_id, source[:chat_id]]
        elsif source.key?(:user_id) && !source[:user_id].nil?
          [:user_id, source[:user_id]]
        end
      end
    end
  end
end
