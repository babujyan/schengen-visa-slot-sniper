# Security

If you discover a security vulnerability, please report it responsibly by
[opening a private issue](../../security/advisories/new) rather than a public one.

## Credential Handling

This extension stores TLSContact credentials and Telegram bot tokens in `chrome.storage.local`. Users should be aware
that:

- Credentials are stored locally on your machine and are never sent to any third-party server.
- Telegram bot tokens are used solely to send notifications to your configured chat.
- Any Chrome extension with `storage` permission running in the same browser profile could theoretically read these
  values.

## Recommendations

- Do not share your browser profile with untrusted extensions while using this tool.
- Use a dedicated Telegram bot for this extension rather than reusing a bot with elevated permissions.
- Review the extension's permissions in `chrome://extensions/` to understand what it can access.
