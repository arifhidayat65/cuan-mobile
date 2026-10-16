package com.cuan.app

import io.flutter.embedding.android.FlutterFragmentActivity

// Must extend FlutterFragmentActivity (not FlutterActivity):
// local_auth's Android BiometricPrompt requires a FragmentActivity,
// otherwise every authenticate() call fails with NOT_FRAGMENT_ACTIVITY
// and no biometric prompt ever appears.
class MainActivity : FlutterFragmentActivity()
