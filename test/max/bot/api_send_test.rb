# frozen_string_literal: true

require 'test_helper'
require 'faraday'

module Max
  module Bot
    class RecordingHttp
      attr_reader :posts, :gets, :deletes

      def initialize
        @posts = []
        @gets = []
        @deletes = []
      end

      def post(path, query: nil, body: nil)
        @posts << { path: path, query: query, body: body }
        { ok: true }
      end

      def get(path, query: {})
        @gets << { path: path, query: query }
        { updates: [] }
      end

      def delete(path, query: nil)
        @deletes << { path: path, query: query }
        { success: true }
      end
    end

    class ApiSendTest < Minitest::Test
      def test_send_message_merges_attachment_and_attachments
        rec = RecordingHttp.new
        api = Api.new('token', http: rec)

        api.send_message(
          'Hello',
          chat_id: 10,
          attachment: Attachments.sticker(code: 'smile'),
          attachments: [Attachments.share(url: 'https://a.example')]
        )

        atts = rec.posts.first[:body][:attachments]
        assert_equal 2, atts.size
        assert_equal 'sticker', atts[0][:type]
        assert_equal 'share', atts[1][:type]
        assert_equal 10, rec.posts.first[:query][:chat_id]
      end

      def test_get_updates_forwards_query
        rec = RecordingHttp.new
        api = Api.new('tok', http: rec)
        api.get_updates(marker: 7, limit: 50, timeout: 15, types: %w[message_created])

        q = rec.gets.first[:query]
        assert_equal 7, q[:marker]
        assert_equal 50, q[:limit]
        assert_equal 15, q[:timeout]
        assert_equal 'message_created', q[:types]
      end

      def test_set_webhook_json_body
        rec = RecordingHttp.new
        api = Api.new('tok', http: rec)
        api.set_webhook(url: 'https://hook', update_types: %w[a], secret: 'sec')

        body = rec.posts.first[:body]
        assert_equal 'https://hook', body[:url]
        assert_equal %w[a], body[:update_types]
        assert_equal 'sec', body[:secret]
      end

      def test_delete_webhook_query
        rec = RecordingHttp.new
        api = Api.new('tok', http: rec)
        api.delete_webhook('https://hook')

        assert_equal({ url: 'https://hook' }, rec.deletes.first[:query])
      end

      def test_chats_query
        rec = RecordingHttp.new
        api = Api.new('tok', http: rec)
        api.chats(count: 25, marker: 3)

        assert_equal({ count: 25, marker: 3 }, rec.gets.first[:query])
      end

      def test_create_upload_posts_type
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post('/uploads') do |env|
            assert_equal 'image', env.params['type']
            [200, { 'Content-Type' => 'application/json' }, '{"url":"https://cdn.example/up"}']
          end
        end

        conn = Faraday.new do |f|
          f.adapter :test, stubs
        end

        http = Http.new('tok', 'https://platform-api.max.ru', connection: conn)
        api = Api.new('tok', http: http)

        result = api.create_upload(type: :image)
        assert_equal 'https://cdn.example/up', result[:url]
        stubs.verify_stubbed_calls
      end

      def test_create_upload_rejects_unknown_type
        api = Api.new('tok', http: RecordingHttp.new)
        assert_raises(ArgumentError) { api.create_upload(type: :photo) }
      end

      def test_upload_file_raises_when_slot_has_no_url
        api = Api.new('tok', http: RecordingHttp.new)

        def api.create_upload(*)
          { token: 'only' }
        end

        err = assert_raises(ApiError) { api.upload_file(type: :image, path: __FILE__) }
        assert_match(/url/i, err.message)
      end
    end
  end
end
