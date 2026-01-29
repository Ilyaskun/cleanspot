# CleanSpot

CleanSpot is a **Flutter mobile application** developed as a Final Year Project (FYP).  
The app is designed to manage cleaning service bookings with **three user roles**: **User**, **Cleaner**, and **Admin**.

The project focuses on demonstrating **real-world application flow**, role-based access, and basic backend integration using **Firebase**.

---

## Features Overview

### User Flow
- Select a cleaning service  
- Enter booking details (date & time)  
- Submit booking request  
- View booking history  
- View photo proof after job completion  

### Admin Flow
- View new booking requests  
- Approve or reject bookings  
- Assign approved jobs to cleaners  
- Review photo proof submitted by cleaners  
- Mark jobs as completed  
- Manage service pricing and job history  

### Cleaner Flow
- Receive approved jobs  
- Accept job and notify user (“On my way”)  
- Complete cleaning service  
- Upload photo proof as evidence  
- Submit proof to admin for final confirmation  

---

## Tech Stack

- Flutter  
- Dart  
- Firebase Authentication  
- Firebase Firestore  
- Firebase Storage  
- Android Studio  

---

## Project Structure (Simplified)

lib/
├── screens/ # UI screens (user, admin, cleaner)
├── models/ # Data models
├── providers/ # State management
├── main.dart # App entry point
android/
ios/
assets/

---

## Notes

- This project was developed for **academic and learning purposes**
- Focus was placed on **application flow, role separation, and usability**
- Backend features are limited by Firebase free-tier constraints

---

## Author

Daniel (Ilyas)  
Final Year Project – Mobile Application Development
