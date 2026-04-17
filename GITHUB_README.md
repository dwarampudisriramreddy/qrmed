# QRmed - Equipment Management & QR Code Tracking System

A comprehensive Flutter-based application for managing institutional equipment, tracking assets through QR codes, and managing inspections, maintenance, and customer requests.

## 📋 Table of Contents
- [About the App](#about-the-app)
- [Features](#features)
- [Getting Started](#getting-started)
- [App Architecture](#app-architecture)
- [How the App Logic Works](#how-the-app-logic-works)
- [How to Use](#how-to-use)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Authentication System](#authentication-system)
- [Database Schema](#database-schema)

---

## 🎯 About the App

**QRmed** is an institutional equipment management system designed to streamline the tracking, maintenance, and distribution of equipment across colleges and institutions. The application uses QR codes for quick equipment identification and manages multiple user roles including administrators, employees, customers, and college managers.

### Key Objectives
- **Asset Tracking**: Track all institutional equipment with QR codes
- **Maintenance Management**: Schedule and track equipment inspections and maintenance
- **Multi-Role Access**: Different interfaces for admins, employees, customers, and college administrators
- **Inspection Workflows**: Manage equipment inspection results and requirements
- **Customer Requests**: Handle customer equipment requests and requirements
- **Equipment Distribution**: Track equipment assignment and status

---

## ✨ Features

### 1. **QR Code Scanning & Generation**
   - Real-time QR code scanner with camera controls
   - Torch/flash support for low-light scanning
   - Front and back camera switching
   - QR code generation for all equipment

### 2. **Multi-Role Dashboard**
   - **Admin Dashboard**: Complete system oversight and management
   - **Employee Dashboard**: Equipment management and inspection tasks
   - **Customer Dashboard**: Equipment request and status tracking
   - **College Dashboard**: Institution-level equipment management

### 3. **Equipment Management**
   - Create, read, update, delete equipment records
   - Track equipment properties (manufacturer, type, serial number, status)
   - Categorize equipment (critical/non-critical, mercury/electrical/portable/hydraulic)
   - Track warranty and service status
   - Monitor equipment assignment to employees

### 4. **Inspection Management**
   - Schedule and record equipment inspections
   - Track inspection results and requirements
   - Manage inspection workflows
   - Generate inspection reports

### 5. **Ticket System**
   - Create and manage service tickets
   - Track ticket status and assignment
   - Customer request management

### 6. **Department Management**
   - Organize equipment by departments
   - Department-based access control and management

### 7. **Firebase Integration**
   - Cloud-based data storage
   - Real-time authentication
   - Secure user management
   - Cloud Firestore database

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.3.0)
- Dart SDK
- Firebase project setup
- Android Studio or Xcode (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/QRmed.git
   cd QRmed
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [firebase.google.com](https://firebase.google.com)
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate directories:
     - Android: `android/app/`
     - iOS: `ios/Runner/`

4. **Run the app**
   ```bash
   flutter run
   ```

### Build for Production

**Android:**
```bash
flutter build apk
# or for AppBundle
flutter build appbundle
```

**iOS:**
```bash
flutter build ios
```

**Web:**
```bash
flutter build web
```

---

## 🏗️ App Architecture

### Architecture Pattern: Provider Pattern + MVC

```
┌─────────────────────────────────────────────────┐
│           Screens (UI Layer)                     │
│  - LoginScreen, AdminDashboard, etc.             │
└──────────────┬──────────────────────────────────┘
               │
┌──────────────┴──────────────────────────────────┐
│         Widgets (UI Components)                  │
│  - DashboardTile, ModernListTile, etc.          │
└──────────────┬──────────────────────────────────┘
               │
┌──────────────┴──────────────────────────────────┐
│      Providers (State Management)                │
│  - EquipmentProvider, EmployeeProvider, etc.     │
│  - Change Notification System                    │
└──────────────┬──────────────────────────────────┘
               │
┌──────────────┴──────────────────────────────────┐
│      Models (Data Models)                        │
│  - Equipment, Employee, College, etc.            │
└──────────────┬──────────────────────────────────┘
               │
┌──────────────┴──────────────────────────────────┐
│   Services (Business Logic & Firebase)           │
│  - AuthService, Firebase Firestore Integration   │
└─────────────────────────────────────────────────┘
```

---

## 📱 How the App Logic Works

### 1. Authentication Flow

```
User Login
  ↓
[LoginScreen] - Collects email & password
  ↓
[AuthService] - Validates credentials
  ↓
Firebase Authentication
  ↓
User Role Verification
  ↓
Route to Appropriate Dashboard
  ├─→ Admin Dashboard
  ├─→ Employee Dashboard
  ├─→ Customer Dashboard
  └─→ College Dashboard
```

**Key Points:**
- Auto-complete suggestions from registered users
- Role-based routing (admin, employee, customer, college)
- Session persistence using Firebase Auth tokens

### 2. Equipment Management Flow

```
[Equipment Creation/Update]
  ↓
[EquipmentProvider] - Manages state
  ↓
[Firebase Firestore] - Persists data
  ↓
Documents Created/Updated
  ├─ Equipment ID (auto-generated UUID)
  ├─ QR Code
  ├─ Equipment Details
  ├─ Assignment Info
  └─ Status Tracking
```

**Equipment Data Model:**
- `id`: Unique identifier (UUID)
- `qrcode`: QR code value
- `name`: Equipment name
- `group`: Equipment category
- `manufacturer`: Manufacturer info
- `type`: Critical or non-critical
- `mode`: Operating mode (mercury, electrical, portable, hydraulic)
- `serialNo`: Serial number
- `department`: Department assignment
- `installationDate`: Installation date
- `status`: Current status
- `service`: Service status (active/non-active)
- `purchasedCost`: Purchase price
- `hasWarranty`: Warranty status
- `warrantyUpto`: Warranty expiration
- `assignedEmployeeId`: Employee assignment
- `customerReceived`: Customer tracking
- `collegeId`: College association

### 3. QR Code Scanning Flow

```
[QR Scanner Screen]
  ↓
[Mobile Scanner] - Captures QR code
  ↓
QR Code Extracted
  ↓
[Equipment Lookup]
  ↓
[Firestore Query] - Search by QR value
  ↓
Equipment Found
  ├─→ Display Equipment Details
  ├─→ Show History
  ├─→ Allow Updates
  └─→ Generate Reports
```

### 4. Inspection Management Flow

```
[Inspection Creation]
  ↓
[InspectionProvider] - Manages state
  ↓
[Equipment Association]
  ↓
Inspection Record Created
  ├─ Equipment ID
  ├─ Inspection Date
  ├─ Inspection Results
  ├─ Requirements
  └─ Status
  ↓
[Firestore Storage]
  ↓
[Employee Notification]
```

### 5. Ticket/Request Management Flow

```
[Customer Request]
  ↓
[Add Edit Ticket Screen]
  ↓
[TicketProvider] - Manages state
  ↓
Ticket Created with:
  ├─ Customer ID
  ├─ Equipment ID
  ├─ Request Details
  ├─ Status (pending/in-progress/completed)
  └─ Timestamp
  ↓
[Firestore Storage]
  ↓
[Employee Assignment]
  ↓
[Status Updates]
  ↓
[Completion & Notification]
```

### 6. Provider Pattern Data Flow

All providers follow the same pattern:

```
Provider Class
  ├─ _collectionReference (Firebase reference)
  ├─ _itemList (cached data)
  └─ Methods:
      ├─ fetch*() - Load from Firestore
      ├─ get*ById() - Fetch single item
      ├─ add*() - Create new item
      ├─ update*() - Modify existing item
      ├─ delete*() - Remove item
      └─ notifyListeners() - Update UI
```

---

## 📖 How to Use

### For Admin Users

#### 1. **Login**
   - Enter registered admin email
   - Use auto-complete dropdown to select from suggestions
   - Enter password
   - Click "Login"

#### 2. **Access Admin Dashboard**
   - View system overview with key metrics
   - Access all management sections

#### 3. **Manage Colleges**
   - Click "Manage Colleges"
   - View list of registered colleges
   - Create new college (+ button)
     - Fill college name, city, type, seats, password
     - Save to Firestore
   - Edit existing college (click on college card)
   - Delete college (swipe or delete button)

#### 4. **Manage Equipment**
   - Navigate to "Manage Equipment"
   - View all equipments with QR codes
   - Add new equipment
     - Fill name, group, manufacturer, type, etc.
     - Generate QR code automatically
     - Set installation date
     - Select department
     - Assign to employee (optional)
   - Update existing equipment
   - Delete equipment

#### 5. **Manage Inspections**
   - Navigate to "Manage Inspections"
   - View inspection records
   - Create new inspection
     - Select equipment
     - Set inspection date
     - Record results
     - Add requirements
   - Track inspection status

#### 6. **View Reports**
   - Dashboard shows summary statistics
   - Equipment status overview
   - Inspection completion rates
   - Active tickets

### For Employee Users

#### 1. **Login to Employee Dashboard**
   - Login with employee credentials
   - Redirected to employee-specific dashboard

#### 2. **View Assigned Equipment**
   - See all equipment assigned to you
   - View equipment details and QR codes

#### 3. **Perform Inspections**
   - Click on equipment to inspect
   - Scan QR code for quick access
   - Record inspection results
   - Submit inspection report

#### 4. **Scan Equipment**
   - Click "Scan QR" button
   - Point camera at QR code
   - Equipment details automatically displayed
   - Update status or information as needed

#### 5. **Manage Tickets**
   - View assigned service tickets
   - Update ticket status
   - Add notes/comments
   - Mark as completed

### For Customer Users

#### 1. **Login to Customer Dashboard**
   - Enter customer credentials
   - View customer-specific dashboard

#### 2. **View Equipment Status**
   - See equipment received from college
   - Track equipment status
   - View equipment history

#### 3. **Submit Requests**
   - Create new equipment request
   - Specify requirements
   - Submit to college
   - Track request status

#### 4. **View Tickets**
   - See submitted service requests
   - Track resolution progress
   - View ticket history

### For College Managers

#### 1. **Login to College Dashboard**
   - Login with college credentials
   - Access college management area

#### 2. **Manage College Equipment**
   - View all equipment in college
   - Filter by department or status
   - Generate equipment reports

#### 3. **Monitor Employees**
   - View employee list
   - See equipment assignments
   - Track employee activities

#### 4. **View Requirements**
   - See customer requirements
   - Plan equipment allocation
   - Track fulfillment

---

## 🔧 Technology Stack

### Frontend
- **Framework**: Flutter (Latest)
- **State Management**: Provider Pattern
- **UI Framework**: Material Design 3
- **Navigation**: Named Routes

### Backend
- **Authentication**: Firebase Authentication
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Hosting**: Firebase Hosting (Web)

### Key Dependencies
- `provider: ^6.1.2` - State management
- `firebase_core: ^3.1.0` - Firebase initialization
- `firebase_auth: ^5.1.0` - Authentication
- `cloud_firestore: ^5.0.0` - Database
- `mobile_scanner: ^5.1.0` - QR code scanning
- `qr_flutter: ^4.1.0` - QR code generation
- `image_picker: ^1.1.2` - Image selection
- `flutter_map: ^7.0.0` - Map integration
- `google_maps_flutter: ^2.6.1` - Google Maps

---

## 📁 Project Structure

```
QRmed/
├── lib/
│   ├── main.dart                 # App entry point & routing
│   ├── firebase_options.dart     # Firebase configuration
│   ├── models/                   # Data models
│   │   ├── equipment.dart
│   │   ├── employee.dart
│   │   ├── college.dart
│   │   ├── customer.dart
│   │   ├── ticket.dart
│   │   ├── inspection_result.dart
│   │   ├── product.dart
│   │   └── department.dart
│   ├── providers/                # State management
│   │   ├── equipment_provider.dart
│   │   ├── employee_provider.dart
│   │   ├── college_provider.dart
│   │   ├── customer_provider.dart
│   │   ├── ticket_provider.dart
│   │   ├── inspection_provider.dart
│   │   ├── requirements_provider.dart
│   │   └── department_provider.dart
│   ├── screens/                  # UI Screens
│   │   ├── login_screen_new.dart
│   │   ├── admin_dashboard_screen.dart
│   │   ├── employee_dashboard_screen.dart
│   │   ├── customer_dashboard_screen.dart
│   │   ├── college_dashboard_screen.dart
│   │   ├── qr_scanner_screen.dart
│   │   ├── manage_equipments_screen.dart
│   │   ├── manage_inspection_screen.dart
│   │   ├── manage_tickets_screen.dart
│   │   └── ...
│   ├── widgets/                  # Reusable UI components
│   │   ├── dashboard_tile.dart
│   │   ├── modern_list_tile.dart
│   │   ├── admin_home_tab.dart
│   │   ├── employee_home_tab.dart
│   │   └── ...
│   ├── services/                 # Business logic
│   │   └── auth_service.dart
│   ├── data/                     # Static data
│   │   ├── requirements_data.dart
│   │   └── department_group.dart
│   └── reference/                # Reference files
├── android/                      # Android native code
├── ios/                          # iOS native code
├── web/                          # Web build
├── windows/                      # Windows build
├── macos/                        # macOS build
├── linux/                        # Linux build
├── assets/                       # Images, logos, etc.
├── pubspec.yaml                  # Dependencies & configuration
└── README.md                     # Project documentation
```

---

## 🔐 Authentication System

### Login Flow

1. **User Input**
   - Email field with auto-complete from Firebase
   - Password field with visibility toggle

2. **Validation**
   - Form validation on client side
   - Firebase Authentication API call

3. **User Role Detection**
   - Check Firestore for user role
   - Possible roles: admin, employee, customer, college

4. **Navigation**
   - Route to appropriate dashboard based on role
   - Session persists using Firebase tokens

### User Types & Permissions

| User Type | Features | Dashboard |
|-----------|----------|-----------|
| **Admin** | Full system access, manage all entities | Admin Dashboard |
| **Employee** | View assigned equipment, perform inspections | Employee Dashboard |
| **Customer** | View equipment status, submit requests | Customer Dashboard |
| **College** | Manage college equipment and employees | College Dashboard |

---

## 📊 Database Schema

### Collections in Firestore

#### 1. **equipments**
```
Document ID: equipment_id
{
  id: string (UUID)
  qrcode: string
  name: string
  group: string
  manufacturer: string
  type: string (critical/non-critical)
  mode: string (mercury/electrical/portable/hydraulic)
  serialNo: string
  department: string
  installationDate: timestamp
  status: string
  service: string (active/non-active)
  purchasedCost: number
  hasWarranty: boolean
  warrantyUpto: timestamp
  assignedEmployeeId: string
  customerReceived: string
  collegeId: string
}
```

#### 2. **employees**
```
Document ID: employee_id
{
  id: string (UUID)
  name: string
  email: string
  collegeId: string
  department: string
  phone: string
  position: string
  status: string
}
```

#### 3. **colleges**
```
Document ID: college_id
{
  id: string (UUID)
  name: string
  city: string
  type: string
  seats: string
  password: string
}
```

#### 4. **customers**
```
Document ID: customer_id
{
  id: string (UUID)
  name: string
  email: string
  phone: string
  collegeId: string
  address: string
  status: string
}
```

#### 5. **inspections**
```
Document ID: inspection_id
{
  id: string (UUID)
  equipmentId: string
  inspectionDate: timestamp
  results: map
  requirements: array
  status: string
  employeeId: string
}
```

#### 6. **tickets**
```
Document ID: ticket_id
{
  id: string (UUID)
  customerId: string
  equipmentId: string
  description: string
  status: string
  createdDate: timestamp
  updatedDate: timestamp
  assignedEmployeeId: string
}
```

#### 7. **departments**
```
Document ID: department_id
{
  id: string (UUID)
  name: string
  collegeId: string
  description: string
}
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 📞 Support & Contact

For support, email: support@qrmed.com
Or create an issue on the GitHub repository.

---

## 🔄 Version History

- **v1.0.0** - Initial release with core features
  - QR code scanning and generation
  - Equipment management
  - Inspection tracking
  - Multi-role authentication
  - Firebase integration

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Provider Pattern Guide](https://pub.dev/packages/provider)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)

---

**Made with ❤️ by the QRmed Team**
