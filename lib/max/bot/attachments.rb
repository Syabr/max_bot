# frozen_string_literal: true

module Max
  module Bot
    # Builders for +attachments+ in +POST /messages+ (NewMessageBody).
    # Types follow the MAX Bot API: image, video, audio, file, sticker, contact,
    # inline_keyboard, location, share.
    #
    # @see https://dev.max.ru/docs-api/methods/POST/messages
    # @see https://dev.max.ru/docs-api/objects/NewMessageBody
    module Attachments
      module_function

      def prune(hash)
        hash.compact
      end

      # --- Media (usually +token+ from +POST /uploads+ flow) ---

      def image(token: nil, url: nil, photos: nil)
        { type: 'image', payload: prune(token: token, url: url, photos: photos) }
      end

      def video(token: nil)
        { type: 'video', payload: prune(token: token) }
      end

      def audio(token: nil)
        { type: 'audio', payload: prune(token: token) }
      end

      def file(token: nil)
        { type: 'file', payload: prune(token: token) }
      end

      def sticker(code:)
        { type: 'sticker', payload: prune(code: code) }
      end

      def contact(name:, contact_id: nil, vcf_info: nil, vcf_phone: nil)
        {
          type: 'contact',
          payload: prune(
            name: name,
            contact_id: contact_id,
            vcf_info: vcf_info,
            vcf_phone: vcf_phone
          )
        }
      end

      # +rows+ is an Array of rows; each row is an Array of button Hashes (see +callback_button+, +link_button+, …).
      def inline_keyboard(rows)
        { type: 'inline_keyboard', payload: { buttons: rows } }
      end
      alias keyboard inline_keyboard

      # Per client typings, latitude/longitude sit on the attachment object (not under +payload+).
      def location(latitude:, longitude:)
        { type: 'location', latitude: latitude, longitude: longitude }
      end

      def share(url: nil, **payload_rest)
        { type: 'share', payload: prune({ url: url }.merge(payload_rest)) }
      end

      # --- Inline keyboard buttons (https://dev.max.ru/docs-api keyboard section) ---

      def callback_button(text, payload, intent: nil)
        prune(type: 'callback', text: text, payload: payload, intent: intent)
      end

      def link_button(text, url)
        { type: 'link', text: text, url: url }
      end

      def request_contact_button(text)
        { type: 'request_contact', text: text }
      end

      def request_geo_location_button(text, quick: nil)
        prune(type: 'request_geo_location', text: text, quick: quick)
      end

      # Some integrations use +chat+ for deep-link style buttons; pass API fields you need.
      def chat_button(text, chat_title:, chat_description: nil, start_payload: nil, uuid: nil)
        prune(
          type: 'chat',
          text: text,
          chat_title: chat_title,
          chat_description: chat_description,
          start_payload: start_payload,
          uuid: uuid
        )
      end

      def message_button(text, payload: nil)
        prune(type: 'message', text: text, payload: payload)
      end

      def clipboard_button(text, payload)
        { type: 'clipboard', text: text, payload: payload }
      end

      # Escape hatch for new API button/attachment shapes.
      def raw(type:, payload: nil, **top_level)
        h = { type: type }
        h[:payload] = payload unless payload.nil?
        prune(h.merge(top_level))
      end
    end
  end
end
