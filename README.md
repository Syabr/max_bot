# max_bot

Ruby-клиент для Bot API мессенджера **[MAX](https://dev.max.ru/docs-api)**: отправка сообщений, получение обновлений через **long polling** или **HTTPS-вебхуки**, список групповых чатов.

Официальная документация API: [dev.max.ru/docs-api](https://dev.max.ru/docs-api).

История изменений: [CHANGELOG.md](CHANGELOG.md) (английский и русский).

## Требования

- Ruby **≥ 2.5**
- Токен бота в кабинете MAX (**Чат-боты → Интеграция → Получить токен**)

## Установка

В `Gemfile`:

```ruby
gem 'max_bot', '~> 0.2'
```

Локально из этого репозитория:

```bash
bundle install
```

## Настройка

По желанию: таймауты и адаптер Faraday.

```ruby
require 'max_bot'

Max::Bot.configure do |config|
  config.connection_timeout       = 95   # секунды (должно быть > long-poll timeout)
  config.connection_open_timeout  = 20
  config.adapter                  = Faraday.default_adapter
end
```

Для `GET /updates` таймаут чтения HTTP должен быть **больше**, чем параметр long polling `timeout` (в `Max::Bot::Client` по умолчанию **30** секунд).

## Запуск бота (long polling)

Long polling рассчитан на **разработку и тесты**. Для продакшена MAX рекомендует **HTTPS-вебхуки** ([POST /subscriptions](https://dev.max.ru/docs-api/methods/POST/subscriptions)).

1. Задайте токен:

   ```bash
   export MAX_BOT_TOKEN="ваш_токен"
   ```

2. Из корня репозитория:

   ```bash
   bundle exec ruby examples/polling_bot.rb
   ```

Пример делает long polling `GET /updates` с `types: %w[message_created]`, разбирает апдейты через `Max::Bot::UpdateHelpers` и отвечает эхом (`POST /messages`).

### Минимальный цикл polling в своём коде

```ruby
require 'max_bot'

api = Max::Bot::Api.new(ENV.fetch('MAX_BOT_TOKEN'))

Max::Bot::Client.new(
  api.token,
  timeout: 30,
  limit: 100,
  types: %w[message_created],
  error_backoff: 5,
  logger: Logger.new($stdout) # по желанию
).run do |update|
  # update — Hash с символичными ключами (объект Update)
  next unless Max::Bot::UpdateHelpers.message_created?(update)

  message = Max::Bot::UpdateHelpers.message_from(update)
  text    = Max::Bot::UpdateHelpers.message_text(message)
  dest    = Max::Bot::UpdateHelpers.message_destination(message)
  next if text.to_s.empty? || dest.nil?

  kind, id = dest # :chat_id или :user_id
  api.send_message("Вы написали: #{text}", kind => id)
end
```

**Через метод класса:**

```ruby
Max::Bot::Client.run(ENV.fetch('MAX_BOT_TOKEN'), timeout: 30) { |u| ... }
```

При сетевых или API-ошибках клиент **ждёт** `error_backoff` (по умолчанию **3** с) и **повторяет** запрос. `Interrupt` (Ctrl+C) прерывает цикл. Вместо `logger` можно передать **`on_error: ->(e) { ... }`**.

## Отправка сообщений

```ruby
api = Max::Bot::Api.new(ENV.fetch('MAX_BOT_TOKEN'))

# Группа / канал
api.send_message('Привет', chat_id: 123)

# Личка
api.send_message('Привет', user_id: 456)

# Markdown / HTML (см. раздел «Форматирование» в доке API)
api.send_message('_cursive_', chat_id: 123, format: 'markdown')
```

`send_message` соответствует **`POST /messages`**: в query — `chat_id` / `user_id`, в теле — JSON. Подробнее: [Отправить сообщение](https://dev.max.ru/docs-api/methods/POST/messages).

### Вложения (`Max::Bot::Attachments`)

Типизированные хелперы под API: **image**, **video**, **audio**, **file**, **sticker**, **contact**, **inline_keyboard**, **location**, **share**. Примеры клавиатуры — в [документации MAX](https://dev.max.ru/docs-api).

```ruby
api.send_message(
  'Выберите',
  chat_id: chat_id,
  attachment: Max::Bot::Attachments.inline_keyboard([
    [
      Max::Bot::Attachments.callback_button('A', 'choice_a'),
      Max::Bot::Attachments.callback_button('B', 'choice_b')
    ],
    [Max::Bot::Attachments.link_button('Документация', 'https://dev.max.ru/docs-api')]
  ])
)

api.send_message(
  'Тут',
  user_id: user_id,
  attachments: [
    Max::Bot::Attachments.location(latitude: 55.75, longitude: 37.61),
    Max::Bot::Attachments.share(url: 'https://example.com/article')
  ]
)

api.send_message('Стикер', chat_id: cid, attachment: Max::Bot::Attachments.sticker(code: 'код_стикера'))
```

Можно передать **`attachment:`** (один Hash или массив) и/или **`attachments:`** — порядок сохраняется.

### Загрузка медиа (`POST /uploads`)

Для **image**, **video**, **audio**, **file**: слот загрузки → `multipart/form-data` на выданный URL → в сообщении использовать **token** из ответа. См. [Загрузка файлов](https://dev.max.ru/docs-api/methods/POST/uploads).

```ruby
# Низкоуровнево
slot = api.create_upload(type: :video) # => { url: "https://..." } и др. поля
meta = api.upload_file(type: :video, path: '/path/to/clip.mp4')
api.send_message('Видео', chat_id: id, attachment: Max::Bot::Attachments.video(token: meta[:token]))

# Одной строкой
api.send_media(type: :image, path: '/path/to/photo.jpg', text: 'Фото', chat_id: id)
```

После загрузки больших файлов перед `POST /messages` может понадобиться пауза (в доке — ошибка **attachment.not.ready**).

## Вебхуки (продакшен)

1. Поднимите **HTTPS**-endpoint (порт **443**, валидная цепочка TLS — см. требования MAX).

2. Подписка:

   ```ruby
   api.set_webhook(
     url: 'https://your.domain/max/webhook',
     update_types: %w[message_created bot_started],
     secret: 'your_secret' # по желанию, 5–256 символов [a-zA-Z0-9_-]
   )
   ```

3. В веб-приложении проверьте секретный заголовок и разберите JSON:

   ```ruby
   require 'max_bot'

   secret = ENV.fetch('WEBHOOK_SECRET')
   header = Max::Bot::Webhook.extract_secret_header(env) # Rack env
   halt 401 unless Max::Bot::Webhook.secret_valid?(header, secret)

   update = Max::Bot::Webhook.parse_json(request_body)
   # обработка update (тот же формат, что и при long polling)
   ```

Заголовок: **`X-Max-Bot-Api-Secret`**. Подробнее: [Подписка на обновления](https://dev.max.ru/docs-api/methods/POST/subscriptions).

4. Отключение вебхука (снова доступен long polling):

   ```ruby
   api.delete_webhook('https://your.domain/max/webhook')
   ```

## Другие методы API

| Метод | HTTP |
|--------|------|
| `api.chats` | [GET /chats](https://dev.max.ru/docs-api/methods/GET/chats) |
| `api.subscriptions` | [GET /subscriptions](https://dev.max.ru/docs-api/methods/GET/subscriptions) |

## Ошибки

Неуспешные HTTP-ответы вызывают **`Max::Bot::ApiError`**: `#status`, `#body` (Hash с символичными ключами, если пришёл JSON).

## Структура библиотеки

Типичный layout RubyGem: файл гема совпадает с именем, код — в `lib/max/bot/`.

| Путь | Назначение |
|------|------------|
| `lib/max_bot.rb` | `require "max_bot"` → подключает `max/bot` |
| `lib/max/bot.rb` | Загрузка зависимостей, `Max::Bot.configure` |
| `lib/max/bot/api.rb` | Публичные методы Bot API |
| `lib/max/bot/api/request_builders.rb` | Сборка query/body для {Api} |
| `lib/max/bot/http.rb` | Faraday, JSON-тело, заголовок `Authorization` |
| `lib/max/bot/json.rb` | Разбор ответа, `deep_symbolize` |
| `lib/max/bot/attachments.rb` | Билдеры вложений и клавиатуры |
| `lib/max/bot/multipart_upload.rb` | Multipart-загрузка на CDN-URL |
| `lib/max/bot/client.rb` | Цикл long polling `GET /updates` |

Для кастомного транспорта или стабов можно подставить объект как **`Max::Bot::Http`**:

```ruby
api = Max::Bot::Api.new(token, http: my_http_client)
```

В тестах: **`Max::Bot::Client.new(..., api: fake_api, sleep: ->(_) {})`** — без реального `sleep` и с подменённым API.

## Разработка

```bash
bundle install
bundle exec rake test    # задача по умолчанию
gem build max_bot.gemspec
```

## Лицензия

MIT — см. [LICENSE.txt](LICENSE.txt).
