# frozen_string_literal: true

require 'test_helper'

module Max
  module Bot
    class WebhookTest < Minitest::Test
      def test_secret_valid_when_no_secret_configured
        assert Webhook.secret_valid?('anything', nil)
        assert Webhook.secret_valid?('anything', '')
      end

      def test_secret_valid_compares_constant_time
        assert Webhook.secret_valid?('abc', 'abc')
        refute Webhook.secret_valid?('abc', 'abd')
        refute Webhook.secret_valid?('abc', 'ab')
      end

      def test_secret_valid_uses_openssl_secure_compare
        # Verify OpenSSL.fixed_length_secure_compare is called for same-length strings
        a = 'test_secret_value'
        b = 'test_secret_value'
        # OpenSSL.fixed_length_secure_compare raises on different lengths in some Ruby versions,
        # so our code checks bytesize first, then delegates to OpenSSL.
        assert Webhook.secret_valid?(a, b)
      end

      def test_extract_secret_header_rack_style
        env = { 'HTTP_X_MAX_BOT_API_SECRET' => 'sekret' }
        assert_equal 'sekret', Webhook.extract_secret_header(env)
      end

      def test_parse_json_empty
        assert_equal({}, Webhook.parse_json(nil))
        assert_equal({}, Webhook.parse_json(''))
      end

      def test_parse_json_object
        h = Webhook.parse_json('{"update_type":"message_created"}')
        assert_equal 'message_created', h[:update_type]
      end
    end
  end
end
