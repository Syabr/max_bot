# Changelog

## 0.3.0

Changes in **0.3.0** compared to **0.2.0** are described below in **English** and **Russian**.

### English

#### New API methods

- `api.me` — **GET /bots**: get bot info (useful for token validation).
- `api.chat(chat_id)` — **GET /chats/{chatId}**: get group chat information.
- `api.get_message(message_id)` — **GET /messages/{messageId}**: get a specific message.
- `api.edit_message(message_id, text, ...)` — **PUT /messages/{messageId}**: edit a message (supports text, attachments, format, link).
- `api.delete_message(message_id)` — **DELETE /messages/{messageId}**: delete a message.
- `api.answer_callback(callback_query_id, ...)` — **POST /messages/callback**: reply to a callback query from inline keyboard buttons (supports `text`, `show_alert`, `url`).

#### Attachments

- `Attachments.clipboard_button(text, payload)` — new button type: **clipboard** (copies payload to clipboard on tap).

#### Improvements & fixes

- `Webhook.secret_valid?` now uses `OpenSSL.fixed_length_secure_compare` for proper constant-time comparison (was a manual XOR loop).
- `Api.set_webhook` validates that `url` is a valid HTTP(S) URL.
- `MultipartUpload` error responses now wrap the body in `{ message: ... }` so `ApiError#to_s` displays the message.
- Added `Http#put` method for `PUT` requests.
- 21 new tests (67 total, 153 assertions).

---

### Русский

#### Новые методы API

- `api.me` — **GET /bots**: информация о боте (удобно для проверки токена).
- `api.chat(chat_id)` — **GET /chats/{chatId}**: информация о групповом чате.
- `api.get_message(message_id)` — **GET /messages/{messageId}**: получить конкретное сообщение.
- `api.edit_message(message_id, text, ...)` — **PUT /messages/{messageId}**: редактировать сообщение (поддерживает текст, вложения, формат, ссылку).
- `api.delete_message(message_id)` — **DELETE /messages/{messageId}**: удалить сообщение.
- `api.answer_callback(callback_query_id, ...)` — **POST /messages/callback**: ответ на callback-запрос от inline-кнопки (поддерживает `text`, `show_alert`, `url`).

#### Вложения

- `Attachments.clipboard_button(text, payload)` — новый тип кнопки: **clipboard** (копирует payload в буфер обмена по нажатию).

#### Улучшения и исправления

- `Webhook.secret_valid?` теперь использует `OpenSSL.fixed_length_secure_compare` для корректного сравнения за постоянное время (раньше был ручной XOR-цикл).
- `Api.set_webhook` проверяет, что `url` — валидный HTTP(S) URL.
- Ошибки `MultipartUpload` теперь оборачивают тело в `{ message: ... }`, чтобы `ApiError#to_s` отображал сообщение.
- Добавлен метод `Http#put` для `PUT`-запросов.
- 21 новый тест (67 всего, 153 assertions).

---

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
