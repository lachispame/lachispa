// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get welcome_title => '¡Bienvenido a La Chispa!';

  @override
  String get welcome_subtitle => 'Lightning para todos';

  @override
  String get get_started_button => 'Comenzar';

  @override
  String get tap_to_start_hint => 'Tan fácil como encender una chispa';

  @override
  String get choose_option_title => 'Conecta con tu servidor LNBits favorito';

  @override
  String get create_new_wallet_title => 'Crear Nueva Billetera';

  @override
  String get create_new_wallet_subtitle =>
      'Configurar tu propia billetera Lightning';

  @override
  String get use_existing_wallet_title => 'Usar Billetera Existente';

  @override
  String get use_existing_wallet_subtitle =>
      'Conectar a una billetera Lightning';

  @override
  String get server_settings_title => 'Servidor actual';

  @override
  String get change_server_button => 'Cambiar servidor';

  @override
  String get server_url_label => 'URL del Servidor';

  @override
  String get admin_label => 'Administrador';

  @override
  String get admin_key_label => 'Clave de Administrador';

  @override
  String get invoice_key_label => 'Clave de Facturación';

  @override
  String get server_url_placeholder => 'https://demo.lnbits.com';

  @override
  String get admin_key_placeholder => 'Ingresa la clave de administrador';

  @override
  String get invoice_key_placeholder => 'Ingresa la clave de facturación';

  @override
  String get connect_button => 'Conectar';

  @override
  String get connecting_button => 'CONECTANDO...';

  @override
  String get connection_error_prefix => 'Error de conexión: ';

  @override
  String get login_title => 'Iniciar Sesión';

  @override
  String get username_label => 'Nombre de Usuario';

  @override
  String get password_label => 'Contraseña';

  @override
  String get username_placeholder => 'Introduce tu nombre de usuario';

  @override
  String get password_placeholder => 'Introduce tu contraseña';

  @override
  String get login_button => 'Iniciar Sesión';

  @override
  String get logging_in_button => 'INICIANDO SESIÓN...';

  @override
  String get no_account_question => '¿No tienes cuenta? ';

  @override
  String get register_link => 'Regístrate';

  @override
  String get login_error_prefix => 'Error en el inicio de sesión: ';

  @override
  String get create_account_title => 'Crear Cuenta';

  @override
  String get signup_username_label => 'Nombre de Usuario';

  @override
  String get signup_password_label => 'Contraseña';

  @override
  String get confirm_password_label => 'Confirmar Contraseña';

  @override
  String get signup_username_placeholder => 'Introduce un nombre de usuario';

  @override
  String get signup_password_placeholder => 'Introduce una contraseña';

  @override
  String get confirm_password_placeholder => 'Repite tu contraseña';

  @override
  String get create_account_button => 'Crear Cuenta';

  @override
  String get creating_account_button => 'CREANDO CUENTA...';

  @override
  String get already_have_account_question => '¿Ya tienes cuenta? ';

  @override
  String get login_link => 'Iniciar Sesión';

  @override
  String get passwords_mismatch_error => 'Las contraseñas no coinciden';

  @override
  String get account_creation_error_prefix => 'Error al crear cuenta: ';

  @override
  String get wallet_title => 'Billetera';

  @override
  String get balance_label => 'Saldo';

  @override
  String get receive_button => 'Recibir';

  @override
  String get send_button => 'Enviar';

  @override
  String get history_button => 'Historial';

  @override
  String get settings_button => 'Configuración';

  @override
  String get loading_text => 'Cargando...';

  @override
  String get history_title => 'Historial';

  @override
  String get loading_transactions_text => 'Cargando transacciones...';

  @override
  String get no_transactions_text => 'No hay transacciones';

  @override
  String get no_transactions_description =>
      'Aún no has realizado ninguna transacción.';

  @override
  String get sent_label => 'Enviado';

  @override
  String get received_label => 'Recibido';

  @override
  String get pending_label => 'Pendiente';

  @override
  String get failed_label => 'Fallida';

  @override
  String get loading_transactions_error_prefix =>
      'Error cargando transacciones: ';

  @override
  String get lightning_address_title => 'Dirección Lightning';

  @override
  String get loading_address_text => 'Cargando dirección...';

  @override
  String get your_lightning_address_label => 'Tu dirección Lightning:';

  @override
  String get not_available_text => 'No disponible';

  @override
  String get share_button => 'Compartir';

  @override
  String get copy_button => 'Copiar';

  @override
  String get address_copied_message => 'Dirección copiada al portapapeles';

  @override
  String get loading_address_error_prefix =>
      'Error cargando dirección Lightning: ';

  @override
  String get settings_title => 'Acerca de';

  @override
  String get lightning_address_option => 'Dirección Lightning';

  @override
  String get lightning_address_description => 'Ver tu dirección Lightning';

  @override
  String get logout_option => 'Cerrar Sesión';

  @override
  String get logout_description => 'Desconectar de la cuenta actual';

  @override
  String get confirm_logout_title => 'Confirmar Cierre de Sesión';

  @override
  String get confirm_logout_message =>
      '¿Estás seguro de que deseas cerrar sesión?';

  @override
  String get cancel_button => 'Cancelar';

  @override
  String get logout_confirm_button => 'Cerrar Sesión';

  @override
  String get receive_title => 'Recibir';

  @override
  String get amount_sats_label => 'Solicitar Monto';

  @override
  String get amount_label => 'Cantidad';

  @override
  String get currency_label => 'Moneda';

  @override
  String get description_label => 'Descripción';

  @override
  String get amount_sats_placeholder => 'Introduce el monto en sats';

  @override
  String get description_placeholder => 'Descripción opcional';

  @override
  String get optional_description_label => 'Descripción (Opcional)';

  @override
  String get copy_lightning_address => 'Copiar Lightning Address';

  @override
  String get copy_lnurl => 'Copiar LNURL';

  @override
  String get generate_invoice_button => 'Generar Factura';

  @override
  String get generating_button => 'GENERANDO...';

  @override
  String get invoice_generated_message => 'Factura generada correctamente';

  @override
  String get invoice_generation_error_prefix => 'Error generando factura: ';

  @override
  String get send_title => 'Enviar';

  @override
  String get paste_invoice_placeholder => 'Pega factura, LNURL o dirección';

  @override
  String get paste_button => 'Pegar';

  @override
  String get scan_button => 'Escanear';

  @override
  String get voucher_scan_title => 'Escanear Voucher';

  @override
  String get voucher_scan_instructions =>
      'Apunta tu cámara al código QR del voucher LNURL-withdraw';

  @override
  String get voucher_scan_subtitle =>
      'La aplicación detectará automáticamente el voucher y te permitirá cobrarlo';

  @override
  String get voucher_scan_button => 'Escanear QR';

  @override
  String get voucher_tap_to_scan => 'Toca para abrir la cámara';

  @override
  String get voucher_manual_input => 'Introducir código manualmente';

  @override
  String get voucher_processing => 'Procesando...';

  @override
  String get voucher_manual_input_hint =>
      'Pega el código LNURL-withdraw del voucher:';

  @override
  String get voucher_manual_input_placeholder => 'lnurl1...';

  @override
  String get process_button => 'Procesar';

  @override
  String get voucher_detected_title => 'Voucher Detectado';

  @override
  String get voucher_fixed_amount => 'Cantidad fija:';

  @override
  String get voucher_amount_range => 'Rango disponible:';

  @override
  String get voucher_amount_to_claim => 'Cantidad a cobrar:';

  @override
  String voucher_min_max_hint(int min, int max) {
    return 'Mínimo: $min sats • Máximo: $max sats';
  }

  @override
  String get voucher_claim_button => 'Cobrar Voucher';

  @override
  String voucher_amount_invalid(int min, int max) {
    return 'Cantidad inválida. Debe estar entre $min y $max sats';
  }

  @override
  String get voucher_claimed_title => '¡Voucher cobrado!';

  @override
  String get voucher_claimed_subtitle =>
      'Los fondos aparecerán en tu wallet en unos momentos.';

  @override
  String get voucher_invalid_code => 'Código no válido';

  @override
  String get voucher_not_valid_lnurl =>
      'El código escaneado no es un voucher LNURL-withdraw válido.';

  @override
  String get voucher_processing_error => 'Error procesando el voucher';

  @override
  String get voucher_already_claimed => 'Voucher ya cobrado';

  @override
  String get voucher_already_claimed_desc =>
      'Este voucher ya fue usado y no puede ser cobrado nuevamente.';

  @override
  String get voucher_expired => 'Voucher expirado';

  @override
  String get voucher_expired_desc =>
      'Este voucher ha expirado y ya no es válido.';

  @override
  String get voucher_not_found => 'Voucher no encontrado';

  @override
  String get voucher_not_found_desc =>
      'Este voucher no pudo ser encontrado o puede haber sido eliminado.';

  @override
  String get voucher_server_error => 'Error del servidor';

  @override
  String get voucher_server_error_desc =>
      'Hubo un problema con el servidor del voucher. Inténtalo de nuevo más tarde.';

  @override
  String get voucher_connection_error => 'Error de conexión';

  @override
  String get voucher_connection_error_desc =>
      'Verifica tu conexión a internet e inténtalo de nuevo.';

  @override
  String get voucher_invalid_amount => 'Cantidad inválida';

  @override
  String get voucher_invalid_amount_desc =>
      'La cantidad del voucher no es válida o se ha corrompido.';

  @override
  String get voucher_insufficient_funds => 'Fondos insuficientes';

  @override
  String get voucher_insufficient_funds_desc =>
      'El voucher no tiene suficientes fondos disponibles.';

  @override
  String get voucher_generic_error => 'No se pudo procesar el voucher';

  @override
  String get voucher_generic_error_desc =>
      'Hubo un error inesperado procesando este voucher. Inténtalo de nuevo o contacta soporte.';

  @override
  String get pay_button => 'PAGAR';

  @override
  String get processing_button => 'PROCESANDO...';

  @override
  String get payment_instruction_text =>
      'Pega una factura Lightning, LNURL o dirección';

  @override
  String get payment_processing_error_prefix => 'Error procesando el pago: ';

  @override
  String get no_active_session_error => 'Sin sesión activa';

  @override
  String get no_primary_wallet_error => 'No hay wallet principal disponible';

  @override
  String get invoice_decoding_error_prefix => 'Error decodificando factura: ';

  @override
  String get send_to_title => 'Enviar a';

  @override
  String get clear_button => 'C';

  @override
  String get decimal_button => '.';

  @override
  String get calculating_text => 'Calculando...';

  @override
  String get loading_rates_text => 'Loading rates...';

  @override
  String get send_button_prefix => 'SEND ';

  @override
  String get amount_processing_button => 'PROCESANDO...';

  @override
  String get exchange_rates_error => 'Error cargando tipos de cambio';

  @override
  String get invalid_amount_error => 'Por favor ingresa un monto válido';

  @override
  String get amount_payment_error_prefix => 'Error procesando pago: ';

  @override
  String get amount_no_session_error => 'Sin sesión activa';

  @override
  String get amount_no_wallet_error => 'Sin billetera principal disponible';

  @override
  String get sending_lnurl_payment => 'Enviando pago LNURL...';

  @override
  String get sending_lightning_payment =>
      'Sending Lightning Address payment...';

  @override
  String get lnurl_payment_pending =>
      'Pago LNURL pendiente - Factura Hold detectada';

  @override
  String get lnurl_payment_success => 'Pago LNURL completado exitosamente!';

  @override
  String get lightning_payment_pending =>
      'Pago Lightning Address pendiente - Factura Hold detectada';

  @override
  String get lightning_payment_success =>
      'Pago Lightning Address completado exitosamente!';

  @override
  String get insufficient_balance_error =>
      'Saldo insuficiente para realizar el pago';

  @override
  String get confirm_payment_title => 'Confirmar Pago';

  @override
  String get invoice_description_label => 'Descripción';

  @override
  String get no_description_text => 'Sin descripción';

  @override
  String get invoice_status_label => 'Estado';

  @override
  String get expired_status => 'Expirada';

  @override
  String get valid_status => 'Válida';

  @override
  String get expiration_label => 'Expiración';

  @override
  String get payment_hash_label => 'Hash de Pago';

  @override
  String get recipient_label => 'Destinatario';

  @override
  String get cancel_button_confirm => 'Cancelar';

  @override
  String get pay_button_confirm => 'Pagar';

  @override
  String get confirm_button => 'Confirmar';

  @override
  String get expired_button_text => 'Expirada';

  @override
  String get sending_button => 'Enviando...';

  @override
  String get invoice_expired_error =>
      'La factura ha expirado y no se puede pagar';

  @override
  String get confirm_no_session_error => 'Sin sesión activa';

  @override
  String get confirm_no_wallet_error => 'No hay wallet principal disponible';

  @override
  String get payment_pending_hold => 'Pago pendiente - Factura Hold detectada';

  @override
  String get payment_completed_success => 'Pago completado exitosamente';

  @override
  String get payment_sent_status_prefix => 'Pago enviado - Estado: ';

  @override
  String get payment_sending_error_prefix => 'Error enviando pago: ';

  @override
  String get language_selector_title => 'Idioma';

  @override
  String get language_selector_description => 'Cambiar idioma de la aplicación';

  @override
  String get select_language => 'Seleccionar idioma';

  @override
  String get no_wallet_error => 'Sin billetera principal disponible';

  @override
  String get invalid_session_error => 'Sin sesión activa';

  @override
  String get send_error_prefix => 'Error procesando el envío: ';

  @override
  String get decode_invoice_error_prefix => 'Error decodificando factura: ';

  @override
  String get payment_success => 'Pago completado exitosamente';

  @override
  String get expiry_label => 'Expiración';

  @override
  String get processing_text => 'procesando';

  @override
  String get paste_input_hint => 'Pega factura, LNURL o dirección';

  @override
  String get conversion_rate_error => 'Error cargando tipos de cambio';

  @override
  String get instant_payments_feature => 'Pagos instantáneos';

  @override
  String get favorite_server_feature => 'Con tu servidor favorito';

  @override
  String get receive_info_text =>
      '• Comparte tu Lightning Address para recibir pagos de cualquier monto\n\n• El código QR se resuelve automáticamente a LNURL para máxima compatibilidad\n\n• Los pagos se reciben directamente en esta billetera';

  @override
  String get payment_description_example => 'Ej: Pago por servicios';

  @override
  String get remember_password_label => 'Recordar contraseña';

  @override
  String get server_prefix => 'Servidor: ';

  @override
  String get login_subtitle =>
      'Ingresa tus credenciales para acceder a tu billetera';

  @override
  String get username_required_error => 'El nombre de usuario es requerido';

  @override
  String get username_length_error =>
      'El nombre de usuario debe tener al menos 3 caracteres';

  @override
  String get password_required_error => 'La contraseña es requerida';

  @override
  String get password_length_error =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get saved_users_header => 'Usuarios guardados';

  @override
  String get tap_to_autocomplete_hint => 'Toca para autocompletar contraseña';

  @override
  String get delete_credentials_title => 'Eliminar credenciales';

  @override
  String get delete_credentials_message =>
      'Al desmarcar esta opción, las credenciales guardadas para este usuario serán eliminadas.\\n\\n¿Estás seguro de que quieres continuar?';

  @override
  String get delete_credentials_cancel => 'Cancelar';

  @override
  String get delete_credentials_confirm => 'Eliminar';

  @override
  String get close_dialog => 'Cerrar';

  @override
  String get credentials_found_message =>
      'Credenciales encontradas - la contraseña será recordada';

  @override
  String get password_will_be_remembered =>
      'La contraseña será recordada después del login';

  @override
  String get password_saved_successfully => 'Contraseña guardada exitosamente';

  @override
  String get password_save_failed => 'No se pudo guardar la contraseña';

  @override
  String get about_app_subtitle => 'Billetera Lightning';

  @override
  String get about_app_description =>
      'Una aplicación móvil para gestionar Bitcoin a través de Lightning Network usando LNBits como backend.';

  @override
  String get lightning_address_copy => 'Copiar';

  @override
  String get lightning_address_default => 'Por defecto';

  @override
  String get lightning_address_delete => 'Eliminar';

  @override
  String get lightning_address_is_default => 'Es por defecto';

  @override
  String get lightning_address_set_default => 'Establecer como por defecto';

  @override
  String get create_new_wallet_help => 'Crear nueva billetera';

  @override
  String get create_wallet_short_description =>
      'Para crear una nueva billetera, accede a tu panel LNBits desde el navegador y usa la opción \"Crear billetera\".';

  @override
  String get create_wallet_detailed_instructions =>
      'Para crear una nueva billetera:\\n\\n1. Abre tu navegador web\\n2. Accede a tu servidor LNBits\\n3. Inicia sesión con tu cuenta\\n4. Busca el botón \"Crear billetera\"\\n5. Asigna un nombre a tu nueva billetera\\n6. Regresa a LaChispa y actualiza tus billeteras\\n\\nLa nueva billetera aparecerá automáticamente en tu lista.';

  @override
  String get fixed_float_loading => 'Cargando Fixed Float...';

  @override
  String get fixed_float_description =>
      'Intercambia criptomonedas con\ntasas fijas y sin registro';

  @override
  String get fixed_float_webview_error =>
      'WebView no disponible en esta plataforma.\nSe abrirá en navegador externo.';

  @override
  String get fixed_float_open_button => 'Abrir Fixed Float';

  @override
  String fixed_float_error_opening(String error) {
    return 'Error abriendo Fixed Float: $error';
  }

  @override
  String get fixed_float_external_browser =>
      'Se abrirá Fixed Float en navegador externo';

  @override
  String get fixed_float_within_app =>
      'Abre Fixed Float dentro de la aplicación';

  @override
  String get boltz_loading => 'Cargando Boltz...';

  @override
  String get boltz_description =>
      'Intercambios atómicos sin confianza\nde Bitcoin y Lightning';

  @override
  String get boltz_webview_error =>
      'WebView no disponible en esta plataforma.\nSe abrirá en navegador externo.';

  @override
  String get boltz_open_button => 'Abrir Boltz';

  @override
  String boltz_error_opening(String error) {
    return 'Error abriendo Boltz: $error';
  }

  @override
  String get boltz_external_browser => 'Se abrirá Boltz en navegador externo';

  @override
  String get boltz_within_app => 'Abre Boltz dentro de la aplicación';

  @override
  String get add_note_optional => 'Añadir una nota (opcional)';

  @override
  String get currency_settings_title => 'Selección de Monedas';

  @override
  String get currency_settings_subtitle => 'Selecciona tus monedas preferidas';

  @override
  String get available_currencies => 'Monedas Disponibles';

  @override
  String get selected_currencies => 'Monedas Seleccionadas';

  @override
  String get no_currencies_available =>
      'No hay monedas disponibles del servidor';

  @override
  String get select_currencies_hint =>
      'Selecciona monedas de la lista de arriba';

  @override
  String get preview_title => 'Vista Previa';

  @override
  String get tap_to_cycle => 'Toca para cambiar monedas';

  @override
  String get settings_screen_title => 'Configuración';

  @override
  String get about_title => 'Acerca de';

  @override
  String get currency_validation_info =>
      'Al seleccionar una moneda, se verificará si está disponible en este servidor';

  @override
  String checking_currency_availability(Object currency) {
    return 'Verificando disponibilidad de $currency...';
  }

  @override
  String currency_added_successfully(Object currency) {
    return '$currency agregado correctamente';
  }

  @override
  String currency_not_available_on_server(
    Object currency,
    Object currencyName,
  ) {
    return '$currencyName ($currency) no está disponible en este servidor';
  }

  @override
  String error_checking_currency(Object currency, Object error) {
    return 'Error verificando $currency: $error';
  }

  @override
  String get deep_link_login_required_title => 'Inicio de sesión requerido';

  @override
  String get deep_link_login_required_message =>
      'Debes iniciar sesión en tu cuenta LaChispa para procesar este pago.';

  @override
  String get invoice_receive_description =>
      'Crea una factura para recibir pagos directamente en tu wallet';

  @override
  String get or_create_lnaddress => 'o también puedes crear una:';

  @override
  String get or_create_lnaddress_full =>
      'o también puedes crear una Lightning Address:';

  @override
  String get invoice_copied => 'Factura copiada';
}
