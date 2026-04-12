# Changelog

## 0.2.0

Changes in **0.2.0** compared to **0.1.1** are described below in **English** and **Russian**.

### English

#### API client & HTTP

- Modular stack: `Max::Bot::Http` (Faraday) and `Max::Bot::Json` for JSON parsing and `deep_symbolize`.
- `Max::Bot::Api`: messages (`POST /messages`), long polling (`GET /updates`), subscriptions & webhooks (`GET` / `POST` / `DELETE /subscriptions`), chats (`GET /chats`), uploads (`POST /uploads` + multipart upload to the returned URL).
- `Authorization` header on requests; JSON body for `POST /messages` without conflicting `url_encoded` middleware.
- Optional `http:` injection into `Api.new` for tests and stubs.
- HTTP failures: `Max::Bot::ApiError` (`#status`, `#body`, richer `#to_s` when the body includes `message`).

#### Messages & attachments

- `send_message` with `chat_id` / `user_id`, `format`, `notify`, `link`, `disable_link_preview`.
- `attachment:` (single Hash or Array) and `attachments:`; merged into one list in order.
- `Max::Bot::Attachments`: `image`, `video`, `audio`, `file`, `sticker`, `contact`, `inline_keyboard` / `keyboard`, `location`, `share`, button helpers (`callback_button`, `link_button`, etc.), `raw`.
- `create_upload`, `upload_file`, `send_media` for media per [upload docs](https://dev.max.ru/docs-api/methods/POST/uploads).
- `Max::Bot::MultipartUpload`: `multipart/form-data` via stdlib `Net::HTTP`.

#### Long polling & webhooks

- `Max::Bot::Client`: `GET /updates` loop, marker, `types` / `limit` / `timeout`, retries on errors (`error_backoff`, `on_error`, `logger`), re-raises `Interrupt`.
- `Max::Bot::Webhook`: `X-Max-Bot-Api-Secret` header, JSON body parsing.
- `Max::Bot::UpdateHelpers`: `message_created`, message text, recipient (`chat_id` / `user_id`).

#### Gem infrastructure

- Entrypoint `require "max_bot"` → `lib/max/bot.rb`; `Max::Bot.configure` (Faraday timeouts, adapter).
- Minitest, default `rake test`, `LICENSE.txt`, `.gitignore`, `examples/polling_bot.rb`.
- Documentation: `README.md` (Russian), this changelog in English and Russian.

---

### Русский

#### Клиент API и HTTP

- Модульный клиент: `Max::Bot::Http` (Faraday), разбор ответов в `Max::Bot::Json` (JSON + `deep_symbolize`).
- `Max::Bot::Api`: сообщения (`POST /messages`), long polling (`GET /updates`), подписки и вебхук (`GET`/`POST`/`DELETE /subscriptions`), чаты (`GET /chats`), загрузки (`POST /uploads` + multipart на выданный URL).
- Заголовок `Authorization` для запросов; JSON-тело для `POST /messages` без конфликта с `url_encoded`.
- Опциональная инъекция `http:` в `Api.new` для тестов и стабов.
- Ошибки HTTP: `Max::Bot::ApiError` (`#status`, `#body`, расширенный `#to_s` при поле `message` в теле).

#### Сообщения и вложения

- `send_message` с `chat_id` / `user_id`, `format`, `notify`, `link`, `disable_link_preview`.
- Параметры `attachment:` (один хэш или массив) и `attachments:`; склейка в один массив.
- Модуль `Max::Bot::Attachments`: `image`, `video`, `audio`, `file`, `sticker`, `contact`, `inline_keyboard` / `keyboard`, `location`, `share`, кнопки (`callback_button`, `link_button`, и др.), `raw`.
- `create_upload`, `upload_file`, `send_media` для медиа по [документации загрузок](https://dev.max.ru/docs-api/methods/POST/uploads).
- `Max::Bot::MultipartUpload` — загрузка `multipart/form-data` через stdlib `Net::HTTP`.

#### Long polling и вебхуки

- `Max::Bot::Client`: цикл `GET /updates`, маркер, `types` / `limit` / `timeout`, повтор при ошибках (`error_backoff`, `on_error`, `logger`), проброс `Interrupt`.
- `Max::Bot::Webhook`: заголовок `X-Max-Bot-Api-Secret`, разбор JSON тела.
- `Max::Bot::UpdateHelpers`: разбор `message_created`, текста и адресата из входящих апдейтов.

#### Инфраструктура гема

- Точка входа `require "max_bot"` → `lib/max/bot.rb`; конфигурация `Max::Bot.configure` (таймауты Faraday, адаптер).
- Minitest, `rake test` по умолчанию, `LICENSE.txt`, `.gitignore`, пример `examples/polling_bot.rb`.
- Документация: `README.md` (русский), этот changelog — на английском и русском.
