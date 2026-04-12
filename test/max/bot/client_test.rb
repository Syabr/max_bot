# frozen_string_literal: true

require 'test_helper'

module Max
  module Bot
    class ClientTest < Minitest::Test
      class DummyApi
        attr_reader :get_updates_calls

        def initialize(responses)
          @responses = responses.dup
          @get_updates_calls = []
        end

        def get_updates(**kwargs)
          @get_updates_calls << kwargs
          @responses.shift || { updates: [], marker: nil }
        end
      end

      def test_initialize_accepts_injected_api
        dummy = DummyApi.new([])
        client = Client.new('token', api: dummy)
        assert_same dummy, client.api
      end

      def test_run_requires_block
        client = Client.new('token', api: DummyApi.new([]))
        err = assert_raises(ArgumentError) { client.run }
        assert_match(/block/, err.message)
      end

      def test_class_run_requires_block
        assert_raises(ArgumentError) { Client.run('token') }
      end

      def test_run_yields_updates_and_passes_marker_on_next_poll
        responses = [
          { updates: [{ id: 1 }], marker: 10 },
          { updates: [{ id: 2 }], marker: 20 }
        ]
        dummy = DummyApi.new(responses)
        seen = []
        client = Client.new('token', api: dummy, sleep: ->(_) {})

        client.run do |u|
          seen << u
          raise StopIteration if seen.size >= 2
        end

        assert_equal 2, seen.size
        assert_equal({ id: 1 }, seen[0])
        assert_equal({ id: 2 }, seen[1])
        assert_nil dummy.get_updates_calls[0][:marker]
        assert_equal 10, dummy.get_updates_calls[1][:marker]
      end
    end
  end
end
