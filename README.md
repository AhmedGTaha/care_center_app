# Care Center App

A Mobile Application for Medical Equipment Rental and Donation Management

## Overview

Care Center App is a Flutter and Firebase based mobile application designed to streamline the rental and donation of medical and mobility equipment. The app supports multiple user roles and enables real-time equipment tracking, reservation workflows, donation processing, lifecycle management, and administrative reporting.

This system helps care centers and individuals efficiently manage medical equipment distribution, reducing waste while supporting those in need.

## Features

### ✔ Authentication & User Roles

* Email registration and login
* Guest mode
* Role based navigation for **Admin**, **Renter**, and **Guest**

### ✔ Equipment Management (Admin)

* Add, edit, delete equipment
* Manage status: available, rented, donated, maintenance
* Search and filter equipment
* Image upload and compression

### ✔ Reservation System (Renter & Admin)

* Browse equipment
* Reserve with date selection
* Admin approval or rejection
* Lifecycle tracking: Reserved → Checked Out → Returned → Maintenance

### ✔ Donation System

* Users and guests can submit donations
* Admin reviews and approves donated items
* Items can be converted into inventory

### ✔ Tracking & Notifications

* Track rentals and overdue cases
* Real time notifications for approvals, maintenance, and donations
* Notification center with unread tracking

### ✔ Reports & Analytics

* Rental analytics
* Equipment usage insights
* Overdue statistics
* Most rented items

## Technology Stack

* **Framework**: Flutter
* **Language**: Dart
* **Backend**: Firebase Firestore, Firebase Storage
* **State Management**: StatefulWidget and StreamBuilder

## Project Contributors

The following students contributed to the development of this project:

| Student Name          | Student ID | Contribution                                                                            |
| --------------------- | ---------- | --------------------------------------------------------------------------------------- |
| **Ahmed Taha**        | 202203742  | Authentication system, user management, role navigation, profile management, guest mode |
| **Ammar Osama**       | 202206744  | Equipment CRUD, filtering, image handling, tags system                                  |
| **Mahdi Mohammed**    | 202104612  | Reservation creation, admin approval flow, tracking pages, lifecycle management         |
| **Salaman Mohammed**  | 202004368  | Donation system, notification service, notification center UI, overdue detection        |
| **Muntadher Abdulla** | 202106721  | Reports and analytics, dashboard, theme and UI/UX, reusable components, animations      |

(These contributions are taken directly from the submitted project report.)


## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/AhmedGTaha/care_center_app.git
   ```
2. Install packages:

   ```bash
   flutter pub get
   ```
3. Run the application:

   ```bash
   flutter run
   ```
4. For running on Chrome:

   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```

## Firebase Setup

Insert the database rules found in `db_rules.txt` into Firebase.
(Refer to the report for Firebase account details if needed during testing.)
