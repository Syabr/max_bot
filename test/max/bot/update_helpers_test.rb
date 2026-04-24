# frozen_string_literal: true

require 'test_helper'

module Max
  module Bot
    class UpdateHelpersTest < Minitest::Test
      def test_message_created_predicate
        assert UpdateHelpers.message_created?(update_type: 'message_created')
        refute UpdateHelpers.message_created?(update_type: 'other')
      end

      def test_message_text_from_body_hash
        msg = { body: { text: 'hello' } }
        assert_equal 'hello', UpdateHelpers.message_text(msg)
      end

      def test_message_destination_chat_id
        msg = { recipient: { chat_id: -100 } }
        assert_equal [:chat_id, -100], UpdateHelpers.message_destination(msg)
      end

      def test_message_destination_user_id_fallback
        msg = { recipient: { user_id: 42 } }
        assert_equal [:user_id, 42], UpdateHelpers.message_destination(msg)
      end

      def test_message_destination_from_bot_started_update_chat_id
        update = { update_type: 'bot_started', chat_id: 65823140, user_id: 223440644 }
        assert_equal [:chat_id, 65823140], UpdateHelpers.message_destination(update)
      end

      def test_message_destination_from_bot_started_update_user_id
        update = { update_type: 'bot_started', user_id: 223440644 }
        assert_equal [:user_id, 223440644], UpdateHelpers.message_destination(update)
      end
    end
  end
end
