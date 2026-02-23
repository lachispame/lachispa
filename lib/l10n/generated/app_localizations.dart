import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
    Locale('ru')
  ];

  /// No description provided for @welcome_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to La Chispa!'**
  String get welcome_title;

  /// No description provided for @welcome_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Lightning for everyone'**
  String get welcome_subtitle;

  /// No description provided for @get_started_button.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get get_started_button;

  /// No description provided for @tap_to_start_hint.
  ///
  /// In en, this message translates to:
  /// **'As easy as lighting a spark'**
  String get tap_to_start_hint;

  /// No description provided for @choose_option_title.
  ///
  /// In en, this message translates to:
  /// **'Connect with your favorite LNBits server'**
  String get choose_option_title;

  /// No description provided for @create_new_wallet_title.
  ///
  /// In en, this message translates to:
  /// **'Create New Wallet'**
  String get create_new_wallet_title;

  /// No description provided for @create_new_wallet_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your own Lightning wallet'**
  String get create_new_wallet_subtitle;

  /// No description provided for @use_existing_wallet_title.
  ///
  /// In en, this message translates to:
  /// **'Use Existing Wallet'**
  String get use_existing_wallet_title;

  /// No description provided for @use_existing_wallet_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to a Lightning wallet'**
  String get use_existing_wallet_subtitle;

  /// No description provided for @server_settings_title.
  ///
  /// In en, this message translates to:
  /// **'Current Server'**
  String get server_settings_title;

  /// No description provided for @change_server_button.
  ///
  /// In en, this message translates to:
  /// **'Change Server'**
  String get change_server_button;

  /// No description provided for @server_url_label.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get server_url_label;

  /// No description provided for @admin_label.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get admin_label;

  /// No description provided for @admin_key_label.
  ///
  /// In en, this message translates to:
  /// **'Admin Key'**
  String get admin_key_label;

  /// No description provided for @invoice_key_label.
  ///
  /// In en, this message translates to:
  /// **'Invoice Key'**
  String get invoice_key_label;

  /// No description provided for @server_url_placeholder.
  ///
  /// In en, this message translates to:
  /// **'https://demo.lnbits.com'**
  String get server_url_placeholder;

  /// No description provided for @admin_key_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Enter admin key'**
  String get admin_key_placeholder;

  /// No description provided for @invoice_key_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Enter invoice key'**
  String get invoice_key_placeholder;

  /// No description provided for @connect_button.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect_button;

  /// No description provided for @connecting_button.
  ///
  /// In en, this message translates to:
  /// **'CONNECTING...'**
  String get connecting_button;

  /// No description provided for @connection_error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Connection error: '**
  String get connection_error_prefix;

  /// No description provided for @login_title.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_title;

  /// No description provided for @username_label.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username_label;

  /// No description provided for @password_label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password_label;

  /// No description provided for @username_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get username_placeholder;

  /// No description provided for @password_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get password_placeholder;

  /// No description provided for @login_button.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_button;

  /// No description provided for @logging_in_button.
  ///
  /// In en, this message translates to:
  /// **'LOGGING IN...'**
  String get logging_in_button;

  /// No description provided for @no_account_question.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get no_account_question;

  /// No description provided for @register_link.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get register_link;

  /// No description provided for @login_error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Login error: '**
  String get login_error_prefix;

  /// No description provided for @create_account_title.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account_title;

  /// No description provided for @signup_username_label.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get signup_username_label;

  /// No description provided for @signup_password_label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signup_password_label;

  /// No description provided for @confirm_password_label.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_password_label;

  /// No description provided for @signup_username_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Enter a username'**
  String get signup_username_placeholder;

  /// No description provided for @signup_password_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get signup_password_placeholder;

  /// No description provided for @confirm_password_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get confirm_password_placeholder;

  /// No description provided for @create_account_button.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account_button;

  /// No description provided for @creating_account_button.
  ///
  /// In en, this message translates to:
  /// **'CREATING ACCOUNT...'**
  String get creating_account_button;

  /// No description provided for @already_have_account_question.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get already_have_account_question;

  /// No description provided for @login_link.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_link;

  /// No description provided for @passwords_mismatch_error.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwords_mismatch_error;

  /// No description provided for @account_creation_error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Error creating account: '**
  String get account_creation_error_prefix;

  /// No description provided for @wallet_title.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet_title;

  /// No description provided for @balance_label.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance_label;

  /// No description provided for @receive_button.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive_button;

  /// No description provided for @send_button.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send_button;

  /// No description provided for @history_button.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history_button;

  /// No description provided for @settings_button.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_button;

  /// No description provided for @loading_text.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading_text;

  /// No description provided for @history_title.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history_title;

  /// No description provided for @loading_transactions_text.
  ///
  /// In en, this message translates to:
  /// **'Loading transactions...'**
  String get loading_transactions_text;

  /// No description provided for @no_transactions_text.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get no_transactions_text;

  /// No description provided for @no_transactions_description.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t made any transactions yet.'**
  String get no_transactions_description;

  /// No description provided for @sent_label.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent_label;

  /// No description provided for @received_label.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received_label;

  /// No description provided for @pending_label.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending_label;

  /// No description provided for @failed_label.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed_label;

  /// No description provided for @loading_transactions_error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Error loading transactions: '**
  String get loading_transactions_error_prefix;

  /// No description provided for @crear_lnaddress_label.
  ///
  /// In en, this message translates to:
  /// **'or create a:'**
  String get crear_lnaddress_label;

  /// No description provided for @lightning_address_title.
  ///
  /// In en, this message translates to:
  /// **'Lightning Address'**
  String get lightning_address_title;

  /// No description provided for @loading_address_text.
  ///
  /// In en, this message translates to:
  /// **'Loading address...'**
  String get loading_address_text;

  /// No description provided for @your_lightning_address_label.
  ///
  /// In en, this message translates to:
  /// **'Your Lightning address:'**
  String get your_lightning_address_label;

  /// No description provided for @not_available_text.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get not_available_text;

  /// No description provided for @share_button.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share_button;

  /// No description provided for @copy_button.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy_button;

  /// No description provided for @address_copied_message.
  ///
  /// In en, this message translates to:
  /// **'Address copied to clipboard'**
  String get address_copied_message;

  /// No description provided for @loading_address_error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Error loading Lightning address: '**
  String get loading_address_error_prefix;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_title;

  /// No description provided for @lightning_address_option.
  ///
  /// In en, this message translates to:
  /// **'Lightning Address'**
  String get lightning_address_option;

  /// No description provided for @lightning_address_description.
  ///
  /// In en, this message translates to:
  /// **'View your Lightning address'**
  String get lightning_address_description;

  /// No description provided for @logout_option.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout_option;

  /// No description provided for @logout_description.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from current account'**
  String get logout_description;

  /// No description provided for @confirm_logout_title.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirm_logout_title;

  /// No description provided for @confirm_logout_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirm_logout_message;

  /// No description provided for @cancel_button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel_button;

  /// No description provided for @logout_confirm_button.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout_confirm_button;

  /// No description provided for @receive_title.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive_title;

  /// No description provided for @crear_factura_label.
  ///
  /// In en, this message translates to:
  /// **'Create an invoice to receive payments directly in your wallet'**
  String get crear_factura_label;

  /// No description provided for @amount_sats_label.
  ///
  /// In en, this message translates to:
  /// **'Request Amount'**
  String get amount_sats_label;

  /// No description provided for @amount_label.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount_label;

  /// No description provided for @currency_label.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency_label;

  /// No description provided for @description_label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description_label;

  /// No description provided for @amount_sats_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Enter amount in sats'**
  String get amount_sats_placeholder;

  /// No description provided for @description_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Optional description'**
  String get description_placeholder;

  /// No description provided for @optional_description_label.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get optional_description_label;

  /// No description provided for @copy_lightning_address.
  ///
  /// In en, this message translates to:
  /// **'Copy Lightning Address'**
  String get copy_lightning_address;

  /// No description provided for @copy_lnurl.
  ///
  /// In en, this message translates to:
  /// **'Copy LNURL'**
  String get copy_lnurl;

  /// No description provided for @generate_invoice_button.
  ///
  /// In en, this message translates to:
  /// **'Generate Invoice'**
  String get generate_invoice_button;

  /// No description provided for @generating_button.
  ///
  /// In en, this message translates to:
  /// **'GENERATING...'**
  String get generating_button;

  /// No description provided for @invoice_generated_message.
  ///
  /// In en, this message translates to:
  /// **'Invoice generated successfully'**
  String get invoice_generated_message;

  /// No description provided for @invoice_generation_error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Error generating invoice: '**
  String get invoice_generation_error_prefix;

  /// No description provided for @send_title.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send_title;

  /// No description provided for @paste_invoice_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Paste invoice, LNURL or address'**
  String get paste_invoice_placeholder;

  /// No description provided for @paste_button.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste_button;

  /// No description provided for @scan_button.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan_button;

  /// No description provided for @voucher_scan_title.
  ///
  /// In en, this message translates to:
  /// **'Scan Voucher'**
  String get voucher_scan_title;

  /// No description provided for @voucher_scan_instructions.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the LNURL-withdraw voucher QR code'**
  String get voucher_scan_instructions;

  /// No description provided for @voucher_scan_subtitle.
  ///
  /// In en, this message translates to:
  /// **'The app will automatically detect the voucher and allow you to claim it'**
  String get voucher_scan_subtitle;

  /// No description provided for @voucher_scan_button.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get voucher_scan_button;

  /// No description provided for @voucher_tap_to_scan.
  ///
  /// In en, this message translates to:
  /// **'Tap to open camera'**
  String get voucher_tap_to_scan;

  /// No description provided for @voucher_manual_input.
  ///
  /// In en, this message translates to:
  /// **'Enter code manually'**
  String get voucher_manual_input;

  /// No description provided for @voucher_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get voucher_processing;

  /// No description provided for @voucher_manual_input_hint.
  ///
  /// In en, this message translates to:
  /// **'Paste the LNURL-withdraw voucher code:'**
  String get voucher_manual_input_hint;

  /// No description provided for @voucher_manual_input_placeholder.
  ///
  /// In en, this message translates to:
  /// **'lnurl1...'**
  String get voucher_manual_input_placeholder;

  /// No description provided for @process_button.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get process_button;

  /// No description provided for @voucher_detected_title.
  ///
  /// In en, this message translates to:
  /// **'Voucher Detected'**
  String get voucher_detected_title;

  /// No description provided for @voucher_fixed_amount.
  ///
  /// In en, this message translates to:
  /// **'Fixed amount:'**
  String get voucher_fixed_amount;

  /// No description provided for @voucher_amount_range.
  ///
  /// In en, this message translates to:
  /// **'Available range:'**
  String get voucher_amount_range;

  /// No description provided for @voucher_amount_to_claim.
  ///
  /// In en, this message translates to:
  /// **'Amount to claim:'**
  String get voucher_amount_to_claim;

  /// No description provided for @voucher_min_max_hint.
  ///
  /// In en, this message translates to:
  /// **'Min: {min} sats • Max: {max} sats'**
  String voucher_min_max_hint(int min, int max);

  /// No description provided for @voucher_claim_button.
  ///
  /// In en, this message translates to:
  /// **'Claim Voucher'**
  String get voucher_claim_button;

  /// No description provided for @voucher_amount_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount. Must be between {min} and {max} sats'**
  String voucher_amount_invalid(int min, int max);

  /// No description provided for @voucher_claimed_title.
  ///
  /// In en, this message translates to:
  /// **'Voucher claimed!'**
  String get voucher_claimed_title;

  /// No description provided for @voucher_claimed_subtitle.
  ///
  /// In en, this message translates to:
  /// **'The funds will appear in your wallet shortly.'**
  String get voucher_claimed_subtitle;

  /// No description provided for @voucher_invalid_code.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get voucher_invalid_code;

  /// No description provided for @voucher_not_valid_lnurl.
  ///
  /// In en, this message translates to:
  /// **'The scanned code is not a valid LNURL-withdraw voucher.'**
  String get voucher_not_valid_lnurl;

  /// No description provided for @voucher_processing_error.
  ///
  /// In en, this message translates to:
  /// **'Error processing voucher'**
  String get voucher_processing_error;

  /// No description provided for @voucher_already_claimed.
  ///
  /// In en, this message translates to:
  /// **'Voucher already claimed'**
  String get voucher_already_claimed;

  /// No description provided for @voucher_already_claimed_desc.
  ///
  /// In en, this message translates to:
  /// **'This voucher has already been used and cannot be claimed again.'**
  String get voucher_already_claimed_desc;

  /// No description provided for @voucher_expired.
  ///
  /// In en, this message translates to:
  /// **'Voucher expired'**
  String get voucher_expired;

  /// No description provided for @voucher_expired_desc.
  ///
  /// In en, this message translates to:
  /// **'This voucher has expired and is no longer valid.'**
  String get voucher_expired_desc;

  /// No description provided for @voucher_not_found.
  ///
  /// In en, this message translates to:
  /// **'Voucher not found'**
  String get voucher_not_found;

  /// No description provided for @voucher_not_found_desc.
  ///
  /// In en, this message translates to:
  /// **'This voucher could not be found or may have been removed.'**
  String get voucher_not_found_desc;

  /// No description provided for @voucher_server_error.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get voucher_server_error;

  /// No description provided for @voucher_server_error_desc.
  ///
  /// In en, this message translates to:
  /// **'There was a problem with the voucher server. Please try again later.'**
  String get voucher_server_error_desc;

  /// No description provided for @voucher_connection_error.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get voucher_connection_error;

  /// No description provided for @voucher_connection_error_desc.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get voucher_connection_error_desc;

  /// No description provided for @voucher_invalid_amount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get voucher_invalid_amount;

  /// No description provided for @voucher_invalid_amount_desc.
  ///
  /// In en, this message translates to:
  /// **'The voucher amount is not valid or has been corrupted.'**
  String get voucher_invalid_amount_desc;

  /// No description provided for @voucher_insufficient_funds.
  ///
  /// In en, this message translates to:
  /// **'Insufficient funds'**
  String get voucher_insufficient_funds;

  /// No description provided for @voucher_insufficient_funds_desc.
  ///
  /// In en, this message translates to:
  /// **'The voucher does not have enough funds available.'**
  String get voucher_insufficient_funds_desc;

  /// No description provided for @voucher_generic_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to process voucher'**
  String get voucher_generic_error;

  /// No description provided for @voucher_generic_error_desc.
  ///
  /// In en, this message translates to:
  /// **'There was an unexpected error processing this voucher. Please try again or contact support.'**
  String get voucher_generic_error_desc;

  /// No description provided for @pay_button.
  ///
  /// In en, this message translates to:
  /// **'PAY'**
  String get pay_button;

  /// No description provided for @processing_button.
  ///
  /// In en, this message translates to:
  /// **'PROCESSING...'**
  String get processing_button;

  /// No description provided for @payment_instruction_text.
  ///
  /// In en, this message translates to:
  /// **'Paste a Lightning invoice, LNURL or address'**
  String get payment_instruction_text;

  /// No description provided for @payment_processing_error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Error processing payment: '**
  String get payment_processing_error_prefix;

  /// No description provided for @no_active_session_error.
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get no_active_session_error;

  /// No description provided for @no_primary_wallet_error.
  ///
  /// In en, this message translates to:
  /// **'No primary wallet available'**
  String get no_primary_wallet_error;

  /// No description provided for @invoice_decoding_error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Error decoding invoice: '**
  String get invoice_decoding_error_prefix;

  /// No description provided for @send_to_title.
  ///
  /// In en, this message translates to:
  /// **'Send to'**
  String get send_to_title;

  /// No description provided for @clear_button.
  ///
  /// In en, this message translates to:
  /// **'C'**
  String get clear_button;

  /// No description provided for @decimal_button.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get decimal_button;

  /// No description provided for @calculating_text.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating_text;

  /// No description provided for @loading_rates_text.
  ///
  /// In en, this message translates to:
  /// **'Loading rates...'**
  String get loading_rates_text;

  /// No description provided for @send_button_prefix.
  ///
  /// In en, this message translates to:
  /// **'SEND '**
  String get send_button_prefix;

  /// No description provided for @amount_processing_button.
  ///
  /// In en, this message translates to:
  /// **'PROCESSING...'**
  String get amount_processing_button;

  /// No description provided for @exchange_rates_error.
  ///
  /// In en, this message translates to:
  /// **'Error loading exchange rates'**
  String get exchange_rates_error;

  /// No description provided for @invalid_amount_error.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get invalid_amount_error;

  /// No description provided for @amount_payment_error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Error processing payment: '**
  String get amount_payment_error_prefix;

  /// No description provided for @amount_no_session_error.
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get amount_no_session_error;

  /// No description provided for @amount_no_wallet_error.
  ///
  /// In en, this message translates to:
  /// **'No primary wallet available'**
  String get amount_no_wallet_error;

  /// No description provided for @sending_lnurl_payment.
  ///
  /// In en, this message translates to:
  /// **'Sending LNURL payment...'**
  String get sending_lnurl_payment;

  /// No description provided for @sending_lightning_payment.
  ///
  /// In en, this message translates to:
  /// **'Sending Lightning Address payment...'**
  String get sending_lightning_payment;

  /// No description provided for @lnurl_payment_pending.
  ///
  /// In en, this message translates to:
  /// **'LNURL payment pending - Hold invoice detected'**
  String get lnurl_payment_pending;

  /// No description provided for @lnurl_payment_success.
  ///
  /// In en, this message translates to:
  /// **'LNURL payment completed successfully!'**
  String get lnurl_payment_success;

  /// No description provided for @lightning_payment_pending.
  ///
  /// In en, this message translates to:
  /// **'Lightning Address payment pending - Hold invoice detected'**
  String get lightning_payment_pending;

  /// No description provided for @lightning_payment_success.
  ///
  /// In en, this message translates to:
  /// **'Lightning Address payment completed successfully!'**
  String get lightning_payment_success;

  /// No description provided for @insufficient_balance_error.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance to make payment'**
  String get insufficient_balance_error;

  /// No description provided for @confirm_payment_title.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirm_payment_title;

  /// No description provided for @invoice_description_label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get invoice_description_label;

  /// No description provided for @no_description_text.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get no_description_text;

  /// No description provided for @invoice_status_label.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get invoice_status_label;

  /// No description provided for @expired_status.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired_status;

  /// No description provided for @valid_status.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get valid_status;

  /// No description provided for @expiration_label.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get expiration_label;

  /// No description provided for @payment_hash_label.
  ///
  /// In en, this message translates to:
  /// **'Payment Hash'**
  String get payment_hash_label;

  /// No description provided for @recipient_label.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient_label;

  /// No description provided for @cancel_button_confirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel_button_confirm;

  /// No description provided for @pay_button_confirm.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay_button_confirm;

  /// No description provided for @confirm_button.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm_button;

  /// No description provided for @expired_button_text.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired_button_text;

  /// No description provided for @sending_button.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending_button;

  /// No description provided for @invoice_expired_error.
  ///
  /// In en, this message translates to:
  /// **'The invoice has expired and cannot be paid'**
  String get invoice_expired_error;

  /// No description provided for @amountless_invoice_error.
  ///
  /// In en, this message translates to:
  /// **'Invoice without amount not supported. Please request an invoice with a specific amount.'**
  String get amountless_invoice_error;

  /// No description provided for @payment_sent_status.
  ///
  /// In en, this message translates to:
  /// **'Payment sent - Status: {status}'**
  String payment_sent_status(String status);

  /// No description provided for @confirm_no_session_error.
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get confirm_no_session_error;

  /// No description provided for @confirm_no_wallet_error.
  ///
  /// In en, this message translates to:
  /// **'No primary wallet available'**
  String get confirm_no_wallet_error;

  /// No description provided for @payment_pending_hold.
  ///
  /// In en, this message translates to:
  /// **'Payment pending - Hold invoice detected'**
  String get payment_pending_hold;

  /// No description provided for @payment_completed_success.
  ///
  /// In en, this message translates to:
  /// **'Payment completed successfully'**
  String get payment_completed_success;

  /// No description provided for @payment_sent_status_prefix.
  ///
  /// In en, this message translates to:
  /// **'Payment sent - Status: '**
  String get payment_sent_status_prefix;

  /// No description provided for @payment_sending_error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Error sending payment: '**
  String get payment_sending_error_prefix;

  /// No description provided for @language_selector_title.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language_selector_title;

  /// No description provided for @language_selector_description.
  ///
  /// In en, this message translates to:
  /// **'Change application language'**
  String get language_selector_description;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get select_language;

  /// No description provided for @no_wallet_error.
  ///
  /// In en, this message translates to:
  /// **'No primary wallet available'**
  String get no_wallet_error;

  /// No description provided for @invalid_session_error.
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get invalid_session_error;

  /// No description provided for @send_error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Error processing send: '**
  String get send_error_prefix;

  /// No description provided for @decode_invoice_error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Error decoding invoice: '**
  String get decode_invoice_error_prefix;

  /// No description provided for @payment_success.
  ///
  /// In en, this message translates to:
  /// **'Payment completed successfully'**
  String get payment_success;

  /// No description provided for @expiry_label.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get expiry_label;

  /// No description provided for @processing_text.
  ///
  /// In en, this message translates to:
  /// **'processing'**
  String get processing_text;

  /// No description provided for @paste_input_hint.
  ///
  /// In en, this message translates to:
  /// **'Paste invoice, LNURL or address'**
  String get paste_input_hint;

  /// No description provided for @conversion_rate_error.
  ///
  /// In en, this message translates to:
  /// **'Error loading exchange rates'**
  String get conversion_rate_error;

  /// No description provided for @instant_payments_feature.
  ///
  /// In en, this message translates to:
  /// **'Instant payments'**
  String get instant_payments_feature;

  /// No description provided for @favorite_server_feature.
  ///
  /// In en, this message translates to:
  /// **'With your favorite server'**
  String get favorite_server_feature;

  /// No description provided for @receive_info_text.
  ///
  /// In en, this message translates to:
  /// **'• Share your Lightning Address to receive payments of any amount\n\n• QR code automatically resolves to LNURL for maximum compatibility\n\n• Payments are received directly in this wallet'**
  String get receive_info_text;

  /// No description provided for @payment_description_example.
  ///
  /// In en, this message translates to:
  /// **'Ex: Payment for services'**
  String get payment_description_example;

  /// No description provided for @remember_password_label.
  ///
  /// In en, this message translates to:
  /// **'Remember password'**
  String get remember_password_label;

  /// No description provided for @server_prefix.
  ///
  /// In en, this message translates to:
  /// **'Server: '**
  String get server_prefix;

  /// No description provided for @login_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials to access your wallet'**
  String get login_subtitle;

  /// No description provided for @username_required_error.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get username_required_error;

  /// No description provided for @username_length_error.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get username_length_error;

  /// No description provided for @password_required_error.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get password_required_error;

  /// No description provided for @password_length_error.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get password_length_error;

  /// No description provided for @saved_users_header.
  ///
  /// In en, this message translates to:
  /// **'Saved users'**
  String get saved_users_header;

  /// No description provided for @tap_to_autocomplete_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap to autocomplete password'**
  String get tap_to_autocomplete_hint;

  /// No description provided for @delete_credentials_title.
  ///
  /// In en, this message translates to:
  /// **'Delete credentials'**
  String get delete_credentials_title;

  /// No description provided for @delete_credentials_message.
  ///
  /// In en, this message translates to:
  /// **'By unchecking this option, saved credentials for this user will be deleted.\\n\\nAre you sure you want to continue?'**
  String get delete_credentials_message;

  /// No description provided for @delete_credentials_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get delete_credentials_cancel;

  /// No description provided for @delete_credentials_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete_credentials_confirm;

  /// No description provided for @close_dialog.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close_dialog;

  /// No description provided for @credentials_found_message.
  ///
  /// In en, this message translates to:
  /// **'Credentials found - password will be remembered'**
  String get credentials_found_message;

  /// No description provided for @password_will_be_remembered.
  ///
  /// In en, this message translates to:
  /// **'Password will be remembered after login'**
  String get password_will_be_remembered;

  /// No description provided for @password_saved_successfully.
  ///
  /// In en, this message translates to:
  /// **'Password saved successfully'**
  String get password_saved_successfully;

  /// No description provided for @password_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save password'**
  String get password_save_failed;

  /// No description provided for @about_app_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Lightning Wallet'**
  String get about_app_subtitle;

  /// No description provided for @about_app_description.
  ///
  /// In en, this message translates to:
  /// **'A mobile application to manage Bitcoin through Lightning Network using LNBits as backend.'**
  String get about_app_description;

  /// No description provided for @lightning_address_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get lightning_address_copy;

  /// No description provided for @lightning_address_default.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get lightning_address_default;

  /// No description provided for @lightning_address_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get lightning_address_delete;

  /// No description provided for @lightning_address_is_default.
  ///
  /// In en, this message translates to:
  /// **'Is default'**
  String get lightning_address_is_default;

  /// No description provided for @lightning_address_set_default.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get lightning_address_set_default;

  /// No description provided for @create_new_wallet_help.
  ///
  /// In en, this message translates to:
  /// **'Create new wallet'**
  String get create_new_wallet_help;

  /// No description provided for @create_wallet_short_description.
  ///
  /// In en, this message translates to:
  /// **'To create a new wallet, access your LNBits panel from the browser and use the \"Create wallet\" option.'**
  String get create_wallet_short_description;

  /// No description provided for @create_wallet_detailed_instructions.
  ///
  /// In en, this message translates to:
  /// **'To create a new wallet:\\n\\n1. Open your web browser\\n2. Access your LNBits server\\n3. Log in with your account\\n4. Look for the \"Create wallet\" button\\n5. Assign a name to your new wallet\\n6. Return to LaChispa and refresh your wallets\\n\\nThe new wallet will appear automatically in your list.'**
  String get create_wallet_detailed_instructions;

  /// No description provided for @fixed_float_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading Fixed Float...'**
  String get fixed_float_loading;

  /// No description provided for @fixed_float_description.
  ///
  /// In en, this message translates to:
  /// **'Exchange cryptocurrencies with\nfixed rates and no registration'**
  String get fixed_float_description;

  /// No description provided for @fixed_float_webview_error.
  ///
  /// In en, this message translates to:
  /// **'WebView not available on this platform.\nWill open in external browser.'**
  String get fixed_float_webview_error;

  /// No description provided for @fixed_float_open_button.
  ///
  /// In en, this message translates to:
  /// **'Open Fixed Float'**
  String get fixed_float_open_button;

  /// No description provided for @fixed_float_error_opening.
  ///
  /// In en, this message translates to:
  /// **'Error opening Fixed Float: {error}'**
  String fixed_float_error_opening(String error);

  /// No description provided for @fixed_float_external_browser.
  ///
  /// In en, this message translates to:
  /// **'Will open Fixed Float in external browser'**
  String get fixed_float_external_browser;

  /// No description provided for @fixed_float_within_app.
  ///
  /// In en, this message translates to:
  /// **'Opens Fixed Float within the app'**
  String get fixed_float_within_app;

  /// No description provided for @boltz_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading Boltz...'**
  String get boltz_loading;

  /// No description provided for @boltz_description.
  ///
  /// In en, this message translates to:
  /// **'Trustless Bitcoin and Lightning\natomic swaps'**
  String get boltz_description;

  /// No description provided for @boltz_webview_error.
  ///
  /// In en, this message translates to:
  /// **'WebView not available on this platform.\nWill open in external browser.'**
  String get boltz_webview_error;

  /// No description provided for @boltz_open_button.
  ///
  /// In en, this message translates to:
  /// **'Open Boltz'**
  String get boltz_open_button;

  /// No description provided for @boltz_error_opening.
  ///
  /// In en, this message translates to:
  /// **'Error opening Boltz: {error}'**
  String boltz_error_opening(String error);

  /// No description provided for @boltz_external_browser.
  ///
  /// In en, this message translates to:
  /// **'Will open Boltz in external browser'**
  String get boltz_external_browser;

  /// No description provided for @boltz_within_app.
  ///
  /// In en, this message translates to:
  /// **'Opens Boltz within the app'**
  String get boltz_within_app;

  /// No description provided for @add_note_optional.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get add_note_optional;

  /// No description provided for @currency_settings_title.
  ///
  /// In en, this message translates to:
  /// **'Currency Selection'**
  String get currency_settings_title;

  /// No description provided for @currency_settings_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred currencies'**
  String get currency_settings_subtitle;

  /// No description provided for @available_currencies.
  ///
  /// In en, this message translates to:
  /// **'Available Currencies'**
  String get available_currencies;

  /// No description provided for @selected_currencies.
  ///
  /// In en, this message translates to:
  /// **'Selected Currencies'**
  String get selected_currencies;

  /// No description provided for @no_currencies_available.
  ///
  /// In en, this message translates to:
  /// **'No currencies available from server'**
  String get no_currencies_available;

  /// No description provided for @select_currencies_hint.
  ///
  /// In en, this message translates to:
  /// **'Select currencies from the list above'**
  String get select_currencies_hint;

  /// No description provided for @preview_title.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview_title;

  /// No description provided for @tap_to_cycle.
  ///
  /// In en, this message translates to:
  /// **'Tap to cycle currencies'**
  String get tap_to_cycle;

  /// No description provided for @settings_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_screen_title;

  /// No description provided for @about_title.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about_title;

  /// No description provided for @currency_validation_info.
  ///
  /// In en, this message translates to:
  /// **'When selecting a currency, it will be verified if it\'s available on this server'**
  String get currency_validation_info;

  /// No description provided for @checking_currency_availability.
  ///
  /// In en, this message translates to:
  /// **'Checking {currency} availability...'**
  String checking_currency_availability(Object currency);

  /// No description provided for @currency_added_successfully.
  ///
  /// In en, this message translates to:
  /// **'{currency} added successfully'**
  String currency_added_successfully(Object currency);

  /// No description provided for @currency_not_available_on_server.
  ///
  /// In en, this message translates to:
  /// **'{currencyName} ({currency}) is not available on this server'**
  String currency_not_available_on_server(Object currency, Object currencyName);

  /// No description provided for @error_checking_currency.
  ///
  /// In en, this message translates to:
  /// **'Error checking {currency}: {error}'**
  String error_checking_currency(Object currency, Object error);

  /// No description provided for @deep_link_login_required_title.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get deep_link_login_required_title;

  /// No description provided for @deep_link_login_required_message.
  ///
  /// In en, this message translates to:
  /// **'You must log in to your LaChispa account to process this payment.'**
  String get deep_link_login_required_message;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'it',
        'pt',
        'ru'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
