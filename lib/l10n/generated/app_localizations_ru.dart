// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get welcome_title => 'Добро пожаловать в La Chispa!';

  @override
  String get welcome_subtitle => 'Lightning для всех';

  @override
  String get get_started_button => 'Начать';

  @override
  String get tap_to_start_hint => 'Просто как зажечь искру';

  @override
  String get choose_option_title =>
      'Подключитесь к вашему любимому серверу LNBits';

  @override
  String get create_new_wallet_title => 'Создать новый кошелек';

  @override
  String get create_new_wallet_subtitle => 'Настройте ваш Lightning кошелек';

  @override
  String get use_existing_wallet_title => 'Использовать существующий кошелек';

  @override
  String get use_existing_wallet_subtitle =>
      'Подключитесь к Lightning кошельку';

  @override
  String get server_settings_title => 'Текущий сервер';

  @override
  String get change_server_button => 'Изменить сервер';

  @override
  String get server_url_label => 'URL сервера';

  @override
  String get admin_label => 'Администратор';

  @override
  String get admin_key_label => 'Ключ администратора';

  @override
  String get invoice_key_label => 'Ключ счета';

  @override
  String get server_url_placeholder => 'https://demo.lnbits.com';

  @override
  String get admin_key_placeholder => 'Введите ключ администратора';

  @override
  String get invoice_key_placeholder => 'Введите ключ счета';

  @override
  String get connect_button => 'Подключить';

  @override
  String get connecting_button => 'ПОДКЛЮЧЕНИЕ...';

  @override
  String get connection_error_prefix => 'Ошибка подключения: ';

  @override
  String get login_title => 'Войти';

  @override
  String get username_label => 'Имя пользователя';

  @override
  String get password_label => 'Пароль';

  @override
  String get username_placeholder => 'Введите ваше имя пользователя';

  @override
  String get password_placeholder => 'Введите ваш пароль';

  @override
  String get login_button => 'Войти';

  @override
  String get logging_in_button => 'ВХОД...';

  @override
  String get no_account_question => 'Нет аккаунта? ';

  @override
  String get register_link => 'Зарегистрироваться';

  @override
  String get login_error_prefix => 'Ошибка входа: ';

  @override
  String get create_account_title => 'Создать аккаунт';

  @override
  String get signup_username_label => 'Имя пользователя';

  @override
  String get signup_password_label => 'Пароль';

  @override
  String get confirm_password_label => 'Подтвердите пароль';

  @override
  String get signup_username_placeholder => 'Введите имя пользователя';

  @override
  String get signup_password_placeholder => 'Введите пароль';

  @override
  String get confirm_password_placeholder => 'Повторите ваш пароль';

  @override
  String get create_account_button => 'Создать аккаунт';

  @override
  String get creating_account_button => 'СОЗДАНИЕ АККАУНТА...';

  @override
  String get already_have_account_question => 'Уже есть аккаунт? ';

  @override
  String get login_link => 'Войти';

  @override
  String get passwords_mismatch_error => 'Пароли не совпадают';

  @override
  String get account_creation_error_prefix => 'Ошибка создания аккаунта: ';

  @override
  String get wallet_title => 'Кошелек';

  @override
  String get balance_label => 'Баланс';

  @override
  String get receive_button => 'Получить';

  @override
  String get send_button => 'Отправить';

  @override
  String get history_button => 'История';

  @override
  String get settings_button => 'Настройки';

  @override
  String get loading_text => 'Загрузка...';

  @override
  String get history_title => 'История';

  @override
  String get loading_transactions_text => 'Загрузка транзакций...';

  @override
  String get no_transactions_text => 'Нет транзакций';

  @override
  String get no_transactions_description => 'У вас пока нет транзакций.';

  @override
  String get sent_label => 'Отправлено';

  @override
  String get received_label => 'Получено';

  @override
  String get pending_label => 'В ожидании';

  @override
  String get failed_label => 'Не удалось';

  @override
  String get loading_transactions_error_prefix =>
      'Ошибка загрузки транзакций: ';

  @override
  String get lightning_address_title => 'Lightning адрес';

  @override
  String get loading_address_text => 'Загрузка адреса...';

  @override
  String get your_lightning_address_label => 'Ваш Lightning адрес:';

  @override
  String get not_available_text => 'Недоступно';

  @override
  String get share_button => 'Поделиться';

  @override
  String get copy_button => 'Копировать';

  @override
  String get address_copied_message => 'Адрес скопирован в буфер обмена';

  @override
  String get loading_address_error_prefix =>
      'Ошибка загрузки Lightning адреса: ';

  @override
  String get settings_title => 'Информация';

  @override
  String get lightning_address_option => 'Lightning адрес';

  @override
  String get lightning_address_description => 'Просмотреть ваш Lightning адрес';

  @override
  String get logout_option => 'Выйти';

  @override
  String get logout_description => 'Выйти из текущего аккаунта';

  @override
  String get confirm_logout_title => 'Подтвердить выход';

  @override
  String get confirm_logout_message => 'Вы уверены, что хотите выйти?';

  @override
  String get cancel_button => 'Отмена';

  @override
  String get logout_confirm_button => 'Выйти';

  @override
  String get receive_title => 'Получить';

  @override
  String get amount_sats_label => 'Запрашиваемая сумма';

  @override
  String get amount_label => 'Сумма';

  @override
  String get currency_label => 'Валюта';

  @override
  String get description_label => 'Описание';

  @override
  String get amount_sats_placeholder => 'Введите сумму в сатоши';

  @override
  String get description_placeholder => 'Необязательное описание';

  @override
  String get optional_description_label => 'Описание (Необязательно)';

  @override
  String get copy_lightning_address => 'Копировать Lightning адрес';

  @override
  String get copy_lnurl => 'Копировать LNURL';

  @override
  String get generate_invoice_button => 'Создать счет';

  @override
  String get generating_button => 'СОЗДАНИЕ...';

  @override
  String get invoice_generated_message => 'Счет успешно создан';

  @override
  String get invoice_generation_error_prefix => 'Ошибка создания счета: ';

  @override
  String get send_title => 'Отправить';

  @override
  String get paste_invoice_placeholder => 'Вставьте счет, LNURL или адрес';

  @override
  String get paste_button => 'Вставить';

  @override
  String get scan_button => 'Сканировать';

  @override
  String get voucher_scan_title => 'Сканировать ваучер';

  @override
  String get voucher_scan_instructions =>
      'Наведите камеру на QR-код ваучера LNURL-withdraw';

  @override
  String get voucher_scan_subtitle =>
      'Приложение автоматически обнаружит ваучер и позволит вам его активировать';

  @override
  String get voucher_scan_button => 'Сканировать QR';

  @override
  String get voucher_tap_to_scan => 'Нажмите, чтобы открыть камеру';

  @override
  String get voucher_manual_input => 'Ввести код вручную';

  @override
  String get voucher_processing => 'Обработка...';

  @override
  String get voucher_manual_input_hint =>
      'Вставьте код ваучера LNURL-withdraw:';

  @override
  String get voucher_manual_input_placeholder => 'lnurl1...';

  @override
  String get process_button => 'Обработать';

  @override
  String get voucher_detected_title => 'Ваучер обнаружен';

  @override
  String get voucher_fixed_amount => 'Фиксированная сумма:';

  @override
  String get voucher_amount_range => 'Доступный диапазон:';

  @override
  String get voucher_amount_to_claim => 'Сумма к получению:';

  @override
  String voucher_min_max_hint(int min, int max) {
    return 'Мин: $min сатоши • Макс: $max сатоши';
  }

  @override
  String get voucher_claim_button => 'Активировать ваучер';

  @override
  String voucher_amount_invalid(int min, int max) {
    return 'Неверная сумма. Должна быть между $min и $max сатоши';
  }

  @override
  String get voucher_claimed_title => 'Ваучер активирован!';

  @override
  String get voucher_claimed_subtitle =>
      'Средства вскоре появятся в вашем кошельке.';

  @override
  String get voucher_invalid_code => 'Неверный код';

  @override
  String get voucher_not_valid_lnurl =>
      'Отсканированный код не является действительным ваучером LNURL-withdraw.';

  @override
  String get voucher_processing_error => 'Ошибка обработки ваучера';

  @override
  String get voucher_already_claimed => 'Ваучер уже активирован';

  @override
  String get voucher_already_claimed_desc =>
      'Этот ваучер уже был использован и не может быть активирован повторно.';

  @override
  String get voucher_expired => 'Ваучер истек';

  @override
  String get voucher_expired_desc =>
      'Этот ваучер истек и больше не действителен.';

  @override
  String get voucher_not_found => 'Ваучер не найден';

  @override
  String get voucher_not_found_desc =>
      'Этот ваучер не найден или мог быть удален.';

  @override
  String get voucher_server_error => 'Ошибка сервера';

  @override
  String get voucher_server_error_desc =>
      'Возникла проблема с сервером ваучеров. Попробуйте еще раз позже.';

  @override
  String get voucher_connection_error => 'Ошибка соединения';

  @override
  String get voucher_connection_error_desc =>
      'Проверьте подключение к интернету и попробуйте еще раз.';

  @override
  String get voucher_invalid_amount => 'Неверная сумма';

  @override
  String get voucher_invalid_amount_desc =>
      'Сумма ваучера недействительна или была повреждена.';

  @override
  String get voucher_insufficient_funds => 'Недостаточно средств';

  @override
  String get voucher_insufficient_funds_desc =>
      'У ваучера недостаточно доступных средств.';

  @override
  String get voucher_generic_error => 'Не удается обработать ваучер';

  @override
  String get voucher_generic_error_desc =>
      'Произошла неожиданная ошибка при обработке этого ваучера. Попробуйте еще раз или обратитесь в поддержку.';

  @override
  String get pay_button => 'ОПЛАТИТЬ';

  @override
  String get processing_button => 'ОБРАБОТКА...';

  @override
  String get payment_instruction_text =>
      'Вставьте Lightning счет, LNURL или адрес';

  @override
  String get payment_processing_error_prefix => 'Ошибка обработки платежа: ';

  @override
  String get no_active_session_error => 'Нет активной сессии';

  @override
  String get no_primary_wallet_error => 'Нет доступного основного кошелька';

  @override
  String get invoice_decoding_error_prefix => 'Ошибка декодирования счета: ';

  @override
  String get send_to_title => 'Отправить на';

  @override
  String get clear_button => 'C';

  @override
  String get decimal_button => '.';

  @override
  String get calculating_text => 'Вычисление...';

  @override
  String get loading_rates_text => 'Загрузка курсов...';

  @override
  String get send_button_prefix => 'ОТПРАВИТЬ ';

  @override
  String get amount_processing_button => 'ОБРАБОТКА...';

  @override
  String get exchange_rates_error => 'Ошибка загрузки обменных курсов';

  @override
  String get invalid_amount_error => 'Введите действительную сумму';

  @override
  String get amount_payment_error_prefix => 'Ошибка обработки платежа: ';

  @override
  String get amount_no_session_error => 'Нет активной сессии';

  @override
  String get amount_no_wallet_error => 'Нет доступного основного кошелька';

  @override
  String get sending_lnurl_payment => 'Отправка LNURL платежа...';

  @override
  String get sending_lightning_payment =>
      'Отправка Lightning Address платежа...';

  @override
  String get lnurl_payment_pending =>
      'LNURL платеж ожидает - Обнаружен счет-холд';

  @override
  String get lnurl_payment_success => 'LNURL платеж успешно завершен!';

  @override
  String get lightning_payment_pending =>
      'Lightning Address платеж ожидает - Обнаружен счет-холд';

  @override
  String get lightning_payment_success =>
      'Lightning Address платеж успешно завершен!';

  @override
  String get insufficient_balance_error =>
      'Недостаточно средств для совершения платежа';

  @override
  String get confirm_payment_title => 'Подтвердить платеж';

  @override
  String get invoice_description_label => 'Описание';

  @override
  String get no_description_text => 'Нет описания';

  @override
  String get invoice_status_label => 'Статус';

  @override
  String get expired_status => 'Истек';

  @override
  String get valid_status => 'Действителен';

  @override
  String get expiration_label => 'Истечение';

  @override
  String get payment_hash_label => 'Хеш платежа';

  @override
  String get recipient_label => 'Получатель';

  @override
  String get cancel_button_confirm => 'Отмена';

  @override
  String get pay_button_confirm => 'Оплатить';

  @override
  String get confirm_button => 'Подтвердить';

  @override
  String get expired_button_text => 'Истек';

  @override
  String get sending_button => 'Отправка...';

  @override
  String get invoice_expired_error => 'Счет истек и не может быть оплачен';

  @override
  String get confirm_no_session_error => 'Нет активной сессии';

  @override
  String get confirm_no_wallet_error => 'Нет доступного основного кошелька';

  @override
  String get payment_pending_hold => 'Платеж ожидает - Обнаружен счет-холд';

  @override
  String get payment_completed_success => 'Платеж успешно завершен';

  @override
  String get payment_sent_status_prefix => 'Платеж отправлен - Статус: ';

  @override
  String get payment_sending_error_prefix => 'Ошибка отправки платежа: ';

  @override
  String get language_selector_title => 'Язык';

  @override
  String get language_selector_description => 'Изменить язык приложения';

  @override
  String get select_language => 'Выбрать язык';

  @override
  String get no_wallet_error => 'Нет доступного основного кошелька';

  @override
  String get invalid_session_error => 'Нет активной сессии';

  @override
  String get send_error_prefix => 'Ошибка обработки отправки: ';

  @override
  String get decode_invoice_error_prefix => 'Ошибка декодирования счета: ';

  @override
  String get payment_success => 'Платеж успешно завершен';

  @override
  String get expiry_label => 'Истечение';

  @override
  String get processing_text => 'обработка';

  @override
  String get paste_input_hint => 'Вставьте счет, LNURL или адрес';

  @override
  String get conversion_rate_error => 'Ошибка загрузки обменных курсов';

  @override
  String get instant_payments_feature => 'Мгновенные платежи';

  @override
  String get favorite_server_feature => 'С вашим любимым сервером';

  @override
  String get receive_info_text =>
      '• Поделитесь своим Lightning адресом для получения платежей любой суммы\\n\\n• QR-код автоматически разрешается в LNURL для максимальной совместимости\\n\\n• Платежи поступают непосредственно в этот кошелек';

  @override
  String get payment_description_example => 'Например: Оплата услуг';

  @override
  String get remember_password_label => 'Запомнить пароль';

  @override
  String get server_prefix => 'Сервер: ';

  @override
  String get login_subtitle =>
      'Введите ваши учетные данные для доступа к кошельку';

  @override
  String get username_required_error => 'Требуется имя пользователя';

  @override
  String get username_length_error =>
      'Имя пользователя должно содержать не менее 3 символов';

  @override
  String get password_required_error => 'Требуется пароль';

  @override
  String get password_length_error =>
      'Пароль должен содержать не менее 6 символов';

  @override
  String get saved_users_header => 'Сохраненные пользователи';

  @override
  String get tap_to_autocomplete_hint => 'Нажмите для автозаполнения пароля';

  @override
  String get delete_credentials_title => 'Удалить учетные данные';

  @override
  String get delete_credentials_message =>
      'Сняв этот флажок, сохраненные учетные данные для этого пользователя будут удалены.\\\\n\\\\nВы уверены, что хотите продолжить?';

  @override
  String get delete_credentials_cancel => 'Отмена';

  @override
  String get delete_credentials_confirm => 'Удалить';

  @override
  String get close_dialog => 'Закрыть';

  @override
  String get credentials_found_message =>
      'Учетные данные найдены - пароль будет запомнен';

  @override
  String get password_will_be_remembered => 'Пароль будет запомнен после входа';

  @override
  String get password_saved_successfully => 'Пароль успешно сохранен';

  @override
  String get password_save_failed => 'Не удалось сохранить пароль';

  @override
  String get about_app_subtitle => 'Lightning кошелек';

  @override
  String get about_app_description =>
      'Мобильное приложение для управления Bitcoin через Lightning Network с использованием LNBits в качестве бэкенда.';

  @override
  String get lightning_address_copy => 'Копировать';

  @override
  String get lightning_address_default => 'По умолчанию';

  @override
  String get lightning_address_delete => 'Удалить';

  @override
  String get lightning_address_is_default => 'По умолчанию';

  @override
  String get lightning_address_set_default => 'Установить по умолчанию';

  @override
  String get create_new_wallet_help => 'Создать новый кошелек';

  @override
  String get create_wallet_short_description =>
      'Чтобы создать новый кошелек, войдите в панель LNBits через браузер и используйте опцию \\\"Создать кошелек\\\".';

  @override
  String get create_wallet_detailed_instructions =>
      'Чтобы создать новый кошелек:\\\\n\\\\n1. Откройте веб-браузер\\\\n2. Войдите на ваш сервер LNBits\\\\n3. Войдите в свой аккаунт\\\\n4. Найдите кнопку \\\"Создать кошелек\\\"\\\\n5. Дайте имя вашему новому кошельку\\\\n6. Вернитесь в LaChispa и обновите ваши кошельки\\\\n\\\\nНовый кошелек автоматически появится в вашем списке.';

  @override
  String get fixed_float_loading => 'Загрузка Fixed Float...';

  @override
  String get fixed_float_description =>
      'Обменивайте криптовалюты по\\nфиксированным курсам без регистрации';

  @override
  String get fixed_float_webview_error =>
      'WebView недоступен на этой платформе.\\\\nОткроется во внешнем браузере.';

  @override
  String get fixed_float_open_button => 'Открыть Fixed Float';

  @override
  String fixed_float_error_opening(String error) {
    return 'Ошибка открытия Fixed Float: $error';
  }

  @override
  String get fixed_float_external_browser =>
      'Откроет Fixed Float во внешнем браузере';

  @override
  String get fixed_float_within_app => 'Открывает Fixed Float в приложении';

  @override
  String get boltz_loading => 'Загрузка Boltz...';

  @override
  String get boltz_description =>
      'Атомные свопы Bitcoin и Lightning\\nбез доверия';

  @override
  String get boltz_webview_error =>
      'WebView недоступен на этой платформе.\\\\nОткроется во внешнем браузере.';

  @override
  String get boltz_open_button => 'Открыть Boltz';

  @override
  String boltz_error_opening(String error) {
    return 'Ошибка открытия Boltz: $error';
  }

  @override
  String get boltz_external_browser => 'Откроет Boltz во внешнем браузере';

  @override
  String get boltz_within_app => 'Открывает Boltz в приложении';

  @override
  String get add_note_optional => 'Добавить заметку (необязательно)';

  @override
  String get currency_settings_title => 'Выбор валют';

  @override
  String get currency_settings_subtitle =>
      'Выберите ваши предпочитаемые валюты';

  @override
  String get available_currencies => 'Доступные валюты';

  @override
  String get selected_currencies => 'Выбранные валюты';

  @override
  String get no_currencies_available => 'Нет доступных валют с сервера';

  @override
  String get select_currencies_hint => 'Выберите валюты из списка выше';

  @override
  String get preview_title => 'Предпросмотр';

  @override
  String get tap_to_cycle => 'Нажмите для переключения валют';

  @override
  String get settings_screen_title => 'Настройки';

  @override
  String get about_title => 'Информация';

  @override
  String get currency_validation_info =>
      'При выборе валюты будет проверено, доступна ли она на этом сервере';

  @override
  String checking_currency_availability(Object currency) {
    return 'Проверка доступности $currency...';
  }

  @override
  String currency_added_successfully(Object currency) {
    return '$currency успешно добавлен';
  }

  @override
  String currency_not_available_on_server(
      Object currency, Object currencyName) {
    return '$currencyName ($currency) недоступна на этом сервере';
  }

  @override
  String error_checking_currency(Object currency, Object error) {
    return 'Ошибка при проверке $currency: $error';
  }

  @override
  String get deep_link_login_required_title => 'Требуется вход в систему';

  @override
  String get deep_link_login_required_message =>
      'Вы должны войти в свою учетную запись LaChispa для обработки этого платежа.';
}
