# Visa Warden — Code Review & Refactor Plan

## Architecture Overview

The extension has 3 JS files with no build system, no modules, and heavy code duplication:

| File | Role | Lines |
|------|------|-------|
| `vwarden.js` | Content script (injected into TLSContact pages) | 680 |
| `resources/vwb.js` | Background service worker (polling loop) | 861 |
| `resources/vwf.js` | Popup UI script | 666 |

---

## Critical Issues

### 1. Implicit globals everywhere (all 3 files)

Variables declared without `let`/`const`/`var` become implicit globals. This causes unpredictable cross-scope pollution and is a top source of subtle bugs.

**`vwarden.js`** — at least these are implicitly global:
- Line 56: `obj = {}`
- Line 100: `end = url.indexOf(...)`
- Line 113: `result = get_val(...)`
- Line 120: `i` in loop
- Line 139: `app_num`
- Line 203: `form_data`
- Lines 317, 324-325, 328: `result`, `lines`, `raw_json`, `json`
- Line 445: `start`, `end`

**`resources/vwb.js`** — same pattern:
- Lines 152, 159, 165, 174: `appt_pos`, `end`, `start` in `get_hash_for_action`
- Lines 233, 237: `x`, `cur_obj` in `get_first_viable_appointment`
- Lines 268, 269: `i`, `slot`
- Lines 334-335, 352, 372-373, 377: `count`, `av_start`, `appts`, `j`
- Lines 403-408: `centre_start`, `centre_end`, `centre`, `lang_start`, `lang_end`, `lang`
- Lines 459-461: `j`, `data`, `id`

**`resources/vwf.js`** — same:
- Lines 456-457: `pd_split`, `i`
- Line 551: `details`
- Lines 565-566: `find_count`, `find_time`

### 2. Password field rendered as plaintext

**`resources/login.html:58`**:
```html
<input class="chunky" id="tlspass" type="text" placeholder="TLSContact Password" />
```
This should be `type="password"`. The user's TLSContact credentials are shown in cleartext in the popup.

### 3. Missing `await` on async call — Belgium flow silently broken

**`vwarden.js:488-489`**:
```js
if (handle_belgium(document.URL) == false) {
```
`handle_belgium` is `async` and returns a Promise. Without `await`, this comparison is `Promise == false` which is always `false`. The error notification on lines 490-491 will **never fire**.

### 4. Parenthesization bug — `get_application_details` always returns `undefined`

**`vwarden.js:81`**:
```js
return (await chrome.storage.local.get('tls_details').tls_details)
```
This evaluates as `chrome.storage.local.get('tls_details').tls_details` (which is `undefined`) and then `await undefined`. Should be:
```js
return (await chrome.storage.local.get('tls_details')).tls_details
```

### 5. `get_tested` in content script accepts unused parameter

**`vwarden.js:21`**:
```js
async function get_tested(val) {
```
The `val` parameter is never used — the function always reads from storage. This is misleading but not a runtime bug.

---

## Security Issues

### 6. Credentials stored in `chrome.storage.local` unencrypted

TLSContact username/password are stored as raw strings (`tu`, `tp`). `chrome.storage.local` is readable by any code in the extension context. Consider using `chrome.storage.session` for transient secrets or at minimum encrypting values.

### 7. Hardcoded timestamp in Belgian onboarding URL

**`vwb.js:450` and `vwarden.js:368`**: The `_=1769785962449` cache-buster is hardcoded. This should be `Date.now()` to avoid potential caching/fingerprinting issues.

### 8. Cookie handling assumes fixed header order

**`vwb.js:755`**:
```js
domain = details[6] // Can this be in a different order? Doubt it.
```
The comment acknowledges the fragility. `set-cookie` attributes can appear in any order. This will silently extract the wrong value if the server changes attribute ordering.

---

## Duplicated Code

### 9. Massive copy-paste across all 3 files

These functions are **identically duplicated** in 2 or 3 files:

| Function | `vwarden.js` | `vwb.js` | `vwf.js` |
|----------|:---:|:---:|:---:|
| `log()` | x | x | x |
| `set_status()` | x | x | x |
| `get_val()` | x | x | x |
| `store_val()` | x | x | x |
| `get_tp()` | x | x | x |
| `get_tu()` | x | x | x |
| `set_refresh_timer()` | x | x | x |
| `set_refreshing()` | x | x | x |
| `get_membership()` | x | | x |
| `get_belgian_onboarding()` | x | x | |
| `login_belgium()` / `handle_belgium()` | x | x | x |
| `set_scanning()` | x | x | x |
| `get_user()` | x | x | |

This makes maintenance extremely error-prone — a fix applied to one copy but not the others will cause inconsistent behavior.

---

## Logic & Reliability Issues

### 10. Brittle HTML parsing for appointment data

**`vwb.js:352-372`**: Appointment data is extracted via `indexOf('availableAppointments')` and manual substring slicing from what appears to be an RSC (React Server Components) response. Any change to whitespace, key ordering, or response format will silently break parsing.

### 11. `extract_application_id_from_url` uses magic offset

**`vwarden.js:104`**:
```js
const id = url.substring(end - 7, end);
```
Assumes application IDs are always exactly 7 characters. If an ID is 6 or 8 digits, this silently returns a wrong number.

### 12. `check_logged_in` is hardcoded to `true`

**`vwarden.js:41-43`**:
```js
async function check_logged_in() {
    return true;
}
```
This guard is never effective. Same for `get_membership()` (always returns `0`), `request_captcha()` (always returns `''`), and `check_sub()` (always returns `true`). These appear to be stubs from removing a server-side component.

### 13. Timer comment contradicts code

**`vwarden.js:533-534`**:
```js
}, 30 * 1000) // Refresh page in 10s.
```
Comment says 10 seconds, code does 30 seconds. This appears in multiple places.

### 14. `failed` variable scoping issue in `main()`

**`vwarden.js:504`**: `failed` is set to `true` inside a `.then()` callback (line 546), but checked synchronously at line 664. Since the `.then()` is async, `failed` will still be `false` when checked, making the guard at line 664 useless.

### 15. Time filtering bug — wrong variable checked

**`vwb.js:279`**:
```js
if (last_time != null && start_time != undefined)
```
This checks `start_time` instead of `last_time`. Should be:
```js
if (last_time != null && last_time != undefined)
```
This means `last_time` filtering is bypassed when `start_time` is undefined.

### 16. `res == 1` but `attempt_booking` returns `true`/`false`

**`vwarden.js:456`**:
```js
if (res == 1) {
```
`attempt_booking` returns `true`/`false`/`-1`. With loose equality `true == 1` is `true`, so this works by accident, but it's confusing and fragile.

---

## Minor Issues

### 17. Popup tick rate is aggressive

**`vwf.js:663`**: `setInterval(tick, 500)` — the popup's `tick()` makes ~10 `chrome.storage.local.get` calls. At 500ms, that's 20 storage reads/second. This is wasteful and could cause UI jank. 1-2 seconds would be fine.

### 18. `recap2.length` on a single element

**`vwarden.js:559`**:
```js
const recap2 = document.getElementById("it-recaptcha-here")
if (recap.length > 0 || recap2.length > 0) {
```
`getElementById` returns a single element or `null`, not an HTMLCollection. `recap2.length` reads the element's `length` property (undefined for most elements), which is falsy. This check doesn't work as intended.

### 19. Label `for` attribute mismatch

**`login.html:150`**:
```html
<label for="d44">Thursday</label>
```
Should be `for="d4"` to match `<input id="d4">`.

### 20. `min` date is stale

**`login.html:115`**:
```html
<input type="date" class="chunky" id="start_date" min="2025-11-18">
```
This will become outdated. Consider setting it dynamically.

---

## Summary

| Category | Count |
|----------|-------|
| Critical (will cause bugs in production) | 5 |
| Security | 3 |
| Code duplication | 1 (systemic) |
| Logic/reliability | 7 |
| Minor | 4 |

## Recommended Fix Priority

1. **Add `"use strict"` to every file** — catches all the implicit globals immediately
2. **Fix the missing `await`** on `handle_belgium()` and the `get_application_details()` parenthesization
3. **Change the password input to `type="password"`**
4. **Fix the `last_time` filtering bug** in `vwb.js:279`
5. **Extract shared utilities** into a common file loaded by all contexts to eliminate the duplication
