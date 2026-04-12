# frozen_string_literal: true

require 'test_helper'

module Max
  module Bot
    class MultipartUploadTest < Minitest::Test
      def setup
        @temp_dir = Dir.mktmpdir
        @test_file_path = File.join(@temp_dir, 'test.bin')
        File.binwrite(@test_file_path, 'test content')
      end

      def teardown
        FileUtils.remove_entry(@temp_dir)
      end

      def test_rejects_blank_upload_url
        assert_raises(ArgumentError) do
          MultipartUpload.post_file(upload_url: '', path: @test_file_path, authorization: 'tok')
        end
        assert_raises(ArgumentError) do
          MultipartUpload.post_file(upload_url: '   ', path: @test_file_path, authorization: 'tok')
        end
      end

      def test_raises_error_for_non_http_url
        # URI.parse('not-a-url') returns URI::Generic which lacks request_uri
        assert_raises(NoMethodError) do
          MultipartUpload.post_file(upload_url: 'not-a-url', path: @test_file_path, authorization: 'tok')
        end
      end

      def test_raises_api_error_on_connection_failure
        # Unresolvable host should raise a network error, wrapped in ApiError by caller
        err = assert_raises(Errno::ECONNREFUSED, SocketError, Errno::ENETUNREACH) do
          MultipartUpload.post_file(
            upload_url: 'http://127.0.0.1:1',
            path: @test_file_path,
            authorization: 'tok'
          )
        end
        assert_kind_of StandardError, err
      end
    end
  end
end
