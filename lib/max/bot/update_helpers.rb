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

        body = message[:body]
        case body
        when Hash
          body[:text] || body[:markdown]
        when String
          body
        end
      end

      # Returns either [:chat_id, id] or [:user_id, id] for send_message kwargs.
      def message_destination(message)
        return unless message.is_a?(Hash)

        recipient = message[:recipient]
        return unless recipient.is_a?(Hash)

        if recipient.key?(:chat_id) && !recipient[:chat_id].nil?
          [:chat_id, recipient[:chat_id]]
        elsif recipient.key?(:user_id) && !recipient[:user_id].nil?
          [:user_id, recipient[:user_id]]
        end
      end
    end
  end
end
