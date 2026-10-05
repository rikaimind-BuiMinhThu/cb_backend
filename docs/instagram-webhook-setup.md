# Instagram Webhook Setup Guide

This document covers Meta App Dashboard configuration required for **DM** and **post comment** webhooks to reach the chatbot server.

App ID: `921432582592605` (must match `REACT_APP_FACEBOOK_APP_ID` in frontend)

Staging webhook URL: `https://ec-chatbot-test.com/api/v1/webhook`

Verify token: value of `Settings.webhook.verify_token` in `config/settings.yml`

---

## Architecture

| Event | Meta sends | Subscribed via |
|-------|------------|----------------|
| DM | `object: instagram`, `messaging` | Page `subscribed_apps` (`messages`) + Meta Dashboard Instagram `messages` |
| Post comment | `object: instagram`, `changes[field=comments]` | Meta Dashboard Instagram `comments` only |
| Button postback | `object: instagram`, `messaging[postback]` | Page `subscribed_apps` (`messaging_postbacks`) |

On connect (`POST /api/v1/instagram_connect`), the backend calls:

```
POST /{page_id}/subscribed_apps?subscribed_fields=messages,messaging_postbacks
```

Comment fields (`comments`, `live_comments`) **cannot** be set via Page API — configure them in Meta Dashboard.

---

## Step 1: Enable permissions (Use Cases)

Meta App Dashboard → **Use cases** → **Customize** → **Permissions and features**

Set each permission to **Ready for testing**:

| Permission | Purpose |
|------------|---------|
| `pages_show_list` | List Facebook Pages |
| `pages_read_engagement` | IG API dependency |
| `pages_manage_metadata` | Call `/{page_id}/subscribed_apps` |
| `pages_messaging` | Subscribe to `messages`, `messaging_postbacks` |
| `instagram_basic` | IG profile and media |
| `instagram_manage_messages` | Send/receive IG DMs |
| `instagram_manage_comments` | Comment webhooks and replies |
| `business_management` | Business Portfolio pages |

Add use cases if missing:

- **Manage everything on your Page** → `pages_manage_metadata`
- **Engage with customers on Messenger from Meta** → `pages_messaging`

Without these, Facebook Login shows **Invalid Scopes** and Meta ignores `pages_manage_metadata` / `pages_messaging`.

---

## Step 2: Configure Webhooks

Meta App Dashboard → **Webhooks** → **Configure**

1. Callback URL: `https://ec-chatbot-test.com/api/v1/webhook`
2. Verify token: same as `config/settings.yml` → `webhook.verify_token`
3. Click **Verify and Save**

---

## Step 3: Subscribe webhook fields

### Instagram object

Subscribe:

- `comments` (post comments)
- `live_comments` (optional)
- `messages` (IG DMs)
- `messaging_postbacks`

### Page object

Subscribe (backup Messenger Platform path):

- `messages`
- `messaging_postbacks`

Click **Test** next to `comments` and `messages`. Staging logs should show:

```
POST "/api/v1/webhook"
"object" => "instagram"   (or "page")
Completed 200 OK
```

---

## Step 4: App roles

App Dashboard → **App roles**:

- Add personal test IG account as **Instagram Tester**
- Business account owner as Admin/Developer if needed

In Development mode, only testers receive full webhook behavior.

---

## Step 5: Reconnect in EC Chatbot

1. Restart frontend dev server
2. UI: **インスタグラムログアウト** (disconnect + Facebook logout)
3. **Facebookでログイン** — approve all permissions (no Invalid Scopes warning)
4. Click **選択** on the Facebook Page with linked IG account

Connect log should include `grantedScopes` with:

```
pages_manage_metadata,pages_messaging,instagram_manage_messages,instagram_manage_comments,...
```

### Verify in Rails console

```ruby
acc = InstagramAccount.find_by(ig_id: "YOUR_IG_BUSINESS_ID")
FacebookManager::GraphApiClient.new(acc.page_access_token).get("#{acc.page_id}/subscribed_apps")
# => :success => true
```

---

## Step 6: Test events

### Comment test

1. Business IG posts public content
2. Instagram Tester comments on the post
3. Expect staging log:

```
"object" => "instagram"
"changes" => [{ "field" => "comments", ... }]
```

### DM test

1. Instagram Tester sends DM to business IG
2. Expect staging log:

```
"object" => "instagram"
"messaging" => [...]
```

---

## Step 7: Configure auto-reply (after webhooks arrive)

Webhooks can arrive without auto-reply if message bags are not configured.

| Channel | Setting |
|---------|---------|
| DM fallback | `default_reply_bag` on Instagram account |
| DM keywords | Keyword settings with `is_dm: true` |
| Post comments | `post_comment_bag_status`: `direct_message` or `keyword` |
| Post comment bag | `post_comment_bag` assigned via Release editor |

API: `PATCH /api/v1/instagram_settings/:id` and `PATCH /api/v1/instagram_setting_change_status/:id`

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Invalid Scopes on login | Enable permissions in Use Cases (Step 1) |
| `pages_messaging` error on connect | Re-login after Step 1; check `grantedScopes` in logs |
| `#100` comments in subscribed_fields | Do not add `comments` to Page `subscribed_apps` — use Dashboard only |
| Permission webhooks only (`object: permissions`) | Normal on login; not DM/comment events |
| Dashboard Test works, real comment does not | Tester role, public post, Advanced Access for `instagram_manage_comments` |
| Webhook arrives, no reply | Configure message bags (Step 7) |

---

## Code references

- Webhook handler: `app/controllers/api/v1/chatbots_controller.rb`
- Connect + Page subscription: `app/services/facebook_manager/instagram_setting.rb`
- Facebook scopes: `EC-ChatBot-Frontend/.../InstagramConnectCard.jsx` → `FB_SCOPES`
