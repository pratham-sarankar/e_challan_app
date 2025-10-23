# Municipal E-Challan App

A comprehensive digital challan management system designed specifically for police officers and traffic inspectors to efficiently manage traffic violations and rule enforcement.

## 🚔 About

The Municipal E-Challan App is a Flutter-based mobile application that digitizes the traditional challan (penalty) system, enabling police officers to issue, manage, and track traffic violation penalties seamlessly. The app bridges the gap between law enforcement and digital payment systems, making the entire process more transparent and efficient.

## 👮‍♂️ Target Users

- **Police Officers** - Traffic police and beat officers
- **Traffic Inspectors** - Municipal traffic enforcement personnel
- **Law Enforcement Officials** - Government authorized personnel

## 🎯 Key Features

### 📝 Challan Management
- **Create New Challans** - Issue digital penalties for various traffic violations
- **View Previous Challans** - Access complete history of issued penalties
- **Challan Details** - Comprehensive view with violator information, images, and payment status
- **Real-time Updates** - Live tracking of challan status and payments

### 🚦 Rule Violations Supported
- Construction & Demolition (C&D) waste disposal on roads - ₹2000
- Missing color-coded dustbins (Green/Blue/Red) - ₹500
- Various municipal and traffic rule violations
- Customizable violation types through admin panel

### 📱 Digital Evidence Collection
- **Camera Integration** - Capture violation evidence directly through the app
- **Gallery Support** - Upload existing photos as evidence
- **Multiple Images** - Attach multiple evidence photos per challan
- **Image Management** - View, organize and manage evidence images

### 💳 Payment Integration
- **Online Payment Gateway** - Integrated with VizPay payment system
- **Offline Payment Recording** - Manual payment confirmation
- **Payment Tracking** - Real-time payment status updates
- **Transaction History** - Complete payment audit trail

### 📊 Reporting & Analytics
- **Work Reports** - Generate performance and activity reports
- **Dashboard Analytics** - Overview of daily/monthly challan statistics
- **Payment Summary** - Track collection efficiency and pending amounts

### 🖨️ Document Generation
- **PDF Generation** - Create printable challan receipts
- **Barcode Integration** - QR codes for easy challan verification
- **Print Support** - Direct printing capabilities for physical receipts

## 🛠️ Technical Features

### 🏗️ Architecture
- **Flutter Framework** - Cross-platform mobile development
- **RESTful API Integration** - Seamless backend connectivity
- **Local Storage** - Offline capability with SharedPreferences
- **State Management** - Efficient app state handling

### 🔐 Security & Authentication
- **Officer Registration** - Secure account creation for authorized personnel
- **Role-based Access** - Inspector and officer role management
- **Token-based Authentication** - Secure API access
- **Data Encryption** - Protected sensitive information storage

### 📱 Platform Support
- **Android** - Full feature support with build flavors
- **iOS** - Complete iOS compatibility
- **Responsive Design** - Adaptive UI for various screen sizes

### 🔄 Real-time Features
- **Live Data Sync** - Automatic updates from backend
- **Push Notifications** - Payment confirmations and status updates
- **Offline Mode** - Work without internet connectivity
- **Auto-sync** - Data synchronization when connection restored

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Android Studio / VS Code
- Git

### Installation
1. Clone the repository
   ```bash
   git clone [repository-url]
   cd challan_app
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Configure Firebase (if applicable)
   ```bash
   # Add your firebase_options.dart file
   ```

4. Run the app
   ```bash
   flutter run
   ```

## 📦 Dependencies

### Core Libraries
- **google_fonts** - Typography and font management
- **image_picker** - Camera and gallery integration
- **permission_handler** - Device permission management
- **shared_preferences** - Local data storage
- **intl** - Internationalization and date formatting

### UI/UX Libraries
- **animate_do** - Smooth animations and transitions
- **carousel_slider** - Image carousel for evidence viewing
- **shimmer** - Loading state animations
- **lottie** - Advanced animations

### Business Logic
- **barcode_widget** - QR code generation
- **printing** - PDF generation and printing
- **pdf** - Document creation
- **vizpay_flutter** - Payment gateway integration

## 🏛️ System Benefits

### For Law Enforcement
- **Efficiency** - Faster challan creation and processing
- **Accuracy** - Reduced manual errors and data inconsistencies
- **Transparency** - Clear audit trail and accountability
- **Mobility** - Field-ready mobile solution

### For Citizens
- **Convenience** - Multiple payment options
- **Transparency** - Clear violation details and evidence
- **Accessibility** - Easy payment through digital channels
- **Records** - Digital copies of all transactions

### For Administration
- **Analytics** - Comprehensive reporting and insights
- **Cost Reduction** - Paperless system reduces operational costs
- **Compliance** - Better regulatory compliance and record keeping
- **Scalability** - Easily expandable to other municipal services

## 📄 License

This project is developed for municipal governance and law enforcement purposes.

## 🤝 Contributing

This is a government project. Please contact the development team for contribution guidelines.

---

**Developed for efficient law enforcement and better citizen services** 🚔