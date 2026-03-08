# Supabase Email Templates (拾憶 Grasp)

將以下 HTML 檔內容貼到 Supabase Dashboard：

- `Authentication` -> `Email Templates` -> `Confirm signup`
  - 使用 `signup_confirmation_email.html`
- `Authentication` -> `Email Templates` -> `Reset Password`
  - 使用 `reset_password_email.html`
- `Authentication` -> `Email Templates` -> `Magic Link`
  - 使用 `magic_link_email.html`
- `Authentication` -> `Email Templates` -> `Change Email Address`（名稱可能依 Dashboard 版本略有不同）
  - 使用 `change_email_confirmation_email.html`

## 注意

- 模板使用 Supabase 變數：`{{ .Email }}`、`{{ .ConfirmationURL }}`、`{{ .SiteURL }}`
- 變更信箱模板額外使用 `{{ .NewEmail }}`（若你的 Supabase 版本不支援，請移除此行）
- 寄送前請確認 Supabase `Site URL` 與 `Redirect URLs` 已正確設定，避免按鈕導向錯誤
