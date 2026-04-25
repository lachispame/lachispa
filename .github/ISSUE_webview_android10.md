# WebView does not load FixedFloat on Android 10

## Problem description

On devices running Android 10 (specifically tested on Xiaomi Redmi Note 9 with MIUI 12), when trying to open FixedFloat from the app, the internal WebView fails to load the content and shows an error.

### Test environment
- **Device**: Xiaomi Redmi Note 9 (M2003J15SC)
- **Android**: 10 (API 29)
- **MIUI**: 12

### Observed error message
```
FixedFloat init: isWeb=false, isAndroid=true, isIOS=false, isDebug=true
FixedFloat: isMobilePlatform=true, willUseWebView=true
FixedFloat: WebViewController initialized successfully
FixedFloat: Page started: https://ff.io/BTCLN/BTC/?ref=setgskja
FixedFloat: Page finished: https://ff.io/BTCLN/BTC/?ref=setgskja
FixedFloat: WebResourceError: -1 - net::ERR_BLOCKED_BY_ORB
```

## Technical analysis

The error `ERR_BLOCKED_BY_ORB` indicates that the website `ff.io` is blocking access from an embedded WebView. This is a security measure by the website to prevent fraud or automated access.

### Findings

1. **Works on Android 14 and 15**: Development team tested on Android 14 and 15 devices without issues
2. **Boltz works on Android 10**: Another screen using WebView (`boltz.exchange`) works correctly on the same device

**Conclusion**: The issue is specific to the combination Android 10 + ff.io, not a general WebView issue or `webview_flutter` library problem.

## Proposed solution

We propose implementing an **automatic fallback** that:

1. **Tries** to load content in the internal WebView first
2. **if it fails** with any error, automatically opens the system's default external browser

### Proposed code

```dart
onWebResourceError: (WebResourceError error) {
  if (mounted) {
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Error: ${error.errorCode} - ${error.description}';
    });
    _openInBrowser();
  }
},
```

The `_openInBrowser()` method uses `url_launcher`:

```dart
Future<void> _launchFixedFloat() async {
  final Uri url = Uri.parse(_fixedFloatUrl);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}
```

### Advantages of this solution

1. **No Android version detection**: Works on any Android where WebView fails
2. **Transparent automatic fallback**: User doesn't need to do anything extra
3. **Consistent**: Works the same if the website blocks WebView for any reason

### Alternatives considered

1. **Detect Android version**: Implement specific logic for Android 10 - Discarded because it complicates code and won't cover other cases
2. **Force Hybrid Composition**: Attempted previously without success - Error persists at website level
3. **No fallback**: Let user see error and decide - Worse user experience

## Questions for discussion

1. Is it acceptable to automatically open the external browser without asking the user?
2. Should we show any visual indicator that it opened in external browser?
3. Should this solution also apply to other screens using WebView (e.g., Boltz)?

## Additional testing suggested

- [ ] Test on Android 14
- [ ] Test on Android 15
- [ ] Test on Android 10 (Redmi Note 9)
- [ ] Verify Boltz still works

---

**Note**: This issue is a proposal for discussion. The mentioned solution is implemented in branch `webview-android10-fix` but requires review before merging.