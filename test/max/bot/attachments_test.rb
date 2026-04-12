# frozen_string_literal: true

require 'test_helper'

module Max
  module Bot
    class AttachmentsTest < Minitest::Test
      def test_image_with_token
        att = Attachments.image(token: 'abc')
        assert_equal 'image', att[:type]
        assert_equal({ token: 'abc' }, att[:payload])
      end

      def test_inline_keyboard_structure
        rows = [
          [
            Attachments.callback_button('OK', 'payload-1', intent: 'positive'),
            Attachments.link_button('Site', 'https://example.com')
          ]
        ]
        att = Attachments.inline_keyboard(rows)
        assert_equal 'inline_keyboard', att[:type]
        assert_equal rows, att[:payload][:buttons]
      end

      def test_location_top_level_coordinates
        att = Attachments.location(latitude: 55.75, longitude: 37.61)
        assert_equal 'location', att[:type]
        assert_in_delta 55.75, att[:latitude]
        assert_in_delta 37.61, att[:longitude]
      end

      def test_share_payload
        att = Attachments.share(url: 'https://example.com')
        assert_equal 'share', att[:type]
        assert_equal 'https://example.com', att[:payload][:url]
      end
    end
  end
end
