# frozen_string_literal: true

require 'test_helper'

module Max
  module Bot
    class ApiRequestBuildersTest < Minitest::Test
      def test_combine_attachments_order
        a = { type: 'share', payload: { url: 'https://a' } }
        b = { type: 'image', payload: { token: 't' } }
        out = Api::RequestBuilders.combine_attachments(a, [b])
        assert_equal(%w[share image], out.map { |h| h[:type] })
      end

      def test_combine_attachments_rejects_invalid_attachment
        err = assert_raises(ArgumentError) do
          Api::RequestBuilders.combine_attachments('bad', nil)
        end
        assert_match(/attachment:/, err.message)
      end

      def test_updates_query_types_csv
        q = Api::RequestBuilders.updates_query(marker: 5, limit: 10, timeout: 20, types: %w[a b])
        assert_equal 5, q[:marker]
        assert_equal 10, q[:limit]
        assert_equal 20, q[:timeout]
        assert_equal 'a,b', q[:types]
      end

      def test_updates_query_omits_empty_types
        q = Api::RequestBuilders.updates_query(marker: nil, limit: nil, timeout: nil, types: [])
        refute q.key?(:types)
      end

      def test_subscription_body_optional_fields
        b = Api::RequestBuilders.subscription_body(url: 'https://x', update_types: %w[a], secret: 's')
        assert_equal 'https://x', b[:url]
        assert_equal %w[a], b[:update_types]
        assert_equal 's', b[:secret]
      end

      def test_media_attachment_from_upload_image
        att = Api::RequestBuilders.media_attachment_from_upload(:image, token: 'tok', url: 'https://u')
        assert_equal 'image', att[:type]
        assert_equal 'tok', att[:payload][:token]
        assert_equal 'https://u', att[:payload][:url]
      end

      def test_media_attachment_unknown_type
        assert_raises(ArgumentError) do
          Api::RequestBuilders.media_attachment_from_upload(:unknown, token: 'x')
        end
      end

      def test_callback_body
        b = Api::RequestBuilders.callback_body(
          callback_query_id: 'cb_123',
          text: 'Done',
          show_alert: true,
          url: nil
        )
        assert_equal 'cb_123', b[:callback_query_id]
        assert_equal 'Done', b[:text]
        assert b[:show_alert]
        refute b.key?(:url)
      end

      def test_callback_body_minimal
        b = Api::RequestBuilders.callback_body(callback_query_id: 'cb', text: nil, show_alert: nil, url: nil)
        assert_equal 'cb', b[:callback_query_id]
        refute b.key?(:text)
        refute b.key?(:show_alert)
        refute b.key?(:url)
      end
    end
  end
end
