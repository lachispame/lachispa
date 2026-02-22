// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcome_title => 'Welcome to La Chispa!';

  @override
  String get welcome_subtitle => 'Lightning for everyone';

  @override
  String get get_started_button => 'Get Started';

  @override
  String get tap_to_start_hint => 'As easy as lighting a spark';

  @override
  String get choose_option_title => 'Connect with your favorite LNBits server';

  @override
  String get create_new_wallet_title => 'Create New Wallet';

  @override
  String get create_new_wallet_subtitle => 'Set up your own Lightning wallet';

  @override
  String get use_existing_wallet_title => 'Use Existing Wallet';

  @override
  String get use_existing_wallet_subtitle => 'Connect to a Lightning wallet';

  @override
  String get server_settings_title => 'Current Server';

  @override
  String get change_server_button => 'Change Server';

  @override
  String get server_url_label => 'Server URL';

  @override
  String get admin_label => 'Administrator';

  @override
  String get admin_key_label => 'Admin Key';

  @override
  String get invoice_key_label => 'Invoice Key';

  @override
  String get server_url_placeholder => 'https://demo.lnbits.com';

  @override
  String get admin_key_placeholder => 'Enter admin key';

  @override
  String get invoice_key_placeholder => 'Enter invoice key';

  @override
  String get connect_button => 'Connect';

  @override
  String get connecting_button => 'CONNECTING...';

  @override
  String get connection_error_prefix => 'Connection error: ';

  @override
  String get login_title => 'Login';

  @override
  String get username_label => 'Username';

  @override
  String get password_label => 'Password';

  @override
  String get username_placeholder => 'Enter your username';

  @override
  String get password_placeholder => 'Enter your password';

  @override
  String get login_button => 'Login';

  @override
  String get logging_in_button => 'LOGGING IN...';

  @override
  String get no_account_question => 'Don\'t have an account? ';

  @override
  String get register_link => 'Sign up';

  @override
  String get login_error_prefix => 'Login error: ';

  @override
  String get create_account_title => 'Create Account';

  @override
  String get signup_username_label => 'Username';

  @override
  String get signup_password_label => 'Password';

  @override
  String get confirm_password_label => 'Confirm Password';

  @override
  String get signup_username_placeholder => 'Enter a username';

  @override
  String get signup_password_placeholder => 'Enter a password';

  @override
  String get confirm_password_placeholder => 'Repeat your password';

  @override
  String get create_account_button => 'Create Account';

  @override
  String get creating_account_button => 'CREATING ACCOUNT...';

  @override
  String get already_have_account_question => 'Already have an account? ';

  @override
  String get login_link => 'Login';

  @override
  String get passwords_mismatch_error => 'Passwords don\'t match';

  @override
  String get account_creation_error_prefix => 'Error creating account: ';

  @override
  String get wallet_title => 'Wallet';

  @override
  String get balance_label => 'Balance';

  @override
  String get receive_button => 'Receive';

  @override
  String get send_button => 'Send';

  @override
  String get history_button => 'History';

  @override
  String get settings_button => 'Settings';

  @override
  String get loading_text => 'Loading...';

  @override
  String get history_title => 'History';

  @override
  String get loading_transactions_text => 'Loading transactions...';

  @override
  String get no_transactions_text => 'No transactions';

  @override
  String get no_transactions_description =>
      'You haven\'t made any transactions yet.';

  @override
  String get sent_label => 'Sent';

  @override
  String get received_label => 'Received';

  @override
  String get pending_label => 'Pending';

  @override
  String get failed_label => 'Failed';

  @override
  String get loading_transactions_error_prefix =>
      'Error loading transactions: ';

  @override
  String get lightning_address_title => 'Lightning Address';

  @override
  String get loading_address_text => 'Loading address...';

  @override
  String get your_lightning_address_label => 'Your Lightning address:';

  @override
  String get not_available_text => 'Not available';

  @override
  String get share_button => 'Share';

  @override
  String get copy_button => 'Copy';

  @override
  String get address_copied_message => 'Address copied to clipboard';

  @override
  String get loading_address_error_prefix =>
      'Error loading Lightning address: ';

  @override
  String get settings_title => 'About';

  @override
  String get lightning_address_option => 'Lightning Address';

  @override
  String get lightning_address_description => 'View your Lightning address';

  @override
  String get logout_option => 'Logout';

  @override
  String get logout_description => 'Disconnect from current account';

  @override
  String get confirm_logout_title => 'Confirm Logout';

  @override
  String get confirm_logout_message => 'Are you sure you want to logout?';

  @override
  String get cancel_button => 'Cancel';

  @override
  String get logout_confirm_button => 'Logout';

  @override
  String get receive_title => 'Receive';

  @override
  String get amount_sats_label => 'Request Amount';

  @override
  String get amount_label => 'Amount';

  @override
  String get currency_label => 'Currency';

  @override
  String get description_label => 'Description';

  @override
  String get amount_sats_placeholder => 'Enter amount in sats';

  @override
  String get description_placeholder => 'Optional description';

  @override
  String get optional_description_label => 'Description (Optional)';

  @override
  String get copy_lightning_address => 'Copy Lightning Address';

  @override
  String get copy_lnurl => 'Copy LNURL';

  @override
  String get generate_invoice_button => 'Generate Invoice';

  @override
  String get generating_button => 'GENERATING...';

  @override
  String get invoice_generated_message => 'Invoice generated successfully';

  @override
  String get invoice_generation_error_prefix => 'Error generating invoice: ';

  @override
  String get send_title => 'Send';

  @override
  String get paste_invoice_placeholder => 'Paste invoice, LNURL or address';

  @override
  String get paste_button => 'Paste';

  @override
  String get scan_button => 'Scan';

  @override
  String get voucher_scan_title => 'Scan Voucher';

  @override
  String get voucher_scan_instructions =>
      'Point your camera at the LNURL-withdraw voucher QR code';

  @override
  String get voucher_scan_subtitle =>
      'The app will automatically detect the voucher and allow you to claim it';

  @override
  String get voucher_scan_button => 'Scan QR';

  @override
  String get voucher_tap_to_scan => 'Tap to open camera';

  @override
  String get voucher_manual_input => 'Enter code manually';

  @override
  String get voucher_processing => 'Processing...';

  @override
  String get voucher_manual_input_hint =>
      'Paste the LNURL-withdraw voucher code:';

  @override
  String get voucher_manual_input_placeholder => 'lnurl1...';

  @override
  String get process_button => 'Process';

  @override
  String get voucher_detected_title => 'Voucher Detected';

  @override
  String get voucher_fixed_amount => 'Fixed amount:';

  @override
  String get voucher_amount_range => 'Available range:';

  @override
  String get voucher_amount_to_claim => 'Amount to claim:';

  @override
  String voucher_min_max_hint(int min, int max) {
    return 'Min: $min sats • Max: $max sats';
  }

  @override
  String get voucher_claim_button => 'Claim Voucher';

  @override
  String voucher_amount_invalid(int min, int max) {
    return 'Invalid amount. Must be between $min and $max sats';
  }

  @override
  String get voucher_claimed_title => 'Voucher claimed!';

  @override
  String get voucher_claimed_subtitle =>
      'The funds will appear in your wallet shortly.';

  @override
  String get voucher_invalid_code => 'Invalid code';

  @override
  String get voucher_not_valid_lnurl =>
      'The scanned code is not a valid LNURL-withdraw voucher.';

  @override
  String get voucher_processing_error => 'Error processing voucher';

  @override
  String get voucher_already_claimed => 'Voucher already claimed';

  @override
  String get voucher_already_claimed_desc =>
      'This voucher has already been used and cannot be claimed again.';

  @override
  String get voucher_expired => 'Voucher expired';

  @override
  String get voucher_expired_desc =>
      'This voucher has expired and is no longer valid.';

  @override
  String get voucher_not_found => 'Voucher not found';

  @override
  String get voucher_not_found_desc =>
      'This voucher could not be found or may have been removed.';

  @override
  String get voucher_server_error => 'Server error';

  @override
  String get voucher_server_error_desc =>
      'There was a problem with the voucher server. Please try again later.';

  @override
  String get voucher_connection_error => 'Connection error';

  @override
  String get voucher_connection_error_desc =>
      'Please check your internet connection and try again.';

  @override
  String get voucher_invalid_amount => 'Invalid amount';

  @override
  String get voucher_invalid_amount_desc =>
      'The voucher amount is not valid or has been corrupted.';

  @override
  String get voucher_insufficient_funds => 'Insufficient funds';

  @override
  String get voucher_insufficient_funds_desc =>
      'The voucher does not have enough funds available.';

  @override
  String get voucher_generic_error => 'Unable to process voucher';

  @override
  String get voucher_generic_error_desc =>
      'There was an unexpected error processing this voucher. Please try again or contact support.';

  @override
  String get pay_button => 'PAY';

  @override
  String get processing_button => 'PROCESSING...';

  @override
  String get payment_instruction_text =>
      'Paste a Lightning invoice, LNURL or address';

  @override
  String get payment_processing_error_prefix => 'Error processing payment: ';

  @override
  String get no_active_session_error => 'No active session';

  @override
  String get no_primary_wallet_error => 'No primary wallet available';

  @override
  String get invoice_decoding_error_prefix => 'Error decoding invoice: ';

  @override
  String get send_to_title => 'Send to';

  @override
  String get clear_button => 'C';

  @override
  String get decimal_button => '.';

  @override
  String get calculating_text => 'Calculating...';

  @override
  String get loading_rates_text => 'Loading rates...';

  @override
  String get send_button_prefix => 'SEND ';

  @override
  String get amount_processing_button => 'PROCESSING...';

  @override
  String get exchange_rates_error => 'Error loading exchange rates';

  @override
  String get invalid_amount_error => 'Please enter a valid amount';

  @override
  String get amount_payment_error_prefix => 'Error processing payment: ';

  @override
  String get amount_no_session_error => 'No active session';

  @override
  String get amount_no_wallet_error => 'No primary wallet available';

  @override
  String get sending_lnurl_payment => 'Sending LNURL payment...';

  @override
  String get sending_lightning_payment =>
      'Sending Lightning Address payment...';

  @override
  String get lnurl_payment_pending =>
      'LNURL payment pending - Hold invoice detected';

  @override
  String get lnurl_payment_success => 'LNURL payment completed successfully!';

  @override
  String get lightning_payment_pending =>
      'Lightning Address payment pending - Hold invoice detected';

  @override
  String get lightning_payment_success =>
      'Lightning Address payment completed successfully!';

  @override
  String get insufficient_balance_error =>
      'Insufficient balance to make payment';

  @override
  String get confirm_payment_title => 'Confirm Payment';

  @override
  String get invoice_description_label => 'Description';

  @override
  String get no_description_text => 'No description';

  @override
  String get invoice_status_label => 'Status';

  @override
  String get expired_status => 'Expired';

  @override
  String get valid_status => 'Valid';

  @override
  String get expiration_label => 'Expiration';

  @override
  String get payment_hash_label => 'Payment Hash';

  @override
  String get recipient_label => 'Recipient';

  @override
  String get cancel_button_confirm => 'Cancel';

  @override
  String get pay_button_confirm => 'Pay';

  @override
  String get confirm_button => 'Confirm';

  @override
  String get expired_button_text => 'Expired';

  @override
  String get sending_button => 'Sending...';

  @override
  String get invoice_expired_error =>
      'The invoice has expired and cannot be paid';

  @override
  String get confirm_no_session_error => 'No active session';

  @override
  String get confirm_no_wallet_error => 'No primary wallet available';

  @override
  String get payment_pending_hold => 'Payment pending - Hold invoice detected';

  @override
  String get payment_completed_success => 'Payment completed successfully';

  @override
  String get payment_sent_status_prefix => 'Payment sent - Status: ';

  @override
  String get payment_sending_error_prefix => 'Error sending payment: ';

  @override
  String get language_selector_title => 'Language';

  @override
  String get language_selector_description => 'Change application language';

  @override
  String get select_language => 'Select language';

  @override
  String get no_wallet_error => 'No primary wallet available';

  @override
  String get invalid_session_error => 'No active session';

  @override
  String get send_error_prefix => 'Error processing send: ';

  @override
  String get decode_invoice_error_prefix => 'Error decoding invoice: ';

  @override
  String get payment_success => 'Payment completed successfully';

  @override
  String get expiry_label => 'Expiration';

  @override
  String get processing_text => 'processing';

  @override
  String get paste_input_hint => 'Paste invoice, LNURL or address';

  @override
  String get conversion_rate_error => 'Error loading exchange rates';

  @override
  String get instant_payments_feature => 'Instant payments';

  @override
  String get favorite_server_feature => 'With your favorite server';

  @override
  String get receive_info_text =>
      '• Share your Lightning Address to receive payments of any amount\n\n• QR code automatically resolves to LNURL for maximum compatibility\n\n• Payments are received directly in this wallet';

  @override
  String get payment_description_example => 'Ex: Payment for services';

  @override
  String get remember_password_label => 'Remember password';

  @override
  String get server_prefix => 'Server: ';

  @override
  String get login_subtitle => 'Enter your credentials to access your wallet';

  @override
  String get username_required_error => 'Username is required';

  @override
  String get username_length_error => 'Username must be at least 3 characters';

  @override
  String get password_required_error => 'Password is required';

  @override
  String get password_length_error => 'Password must be at least 6 characters';

  @override
  String get saved_users_header => 'Saved users';

  @override
  String get tap_to_autocomplete_hint => 'Tap to autocomplete password';

  @override
  String get delete_credentials_title => 'Delete credentials';

  @override
  String get delete_credentials_message =>
      'By unchecking this option, saved credentials for this user will be deleted.\\n\\nAre you sure you want to continue?';

  @override
  String get delete_credentials_cancel => 'Cancel';

  @override
  String get delete_credentials_confirm => 'Delete';

  @override
  String get close_dialog => 'Close';

  @override
  String get credentials_found_message =>
      'Credentials found - password will be remembered';

  @override
  String get password_will_be_remembered =>
      'Password will be remembered after login';

  @override
  String get password_saved_successfully => 'Password saved successfully';

  @override
  String get password_save_failed => 'Could not save password';

  @override
  String get about_app_subtitle => 'Lightning Wallet';

  @override
  String get about_app_description =>
      'A mobile application to manage Bitcoin through Lightning Network using LNBits as backend.';

  @override
  String get lightning_address_copy => 'Copy';

  @override
  String get lightning_address_default => 'Default';

  @override
  String get lightning_address_delete => 'Delete';

  @override
  String get lightning_address_is_default => 'Is default';

  @override
  String get lightning_address_set_default => 'Set as default';

  @override
  String get create_new_wallet_help => 'Create new wallet';

  @override
  String get create_wallet_short_description =>
      'To create a new wallet, access your LNBits panel from the browser and use the \"Create wallet\" option.';

  @override
  String get create_wallet_detailed_instructions =>
      'To create a new wallet:\\n\\n1. Open your web browser\\n2. Access your LNBits server\\n3. Log in with your account\\n4. Look for the \"Create wallet\" button\\n5. Assign a name to your new wallet\\n6. Return to LaChispa and refresh your wallets\\n\\nThe new wallet will appear automatically in your list.';

  @override
  String get fixed_float_loading => 'Loading Fixed Float...';

  @override
  String get fixed_float_description =>
      'Exchange cryptocurrencies with\nfixed rates and no registration';

  @override
  String get fixed_float_webview_error =>
      'WebView not available on this platform.\nWill open in external browser.';

  @override
  String get fixed_float_open_button => 'Open Fixed Float';

  @override
  String fixed_float_error_opening(String error) {
    return 'Error opening Fixed Float: $error';
  }

  @override
  String get fixed_float_external_browser =>
      'Will open Fixed Float in external browser';

  @override
  String get fixed_float_within_app => 'Opens Fixed Float within the app';

  @override
  String get boltz_loading => 'Loading Boltz...';

  @override
  String get boltz_description =>
      'Trustless Bitcoin and Lightning\natomic swaps';

  @override
  String get boltz_webview_error =>
      'WebView not available on this platform.\nWill open in external browser.';

  @override
  String get boltz_open_button => 'Open Boltz';

  @override
  String boltz_error_opening(String error) {
    return 'Error opening Boltz: $error';
  }

  @override
  String get boltz_external_browser => 'Will open Boltz in external browser';

  @override
  String get boltz_within_app => 'Opens Boltz within the app';

  @override
  String get add_note_optional => 'Add a note (optional)';

  @override
  String get currency_settings_title => 'Currency Selection';

  @override
  String get currency_settings_subtitle => 'Select your preferred currencies';

  @override
  String get available_currencies => 'Available Currencies';

  @override
  String get selected_currencies => 'Selected Currencies';

  @override
  String get no_currencies_available => 'No currencies available from server';

  @override
  String get select_currencies_hint => 'Select currencies from the list above';

  @override
  String get preview_title => 'Preview';

  @override
  String get tap_to_cycle => 'Tap to cycle currencies';

  @override
  String get settings_screen_title => 'Settings';

  @override
  String get about_title => 'About';

  @override
  String get currency_validation_info =>
      'When selecting a currency, it will be verified if it\'s available on this server';

  @override
  String checking_currency_availability(Object currency) {
    return 'Checking $currency availability...';
  }

  @override
  String currency_added_successfully(Object currency) {
    return '$currency added successfully';
  }

  @override
  String currency_not_available_on_server(
    Object currency,
    Object currencyName,
  ) {
    return '$currencyName ($currency) is not available on this server';
  }

  @override
  String error_checking_currency(Object currency, Object error) {
    return 'Error checking $currency: $error';
  }

  @override
  String get deep_link_login_required_title => 'Login Required';

  @override
  String get deep_link_login_required_message =>
      'You must log in to your LaChispa account to process this payment.';

  @override
  String get invoice_receive_description =>
      'Create an invoice to receive payments directly to your wallet';

  @override
  String get or_create_lnaddress => 'or you can also create a:';

  @override
  String get or_create_lnaddress_full =>
      'or you can also create a Lightning Address:';

  @override
  String get invoice_copied => 'Invoice copied';
}
