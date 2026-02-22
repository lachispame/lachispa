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
    Locale('ru'),
  ];

  /// No description provided for @welcome_title.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido a La Chispa!'**
  String get welcome_title;

  /// No description provided for @welcome_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Lightning para todos'**
  String get welcome_subtitle;

  /// No description provided for @get_started_button.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get get_started_button;

  /// No description provided for @tap_to_start_hint.
  ///
  /// In es, this message translates to:
  /// **'Tan fácil como encender una chispa'**
  String get tap_to_start_hint;

  /// No description provided for @choose_option_title.
  ///
  /// In es, this message translates to:
  /// **'Conecta con tu servidor LNBits favorito'**
  String get choose_option_title;

  /// No description provided for @create_new_wallet_title.
  ///
  /// In es, this message translates to:
  /// **'Crear Nueva Billetera'**
  String get create_new_wallet_title;

  /// No description provided for @create_new_wallet_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Configurar tu propia billetera Lightning'**
  String get create_new_wallet_subtitle;

  /// No description provided for @use_existing_wallet_title.
  ///
  /// In es, this message translates to:
  /// **'Usar Billetera Existente'**
  String get use_existing_wallet_title;

  /// No description provided for @use_existing_wallet_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Conectar a una billetera Lightning'**
  String get use_existing_wallet_subtitle;

  /// No description provided for @server_settings_title.
  ///
  /// In es, this message translates to:
  /// **'Servidor actual'**
  String get server_settings_title;

  /// No description provided for @change_server_button.
  ///
  /// In es, this message translates to:
  /// **'Cambiar servidor'**
  String get change_server_button;

  /// No description provided for @server_url_label.
  ///
  /// In es, this message translates to:
  /// **'URL del Servidor'**
  String get server_url_label;

  /// No description provided for @admin_label.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get admin_label;

  /// No description provided for @admin_key_label.
  ///
  /// In es, this message translates to:
  /// **'Clave de Administrador'**
  String get admin_key_label;

  /// No description provided for @invoice_key_label.
  ///
  /// In es, this message translates to:
  /// **'Clave de Facturación'**
  String get invoice_key_label;

  /// No description provided for @server_url_placeholder.
  ///
  /// In es, this message translates to:
  /// **'https://demo.lnbits.com'**
  String get server_url_placeholder;

  /// No description provided for @admin_key_placeholder.
  ///
  /// In es, this message translates to:
  /// **'Ingresa la clave de administrador'**
  String get admin_key_placeholder;

  /// No description provided for @invoice_key_placeholder.
  ///
  /// In es, this message translates to:
  /// **'Ingresa la clave de facturación'**
  String get invoice_key_placeholder;

  /// No description provided for @connect_button.
  ///
  /// In es, this message translates to:
  /// **'Conectar'**
  String get connect_button;

  /// No description provided for @connecting_button.
  ///
  /// In es, this message translates to:
  /// **'CONECTANDO...'**
  String get connecting_button;

  /// No description provided for @connection_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión: '**
  String get connection_error_prefix;

  /// No description provided for @login_title.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get login_title;

  /// No description provided for @username_label.
  ///
  /// In es, this message translates to:
  /// **'Nombre de Usuario'**
  String get username_label;

  /// No description provided for @password_label.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password_label;

  /// No description provided for @username_placeholder.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu nombre de usuario'**
  String get username_placeholder;

  /// No description provided for @password_placeholder.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu contraseña'**
  String get password_placeholder;

  /// No description provided for @login_button.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get login_button;

  /// No description provided for @logging_in_button.
  ///
  /// In es, this message translates to:
  /// **'INICIANDO SESIÓN...'**
  String get logging_in_button;

  /// No description provided for @no_account_question.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? '**
  String get no_account_question;

  /// No description provided for @register_link.
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get register_link;

  /// No description provided for @login_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Error en el inicio de sesión: '**
  String get login_error_prefix;

  /// No description provided for @create_account_title.
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get create_account_title;

  /// No description provided for @signup_username_label.
  ///
  /// In es, this message translates to:
  /// **'Nombre de Usuario'**
  String get signup_username_label;

  /// No description provided for @signup_password_label.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get signup_password_label;

  /// No description provided for @confirm_password_label.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Contraseña'**
  String get confirm_password_label;

  /// No description provided for @signup_username_placeholder.
  ///
  /// In es, this message translates to:
  /// **'Introduce un nombre de usuario'**
  String get signup_username_placeholder;

  /// No description provided for @signup_password_placeholder.
  ///
  /// In es, this message translates to:
  /// **'Introduce una contraseña'**
  String get signup_password_placeholder;

  /// No description provided for @confirm_password_placeholder.
  ///
  /// In es, this message translates to:
  /// **'Repite tu contraseña'**
  String get confirm_password_placeholder;

  /// No description provided for @create_account_button.
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get create_account_button;

  /// No description provided for @creating_account_button.
  ///
  /// In es, this message translates to:
  /// **'CREANDO CUENTA...'**
  String get creating_account_button;

  /// No description provided for @already_have_account_question.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? '**
  String get already_have_account_question;

  /// No description provided for @login_link.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get login_link;

  /// No description provided for @passwords_mismatch_error.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get passwords_mismatch_error;

  /// No description provided for @account_creation_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Error al crear cuenta: '**
  String get account_creation_error_prefix;

  /// No description provided for @wallet_title.
  ///
  /// In es, this message translates to:
  /// **'Billetera'**
  String get wallet_title;

  /// No description provided for @balance_label.
  ///
  /// In es, this message translates to:
  /// **'Saldo'**
  String get balance_label;

  /// No description provided for @receive_button.
  ///
  /// In es, this message translates to:
  /// **'Recibir'**
  String get receive_button;

  /// No description provided for @send_button.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get send_button;

  /// No description provided for @history_button.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get history_button;

  /// No description provided for @settings_button.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settings_button;

  /// No description provided for @loading_text.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading_text;

  /// No description provided for @history_title.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get history_title;

  /// No description provided for @loading_transactions_text.
  ///
  /// In es, this message translates to:
  /// **'Cargando transacciones...'**
  String get loading_transactions_text;

  /// No description provided for @no_transactions_text.
  ///
  /// In es, this message translates to:
  /// **'No hay transacciones'**
  String get no_transactions_text;

  /// No description provided for @no_transactions_description.
  ///
  /// In es, this message translates to:
  /// **'Aún no has realizado ninguna transacción.'**
  String get no_transactions_description;

  /// No description provided for @sent_label.
  ///
  /// In es, this message translates to:
  /// **'Enviado'**
  String get sent_label;

  /// No description provided for @received_label.
  ///
  /// In es, this message translates to:
  /// **'Recibido'**
  String get received_label;

  /// No description provided for @pending_label.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get pending_label;

  /// No description provided for @failed_label.
  ///
  /// In es, this message translates to:
  /// **'Fallida'**
  String get failed_label;

  /// No description provided for @loading_transactions_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Error cargando transacciones: '**
  String get loading_transactions_error_prefix;

  /// No description provided for @lightning_address_title.
  ///
  /// In es, this message translates to:
  /// **'Dirección Lightning'**
  String get lightning_address_title;

  /// No description provided for @loading_address_text.
  ///
  /// In es, this message translates to:
  /// **'Cargando dirección...'**
  String get loading_address_text;

  /// No description provided for @your_lightning_address_label.
  ///
  /// In es, this message translates to:
  /// **'Tu dirección Lightning:'**
  String get your_lightning_address_label;

  /// No description provided for @not_available_text.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get not_available_text;

  /// No description provided for @share_button.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get share_button;

  /// No description provided for @copy_button.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get copy_button;

  /// No description provided for @address_copied_message.
  ///
  /// In es, this message translates to:
  /// **'Dirección copiada al portapapeles'**
  String get address_copied_message;

  /// No description provided for @loading_address_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Error cargando dirección Lightning: '**
  String get loading_address_error_prefix;

  /// No description provided for @settings_title.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get settings_title;

  /// No description provided for @lightning_address_option.
  ///
  /// In es, this message translates to:
  /// **'Dirección Lightning'**
  String get lightning_address_option;

  /// No description provided for @lightning_address_description.
  ///
  /// In es, this message translates to:
  /// **'Ver tu dirección Lightning'**
  String get lightning_address_description;

  /// No description provided for @logout_option.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Sesión'**
  String get logout_option;

  /// No description provided for @logout_description.
  ///
  /// In es, this message translates to:
  /// **'Desconectar de la cuenta actual'**
  String get logout_description;

  /// No description provided for @confirm_logout_title.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Cierre de Sesión'**
  String get confirm_logout_title;

  /// No description provided for @confirm_logout_message.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cerrar sesión?'**
  String get confirm_logout_message;

  /// No description provided for @cancel_button.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel_button;

  /// No description provided for @logout_confirm_button.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Sesión'**
  String get logout_confirm_button;

  /// No description provided for @receive_title.
  ///
  /// In es, this message translates to:
  /// **'Recibir'**
  String get receive_title;

  /// No description provided for @amount_sats_label.
  ///
  /// In es, this message translates to:
  /// **'Solicitar Monto'**
  String get amount_sats_label;

  /// No description provided for @amount_label.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get amount_label;

  /// No description provided for @currency_label.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get currency_label;

  /// No description provided for @description_label.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get description_label;

  /// No description provided for @amount_sats_placeholder.
  ///
  /// In es, this message translates to:
  /// **'Introduce el monto en sats'**
  String get amount_sats_placeholder;

  /// No description provided for @description_placeholder.
  ///
  /// In es, this message translates to:
  /// **'Descripción opcional'**
  String get description_placeholder;

  /// No description provided for @optional_description_label.
  ///
  /// In es, this message translates to:
  /// **'Descripción (Opcional)'**
  String get optional_description_label;

  /// No description provided for @copy_lightning_address.
  ///
  /// In es, this message translates to:
  /// **'Copiar Lightning Address'**
  String get copy_lightning_address;

  /// No description provided for @copy_lnurl.
  ///
  /// In es, this message translates to:
  /// **'Copiar LNURL'**
  String get copy_lnurl;

  /// No description provided for @generate_invoice_button.
  ///
  /// In es, this message translates to:
  /// **'Generar Factura'**
  String get generate_invoice_button;

  /// No description provided for @generating_button.
  ///
  /// In es, this message translates to:
  /// **'GENERANDO...'**
  String get generating_button;

  /// No description provided for @invoice_generated_message.
  ///
  /// In es, this message translates to:
  /// **'Factura generada correctamente'**
  String get invoice_generated_message;

  /// No description provided for @invoice_generation_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Error generando factura: '**
  String get invoice_generation_error_prefix;

  /// No description provided for @send_title.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get send_title;

  /// No description provided for @paste_invoice_placeholder.
  ///
  /// In es, this message translates to:
  /// **'Pega factura, LNURL o dirección'**
  String get paste_invoice_placeholder;

  /// No description provided for @paste_button.
  ///
  /// In es, this message translates to:
  /// **'Pegar'**
  String get paste_button;

  /// No description provided for @scan_button.
  ///
  /// In es, this message translates to:
  /// **'Escanear'**
  String get scan_button;

  /// No description provided for @voucher_scan_title.
  ///
  /// In es, this message translates to:
  /// **'Escanear Voucher'**
  String get voucher_scan_title;

  /// No description provided for @voucher_scan_instructions.
  ///
  /// In es, this message translates to:
  /// **'Apunta tu cámara al código QR del voucher LNURL-withdraw'**
  String get voucher_scan_instructions;

  /// No description provided for @voucher_scan_subtitle.
  ///
  /// In es, this message translates to:
  /// **'La aplicación detectará automáticamente el voucher y te permitirá cobrarlo'**
  String get voucher_scan_subtitle;

  /// No description provided for @voucher_scan_button.
  ///
  /// In es, this message translates to:
  /// **'Escanear QR'**
  String get voucher_scan_button;

  /// No description provided for @voucher_tap_to_scan.
  ///
  /// In es, this message translates to:
  /// **'Toca para abrir la cámara'**
  String get voucher_tap_to_scan;

  /// No description provided for @voucher_manual_input.
  ///
  /// In es, this message translates to:
  /// **'Introducir código manualmente'**
  String get voucher_manual_input;

  /// No description provided for @voucher_processing.
  ///
  /// In es, this message translates to:
  /// **'Procesando...'**
  String get voucher_processing;

  /// No description provided for @voucher_manual_input_hint.
  ///
  /// In es, this message translates to:
  /// **'Pega el código LNURL-withdraw del voucher:'**
  String get voucher_manual_input_hint;

  /// No description provided for @voucher_manual_input_placeholder.
  ///
  /// In es, this message translates to:
  /// **'lnurl1...'**
  String get voucher_manual_input_placeholder;

  /// No description provided for @process_button.
  ///
  /// In es, this message translates to:
  /// **'Procesar'**
  String get process_button;

  /// No description provided for @voucher_detected_title.
  ///
  /// In es, this message translates to:
  /// **'Voucher Detectado'**
  String get voucher_detected_title;

  /// No description provided for @voucher_fixed_amount.
  ///
  /// In es, this message translates to:
  /// **'Cantidad fija:'**
  String get voucher_fixed_amount;

  /// No description provided for @voucher_amount_range.
  ///
  /// In es, this message translates to:
  /// **'Rango disponible:'**
  String get voucher_amount_range;

  /// No description provided for @voucher_amount_to_claim.
  ///
  /// In es, this message translates to:
  /// **'Cantidad a cobrar:'**
  String get voucher_amount_to_claim;

  /// No description provided for @voucher_min_max_hint.
  ///
  /// In es, this message translates to:
  /// **'Mínimo: {min} sats • Máximo: {max} sats'**
  String voucher_min_max_hint(int min, int max);

  /// No description provided for @voucher_claim_button.
  ///
  /// In es, this message translates to:
  /// **'Cobrar Voucher'**
  String get voucher_claim_button;

  /// No description provided for @voucher_amount_invalid.
  ///
  /// In es, this message translates to:
  /// **'Cantidad inválida. Debe estar entre {min} y {max} sats'**
  String voucher_amount_invalid(int min, int max);

  /// No description provided for @voucher_claimed_title.
  ///
  /// In es, this message translates to:
  /// **'¡Voucher cobrado!'**
  String get voucher_claimed_title;

  /// No description provided for @voucher_claimed_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Los fondos aparecerán en tu wallet en unos momentos.'**
  String get voucher_claimed_subtitle;

  /// No description provided for @voucher_invalid_code.
  ///
  /// In es, this message translates to:
  /// **'Código no válido'**
  String get voucher_invalid_code;

  /// No description provided for @voucher_not_valid_lnurl.
  ///
  /// In es, this message translates to:
  /// **'El código escaneado no es un voucher LNURL-withdraw válido.'**
  String get voucher_not_valid_lnurl;

  /// No description provided for @voucher_processing_error.
  ///
  /// In es, this message translates to:
  /// **'Error procesando el voucher'**
  String get voucher_processing_error;

  /// No description provided for @voucher_already_claimed.
  ///
  /// In es, this message translates to:
  /// **'Voucher ya cobrado'**
  String get voucher_already_claimed;

  /// No description provided for @voucher_already_claimed_desc.
  ///
  /// In es, this message translates to:
  /// **'Este voucher ya fue usado y no puede ser cobrado nuevamente.'**
  String get voucher_already_claimed_desc;

  /// No description provided for @voucher_expired.
  ///
  /// In es, this message translates to:
  /// **'Voucher expirado'**
  String get voucher_expired;

  /// No description provided for @voucher_expired_desc.
  ///
  /// In es, this message translates to:
  /// **'Este voucher ha expirado y ya no es válido.'**
  String get voucher_expired_desc;

  /// No description provided for @voucher_not_found.
  ///
  /// In es, this message translates to:
  /// **'Voucher no encontrado'**
  String get voucher_not_found;

  /// No description provided for @voucher_not_found_desc.
  ///
  /// In es, this message translates to:
  /// **'Este voucher no pudo ser encontrado o puede haber sido eliminado.'**
  String get voucher_not_found_desc;

  /// No description provided for @voucher_server_error.
  ///
  /// In es, this message translates to:
  /// **'Error del servidor'**
  String get voucher_server_error;

  /// No description provided for @voucher_server_error_desc.
  ///
  /// In es, this message translates to:
  /// **'Hubo un problema con el servidor del voucher. Inténtalo de nuevo más tarde.'**
  String get voucher_server_error_desc;

  /// No description provided for @voucher_connection_error.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión'**
  String get voucher_connection_error;

  /// No description provided for @voucher_connection_error_desc.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu conexión a internet e inténtalo de nuevo.'**
  String get voucher_connection_error_desc;

  /// No description provided for @voucher_invalid_amount.
  ///
  /// In es, this message translates to:
  /// **'Cantidad inválida'**
  String get voucher_invalid_amount;

  /// No description provided for @voucher_invalid_amount_desc.
  ///
  /// In es, this message translates to:
  /// **'La cantidad del voucher no es válida o se ha corrompido.'**
  String get voucher_invalid_amount_desc;

  /// No description provided for @voucher_insufficient_funds.
  ///
  /// In es, this message translates to:
  /// **'Fondos insuficientes'**
  String get voucher_insufficient_funds;

  /// No description provided for @voucher_insufficient_funds_desc.
  ///
  /// In es, this message translates to:
  /// **'El voucher no tiene suficientes fondos disponibles.'**
  String get voucher_insufficient_funds_desc;

  /// No description provided for @voucher_generic_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo procesar el voucher'**
  String get voucher_generic_error;

  /// No description provided for @voucher_generic_error_desc.
  ///
  /// In es, this message translates to:
  /// **'Hubo un error inesperado procesando este voucher. Inténtalo de nuevo o contacta soporte.'**
  String get voucher_generic_error_desc;

  /// No description provided for @pay_button.
  ///
  /// In es, this message translates to:
  /// **'PAGAR'**
  String get pay_button;

  /// No description provided for @processing_button.
  ///
  /// In es, this message translates to:
  /// **'PROCESANDO...'**
  String get processing_button;

  /// No description provided for @payment_instruction_text.
  ///
  /// In es, this message translates to:
  /// **'Pega una factura Lightning, LNURL o dirección'**
  String get payment_instruction_text;

  /// No description provided for @payment_processing_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Error procesando el pago: '**
  String get payment_processing_error_prefix;

  /// No description provided for @no_active_session_error.
  ///
  /// In es, this message translates to:
  /// **'Sin sesión activa'**
  String get no_active_session_error;

  /// No description provided for @no_primary_wallet_error.
  ///
  /// In es, this message translates to:
  /// **'No hay wallet principal disponible'**
  String get no_primary_wallet_error;

  /// No description provided for @invoice_decoding_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Error decodificando factura: '**
  String get invoice_decoding_error_prefix;

  /// No description provided for @send_to_title.
  ///
  /// In es, this message translates to:
  /// **'Enviar a'**
  String get send_to_title;

  /// No description provided for @clear_button.
  ///
  /// In es, this message translates to:
  /// **'C'**
  String get clear_button;

  /// No description provided for @decimal_button.
  ///
  /// In es, this message translates to:
  /// **'.'**
  String get decimal_button;

  /// No description provided for @calculating_text.
  ///
  /// In es, this message translates to:
  /// **'Calculando...'**
  String get calculating_text;

  /// No description provided for @loading_rates_text.
  ///
  /// In es, this message translates to:
  /// **'Loading rates...'**
  String get loading_rates_text;

  /// No description provided for @send_button_prefix.
  ///
  /// In es, this message translates to:
  /// **'SEND '**
  String get send_button_prefix;

  /// No description provided for @amount_processing_button.
  ///
  /// In es, this message translates to:
  /// **'PROCESANDO...'**
  String get amount_processing_button;

  /// No description provided for @exchange_rates_error.
  ///
  /// In es, this message translates to:
  /// **'Error cargando tipos de cambio'**
  String get exchange_rates_error;

  /// No description provided for @invalid_amount_error.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa un monto válido'**
  String get invalid_amount_error;

  /// No description provided for @amount_payment_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Error procesando pago: '**
  String get amount_payment_error_prefix;

  /// No description provided for @amount_no_session_error.
  ///
  /// In es, this message translates to:
  /// **'Sin sesión activa'**
  String get amount_no_session_error;

  /// No description provided for @amount_no_wallet_error.
  ///
  /// In es, this message translates to:
  /// **'Sin billetera principal disponible'**
  String get amount_no_wallet_error;

  /// No description provided for @sending_lnurl_payment.
  ///
  /// In es, this message translates to:
  /// **'Enviando pago LNURL...'**
  String get sending_lnurl_payment;

  /// No description provided for @sending_lightning_payment.
  ///
  /// In es, this message translates to:
  /// **'Sending Lightning Address payment...'**
  String get sending_lightning_payment;

  /// No description provided for @lnurl_payment_pending.
  ///
  /// In es, this message translates to:
  /// **'Pago LNURL pendiente - Factura Hold detectada'**
  String get lnurl_payment_pending;

  /// No description provided for @lnurl_payment_success.
  ///
  /// In es, this message translates to:
  /// **'Pago LNURL completado exitosamente!'**
  String get lnurl_payment_success;

  /// No description provided for @lightning_payment_pending.
  ///
  /// In es, this message translates to:
  /// **'Pago Lightning Address pendiente - Factura Hold detectada'**
  String get lightning_payment_pending;

  /// No description provided for @lightning_payment_success.
  ///
  /// In es, this message translates to:
  /// **'Pago Lightning Address completado exitosamente!'**
  String get lightning_payment_success;

  /// No description provided for @insufficient_balance_error.
  ///
  /// In es, this message translates to:
  /// **'Saldo insuficiente para realizar el pago'**
  String get insufficient_balance_error;

  /// No description provided for @confirm_payment_title.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Pago'**
  String get confirm_payment_title;

  /// No description provided for @invoice_description_label.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get invoice_description_label;

  /// No description provided for @no_description_text.
  ///
  /// In es, this message translates to:
  /// **'Sin descripción'**
  String get no_description_text;

  /// No description provided for @invoice_status_label.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get invoice_status_label;

  /// No description provided for @expired_status.
  ///
  /// In es, this message translates to:
  /// **'Expirada'**
  String get expired_status;

  /// No description provided for @valid_status.
  ///
  /// In es, this message translates to:
  /// **'Válida'**
  String get valid_status;

  /// No description provided for @expiration_label.
  ///
  /// In es, this message translates to:
  /// **'Expiración'**
  String get expiration_label;

  /// No description provided for @payment_hash_label.
  ///
  /// In es, this message translates to:
  /// **'Hash de Pago'**
  String get payment_hash_label;

  /// No description provided for @recipient_label.
  ///
  /// In es, this message translates to:
  /// **'Destinatario'**
  String get recipient_label;

  /// No description provided for @cancel_button_confirm.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel_button_confirm;

  /// No description provided for @pay_button_confirm.
  ///
  /// In es, this message translates to:
  /// **'Pagar'**
  String get pay_button_confirm;

  /// No description provided for @confirm_button.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm_button;

  /// No description provided for @expired_button_text.
  ///
  /// In es, this message translates to:
  /// **'Expirada'**
  String get expired_button_text;

  /// No description provided for @sending_button.
  ///
  /// In es, this message translates to:
  /// **'Enviando...'**
  String get sending_button;

  /// No description provided for @invoice_expired_error.
  ///
  /// In es, this message translates to:
  /// **'La factura ha expirado y no se puede pagar'**
  String get invoice_expired_error;

  /// No description provided for @amountless_invoice_error.
  ///
  /// In es, this message translates to:
  /// **'Factura sin monto no soportada. Solicite una factura con un monto específico.'**
  String get amountless_invoice_error;

  /// No description provided for @payment_sent_status.
  ///
  /// In es, this message translates to:
  /// **'Pago enviado - Estado: {status}'**
  String payment_sent_status(Object status);

  /// No description provided for @confirm_no_session_error.
  ///
  /// In es, this message translates to:
  /// **'Sin sesión activa'**
  String get confirm_no_session_error;

  /// No description provided for @confirm_no_wallet_error.
  ///
  /// In es, this message translates to:
  /// **'No hay wallet principal disponible'**
  String get confirm_no_wallet_error;

  /// No description provided for @payment_pending_hold.
  ///
  /// In es, this message translates to:
  /// **'Pago pendiente - Factura Hold detectada'**
  String get payment_pending_hold;

  /// No description provided for @payment_completed_success.
  ///
  /// In es, this message translates to:
  /// **'Pago completado exitosamente'**
  String get payment_completed_success;

  /// No description provided for @payment_sent_status_prefix.
  ///
  /// In es, this message translates to:
  /// **'Pago enviado - Estado: '**
  String get payment_sent_status_prefix;

  /// No description provided for @payment_sending_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Error enviando pago: '**
  String get payment_sending_error_prefix;

  /// No description provided for @language_selector_title.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language_selector_title;

  /// No description provided for @language_selector_description.
  ///
  /// In es, this message translates to:
  /// **'Cambiar idioma de la aplicación'**
  String get language_selector_description;

  /// No description provided for @select_language.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar idioma'**
  String get select_language;

  /// No description provided for @no_wallet_error.
  ///
  /// In es, this message translates to:
  /// **'Sin billetera principal disponible'**
  String get no_wallet_error;

  /// No description provided for @invalid_session_error.
  ///
  /// In es, this message translates to:
  /// **'Sin sesión activa'**
  String get invalid_session_error;

  /// No description provided for @send_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Error procesando el envío: '**
  String get send_error_prefix;

  /// No description provided for @decode_invoice_error_prefix.
  ///
  /// In es, this message translates to:
  /// **'Error decodificando factura: '**
  String get decode_invoice_error_prefix;

  /// No description provided for @payment_success.
  ///
  /// In es, this message translates to:
  /// **'Pago completado exitosamente'**
  String get payment_success;

  /// No description provided for @expiry_label.
  ///
  /// In es, this message translates to:
  /// **'Expiración'**
  String get expiry_label;

  /// No description provided for @processing_text.
  ///
  /// In es, this message translates to:
  /// **'procesando'**
  String get processing_text;

  /// No description provided for @paste_input_hint.
  ///
  /// In es, this message translates to:
  /// **'Pega factura, LNURL o dirección'**
  String get paste_input_hint;

  /// No description provided for @conversion_rate_error.
  ///
  /// In es, this message translates to:
  /// **'Error cargando tipos de cambio'**
  String get conversion_rate_error;

  /// No description provided for @instant_payments_feature.
  ///
  /// In es, this message translates to:
  /// **'Pagos instantáneos'**
  String get instant_payments_feature;

  /// No description provided for @favorite_server_feature.
  ///
  /// In es, this message translates to:
  /// **'Con tu servidor favorito'**
  String get favorite_server_feature;

  /// No description provided for @receive_info_text.
  ///
  /// In es, this message translates to:
  /// **'• Comparte tu Lightning Address para recibir pagos de cualquier monto\n\n• El código QR se resuelve automáticamente a LNURL para máxima compatibilidad\n\n• Los pagos se reciben directamente en esta billetera'**
  String get receive_info_text;

  /// No description provided for @payment_description_example.
  ///
  /// In es, this message translates to:
  /// **'Ej: Pago por servicios'**
  String get payment_description_example;

  /// No description provided for @remember_password_label.
  ///
  /// In es, this message translates to:
  /// **'Recordar contraseña'**
  String get remember_password_label;

  /// No description provided for @server_prefix.
  ///
  /// In es, this message translates to:
  /// **'Servidor: '**
  String get server_prefix;

  /// No description provided for @login_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tus credenciales para acceder a tu billetera'**
  String get login_subtitle;

  /// No description provided for @username_required_error.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario es requerido'**
  String get username_required_error;

  /// No description provided for @username_length_error.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario debe tener al menos 3 caracteres'**
  String get username_length_error;

  /// No description provided for @password_required_error.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es requerida'**
  String get password_required_error;

  /// No description provided for @password_length_error.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get password_length_error;

  /// No description provided for @saved_users_header.
  ///
  /// In es, this message translates to:
  /// **'Usuarios guardados'**
  String get saved_users_header;

  /// No description provided for @tap_to_autocomplete_hint.
  ///
  /// In es, this message translates to:
  /// **'Toca para autocompletar contraseña'**
  String get tap_to_autocomplete_hint;

  /// No description provided for @delete_credentials_title.
  ///
  /// In es, this message translates to:
  /// **'Eliminar credenciales'**
  String get delete_credentials_title;

  /// No description provided for @delete_credentials_message.
  ///
  /// In es, this message translates to:
  /// **'Al desmarcar esta opción, las credenciales guardadas para este usuario serán eliminadas.\\n\\n¿Estás seguro de que quieres continuar?'**
  String get delete_credentials_message;

  /// No description provided for @delete_credentials_cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get delete_credentials_cancel;

  /// No description provided for @delete_credentials_confirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete_credentials_confirm;

  /// No description provided for @close_dialog.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close_dialog;

  /// No description provided for @credentials_found_message.
  ///
  /// In es, this message translates to:
  /// **'Credenciales encontradas - la contraseña será recordada'**
  String get credentials_found_message;

  /// No description provided for @password_will_be_remembered.
  ///
  /// In es, this message translates to:
  /// **'La contraseña será recordada después del login'**
  String get password_will_be_remembered;

  /// No description provided for @password_saved_successfully.
  ///
  /// In es, this message translates to:
  /// **'Contraseña guardada exitosamente'**
  String get password_saved_successfully;

  /// No description provided for @password_save_failed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la contraseña'**
  String get password_save_failed;

  /// No description provided for @about_app_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Billetera Lightning'**
  String get about_app_subtitle;

  /// No description provided for @about_app_description.
  ///
  /// In es, this message translates to:
  /// **'Una aplicación móvil para gestionar Bitcoin a través de Lightning Network usando LNBits como backend.'**
  String get about_app_description;

  /// No description provided for @lightning_address_copy.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get lightning_address_copy;

  /// No description provided for @lightning_address_default.
  ///
  /// In es, this message translates to:
  /// **'Por defecto'**
  String get lightning_address_default;

  /// No description provided for @lightning_address_delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get lightning_address_delete;

  /// No description provided for @lightning_address_is_default.
  ///
  /// In es, this message translates to:
  /// **'Es por defecto'**
  String get lightning_address_is_default;

  /// No description provided for @lightning_address_set_default.
  ///
  /// In es, this message translates to:
  /// **'Establecer como por defecto'**
  String get lightning_address_set_default;

  /// No description provided for @create_new_wallet_help.
  ///
  /// In es, this message translates to:
  /// **'Crear nueva billetera'**
  String get create_new_wallet_help;

  /// No description provided for @create_wallet_short_description.
  ///
  /// In es, this message translates to:
  /// **'Para crear una nueva billetera, accede a tu panel LNBits desde el navegador y usa la opción \"Crear billetera\".'**
  String get create_wallet_short_description;

  /// No description provided for @create_wallet_detailed_instructions.
  ///
  /// In es, this message translates to:
  /// **'Para crear una nueva billetera:\\n\\n1. Abre tu navegador web\\n2. Accede a tu servidor LNBits\\n3. Inicia sesión con tu cuenta\\n4. Busca el botón \"Crear billetera\"\\n5. Asigna un nombre a tu nueva billetera\\n6. Regresa a LaChispa y actualiza tus billeteras\\n\\nLa nueva billetera aparecerá automáticamente en tu lista.'**
  String get create_wallet_detailed_instructions;

  /// No description provided for @fixed_float_loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando Fixed Float...'**
  String get fixed_float_loading;

  /// No description provided for @fixed_float_description.
  ///
  /// In es, this message translates to:
  /// **'Intercambia criptomonedas con\ntasas fijas y sin registro'**
  String get fixed_float_description;

  /// No description provided for @fixed_float_webview_error.
  ///
  /// In es, this message translates to:
  /// **'WebView no disponible en esta plataforma.\nSe abrirá en navegador externo.'**
  String get fixed_float_webview_error;

  /// No description provided for @fixed_float_open_button.
  ///
  /// In es, this message translates to:
  /// **'Abrir Fixed Float'**
  String get fixed_float_open_button;

  /// No description provided for @fixed_float_error_opening.
  ///
  /// In es, this message translates to:
  /// **'Error abriendo Fixed Float: {error}'**
  String fixed_float_error_opening(String error);

  /// No description provided for @fixed_float_external_browser.
  ///
  /// In es, this message translates to:
  /// **'Se abrirá Fixed Float en navegador externo'**
  String get fixed_float_external_browser;

  /// No description provided for @fixed_float_within_app.
  ///
  /// In es, this message translates to:
  /// **'Abre Fixed Float dentro de la aplicación'**
  String get fixed_float_within_app;

  /// No description provided for @boltz_loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando Boltz...'**
  String get boltz_loading;

  /// No description provided for @boltz_description.
  ///
  /// In es, this message translates to:
  /// **'Intercambios atómicos sin confianza\nde Bitcoin y Lightning'**
  String get boltz_description;

  /// No description provided for @boltz_webview_error.
  ///
  /// In es, this message translates to:
  /// **'WebView no disponible en esta plataforma.\nSe abrirá en navegador externo.'**
  String get boltz_webview_error;

  /// No description provided for @boltz_open_button.
  ///
  /// In es, this message translates to:
  /// **'Abrir Boltz'**
  String get boltz_open_button;

  /// No description provided for @boltz_error_opening.
  ///
  /// In es, this message translates to:
  /// **'Error abriendo Boltz: {error}'**
  String boltz_error_opening(String error);

  /// No description provided for @boltz_external_browser.
  ///
  /// In es, this message translates to:
  /// **'Se abrirá Boltz en navegador externo'**
  String get boltz_external_browser;

  /// No description provided for @boltz_within_app.
  ///
  /// In es, this message translates to:
  /// **'Abre Boltz dentro de la aplicación'**
  String get boltz_within_app;

  /// No description provided for @add_note_optional.
  ///
  /// In es, this message translates to:
  /// **'Añadir una nota (opcional)'**
  String get add_note_optional;

  /// No description provided for @currency_settings_title.
  ///
  /// In es, this message translates to:
  /// **'Selección de Monedas'**
  String get currency_settings_title;

  /// No description provided for @currency_settings_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tus monedas preferidas'**
  String get currency_settings_subtitle;

  /// No description provided for @available_currencies.
  ///
  /// In es, this message translates to:
  /// **'Monedas Disponibles'**
  String get available_currencies;

  /// No description provided for @selected_currencies.
  ///
  /// In es, this message translates to:
  /// **'Monedas Seleccionadas'**
  String get selected_currencies;

  /// No description provided for @no_currencies_available.
  ///
  /// In es, this message translates to:
  /// **'No hay monedas disponibles del servidor'**
  String get no_currencies_available;

  /// No description provided for @select_currencies_hint.
  ///
  /// In es, this message translates to:
  /// **'Selecciona monedas de la lista de arriba'**
  String get select_currencies_hint;

  /// No description provided for @preview_title.
  ///
  /// In es, this message translates to:
  /// **'Vista Previa'**
  String get preview_title;

  /// No description provided for @tap_to_cycle.
  ///
  /// In es, this message translates to:
  /// **'Toca para cambiar monedas'**
  String get tap_to_cycle;

  /// No description provided for @settings_screen_title.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settings_screen_title;

  /// No description provided for @about_title.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get about_title;

  /// No description provided for @currency_validation_info.
  ///
  /// In es, this message translates to:
  /// **'Al seleccionar una moneda, se verificará si está disponible en este servidor'**
  String get currency_validation_info;

  /// No description provided for @checking_currency_availability.
  ///
  /// In es, this message translates to:
  /// **'Verificando disponibilidad de {currency}...'**
  String checking_currency_availability(Object currency);

  /// No description provided for @currency_added_successfully.
  ///
  /// In es, this message translates to:
  /// **'{currency} agregado correctamente'**
  String currency_added_successfully(Object currency);

  /// No description provided for @currency_not_available_on_server.
  ///
  /// In es, this message translates to:
  /// **'{currencyName} ({currency}) no está disponible en este servidor'**
  String currency_not_available_on_server(Object currency, Object currencyName);

  /// No description provided for @error_checking_currency.
  ///
  /// In es, this message translates to:
  /// **'Error verificando {currency}: {error}'**
  String error_checking_currency(Object currency, Object error);

  /// No description provided for @deep_link_login_required_title.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión requerido'**
  String get deep_link_login_required_title;

  /// No description provided for @deep_link_login_required_message.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión en tu cuenta LaChispa para procesar este pago.'**
  String get deep_link_login_required_message;

  /// No description provided for @invoice_receive_description.
  ///
  /// In es, this message translates to:
  /// **'Crea una factura para recibir pagos directamente en tu wallet'**
  String get invoice_receive_description;

  /// No description provided for @or_create_lnaddress.
  ///
  /// In es, this message translates to:
  /// **'o también puedes crear una:'**
  String get or_create_lnaddress;

  /// No description provided for @or_create_lnaddress_full.
  ///
  /// In es, this message translates to:
  /// **'o también puedes crear una Lightning Address:'**
  String get or_create_lnaddress_full;

  /// No description provided for @invoice_copied.
  ///
  /// In es, this message translates to:
  /// **'Factura copiada'**
  String get invoice_copied;
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
    'ru',
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
    'that was used.',
  );
}
