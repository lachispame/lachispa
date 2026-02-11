# LaChispa ⚡

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://github.com/lachispame/lachispa)   
  *Ask questions about this project using DeepWiki AI*

<div align="center">
  <img src="assets/images/chispabordesredondos.png" alt="LaChispa Logo" width="120" height="120">
  
  **A modern and easy-to-use mobile Lightning Network wallet**
  
  ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
  ![Bitcoin](https://img.shields.io/badge/Bitcoin-F7931E?style=for-the-badge&logo=bitcoin&logoColor=white)
  ![Lightning](https://img.shields.io/badge/Lightning-792EE5?style=for-the-badge&logo=lightning&logoColor=white)
</div>

---

## 📱 About LaChispa

LaChispa is a modern mobile application developed in Flutter that allows you to manage Bitcoin through Lightning Network using LNBits as backend. Designed with an intuitive interface and attractive visual effects, it makes Lightning Network usage accessible for everyone.

### ✨ Key Features

- **🔐 Secure Authentication**: Login and registration with multiple LNBits servers
- **💼 Wallet Management**: Support for multiple wallets with automatic selection
- **⚡ Lightning Payments**: Send and receive instant Lightning payments
- **📧 Lightning Address**: Create and manage personalized Lightning Addresses
- **🎯 Multiple Formats**: Support for BOLT11, LNURL, and Lightning Address
- **💱 Currency Conversion**: Integration with Yadio.io for USD, CUP and sats (more denominations coming)
- **📊 Complete History**: Detailed visualization of all transactions
- **🌐 Multiplatform**: Android, iOS, Web, Windows, macOS and Linux

## 🚀 Screenshots

<div align="center">
  <img src="assets/images/welcome_screen.jpg" alt="Welcome Screen" width="200">
  <img src="assets/images/home_screen.jpg" alt="Home Screen" width="200">
  <img src="assets/images/sending_bitcoin.jpg" alt="Sending Bitcoin" width="200">
  <img src="assets/images/receive_screen.jpg" alt="Receive Screen" width="200">
  <img src="assets/images/history_screen.jpg" alt="Transaction History" width="200">
</div>

| Welcome Screen | Home Screen | Send Payment | Receive Payment | Transaction History |
|:--:|:--:|:--:|:--:|:--:|
| *Easy onboarding* | *Wallet management* | *Multiple formats* | *QR code generation* | *Complete transaction log* |

## 🔧 Technologies Used

### Frontend
- **Flutter 3.0+**: Cross-platform framework
- **Dart**: Programming language
- **Provider**: State management
- **QR Flutter**: QR code generation
- **Mobile Scanner**: QR code scanning

### Backend & APIs
- **LNBits**: Lightning Network server
- **Yadio.io**: Exchange rate conversion
- **Lightning Network**: Payment protocol

### Technical Features
- **Secure Storage**: Secure credential storage
- **Dio HTTP Client**: Optimized HTTP requests
- **Real-time Updates**: Automatic balance updates
- **Responsive Design**: Automatic adaptation to different screen sizes

## 📦 Installation

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Configured LNBits server

### Clone the Repository
```bash
git clone https://github.com/Forte11Cuba/lachispa.git
cd lachispa
```

### Install Dependencies
```bash
flutter pub get
```

### Run the app in emulator
```bash
flutter run
```

### Build for your Platform

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

**Desktop:**
```bash
flutter build windows --release  # Windows
flutter build macos --release    # macOS
flutter build linux --release    # Linux
```

## ⚙️ Configuration

### LNBits Servers

The application comes preconfigured with public LNBits servers, but you can add your own server:

1. Open the application
2. Go to "Change server"
3. Select "Custom server"
4. Enter your LNBits server URL

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
│   ├── wallet_info.dart
│   ├── lightning_invoice.dart
│   └── ln_address.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── wallet_provider.dart
│   └── ln_address_provider.dart
├── screens/                  # Application screens
│   ├── 1welcome_screen.dart
│   ├── 6home_screen.dart
│   └── ...
├── services/                 # API services
│   ├── auth_service.dart
│   ├── wallet_service.dart
│   └── invoice_service.dart
└── widgets/                  # Reusable components
    ├── qr_scanner_widget.dart
    └── spark_effect.dart
```

## 🔐 Security

- **Secure Storage**: Locally encrypted credentials
- **HTTPS Only**: All communications encrypted
- **No Logging**: No sensitive information logging
- **Session Management**: Secure session management
- **Input Validation**: Comprehensive input validation


## 📱 Compatibility

### Supported Platforms
- ✅ Android (API 21+)
- ✅ iOS (iOS 12.0+)
- ✅ Web (Chrome, Firefox, Safari)
- ✅ Windows (Windows 10+)
- ✅ macOS (macOS 10.14+)
- ✅ Linux (Ubuntu 18.04+)

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a branch for your feature (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -m 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Open a Pull Request

## 📄 License

This project is under the MIT License - see the [LICENSE](LICENSE) file for more details.
