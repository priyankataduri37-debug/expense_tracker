# 💰 Expense Tracker — Personal Finance Management App

**Track your money. Build better habits. Reach your financial goals.**

A personal finance management application built with **Flutter and Dart** to help users manage income and expenses, monitor account balances, organize savings goals, and gain insights into their spending.

The application combines transaction management, recurring transactions, savings-goal tracking, and smart financial insights in one place.

---

## ✨ Features

### 📊 Smart Dashboard

* Get an overview of your financial activity.
* Monitor income, expenses, and account balances.
* Review key financial information from one place.

### 💸 Income & Expense Tracking

* Record income and expense transactions.
* Organize financial activity.
* Keep track of transactions and their impact on your accounts.

### 🏦 Account Management

* Manage multiple account types, including cash, bank accounts, credit cards, wallets, and savings accounts.
* Track balances for individual accounts.
* Keep account balances consistent with supported transactions and transfers.

### 🔄 Recurring Transactions

* Configure recurring income and expenses.
* Support daily, weekly, monthly, and yearly recurrence frequencies.
* Simplify the management of regular financial commitments.

### 🎯 Savings Goals

* Create and manage savings goals.
* Add contributions toward financial targets.
* Track progress as you work toward your goals.

### 🧠 Smart Insights

* Review financial insights based on the information tracked by the application.
* Understand spending patterns and financial activity.

### 💾 Local Storage & Synchronization

* Persist application data using local database storage.
* Support offline data access where implemented.
* Integrate synchronization functionality for supported data operations.

---

## 🛠️ Tech Stack

| Technology   | Purpose                                 |
| ------------ | --------------------------------------- |
| Flutter      | Cross-platform application development  |
| Dart         | Application programming language        |
| Provider     | State management                        |
| SQLite       | Local relational database               |
| Flutter Test | Automated testing                       |
| Git & GitHub | Version control and source-code hosting |

---

## 🏗️ Project Architecture

The application organizes its code into separate layers and feature modules to improve maintainability and make future enhancements easier.

```text
lib/
├── core/
│   └── utils/
├── data/
│   ├── local/
│   └── repositories/
├── features/
│   └── recurring/
├── providers/
└── main.dart

test/
```

**Architecture overview**

* **Core:** Shared utilities and common application logic.
* **Data:** Local database and repository classes responsible for data operations.
* **Features:** Screens and functionality grouped by feature.
* **Providers:** Application state management and communication between UI and data layers.
* **Tests:** Automated tests for important application behavior.

*This is a simplified directory overview. Update it if your actual project structure differs.*

---

## 🚀 Getting Started

Follow these steps to run the project locally.

### Prerequisites

Install the following:

* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* [Android Studio](https://developer.android.com/studio) or Visual Studio Code
* Android emulator or a physical Android device
* Git

Verify your Flutter installation:

```bash
flutter doctor
```

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/priyankataduri37-debug/expense_tracker.git
```

**2. Navigate to the project directory**

```bash
cd expense_tracker
```

**3. Install dependencies**

```bash
flutter pub get
```

**4. Check connected devices**

```bash
flutter devices
```

**5. Run the application**

```bash
flutter run
```

---

## 🧪 Testing & Code Quality

Run the automated test suite:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

These commands help verify application behavior and identify code-quality issues.

---

## 📦 Build a Release APK

To generate an Android release APK, run:

```bash
flutter build apk --release
```

After a successful build, locate the APK at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

You can install the APK on a compatible Android device for testing.

---

## 📸 Application Screenshots

Explore the key features and interface of the Expense Tracker application.

### 🏠 Dashboard

Get an overview of your finances, balances, and recent transactions.

![Expense Tracker Dashboard](dashboard1.jpeg)

### 💳 Transaction Management

View and manage your financial transactions.

![Transaction History](transactions1.jpeg)

![Transaction History - Additional View](transactiobd1.jpeg)

### 📊 Analytics & Smart Insights

Visualize your spending patterns and financial activity.

![Analytics Overview](analytics1.jpeg)

![Analytics Details](analytics2.jpeg)

### 🏦 Accounts & Wallets

Manage your accounts and monitor individual balances.

![Accounts and Wallets](accounts.jpeg)

### 🎯 Savings Goals

Track your savings progress and financial targets.

![Savings Goals - Overview](savings1.jpeg)

![Savings Goals - Progress](savings2.jpeg)

### 💰 Budget Management

Monitor your budget and spending progress.

![Budget Management](budgets.jpeg)

### ⚙️ Settings & Preferences

Configure application settings and preferences.

![Settings Overview](settings1.jpeg)

![Settings Details](settings2.jpeg)


## 🔮 Future Enhancements

Potential improvements for future versions include:

* More detailed financial reports and visualizations.
* Advanced budgeting and spending analysis.
* Additional transaction filters and search options.
* Expanded automated test coverage.
* Further improvements to data synchronization and error handling.

---

## 🎯 Project Goals

This project demonstrates practical experience with:

* Building a Flutter application using Dart.
* Managing application state with Provider.
* Implementing local persistence with SQLite.
* Organizing code using repositories and feature-based modules.
* Handling financial operations across accounts and savings goals.
* Writing automated tests and validating code with static analysis.
* Managing source code with Git and GitHub.

---

## 👩‍💻 Author

**Project:** Expense Tracker
**Repository:** [expense_tracker on GitHub](https://github.com/priyankataduri37-debug/expense_tracker)

---

*Built with Flutter and Dart.*
