# TripSync

TripSync is a travel collaboration app built with Flutter. It helps users create trips, invite members, share locations on a map, attach media to markers, and manage trip expenses with split calculations.

## Features

- User authentication and profile management
- Create and manage trips
- Join trips using an invite code
- Display trips and trip details
- Map-based marker management
- Add, edit, and view marker details
- Attach image and audio media to markers
- Expense tracking for each trip
- Expense splitting among trip members
- Balance calculation for shared costs
- Date selection with a Persian date picker

## Tech Stack

- Flutter / Dart
- Riverpod for state management
- GoRouter for navigation
- Supabase for authentication, database, and storage

The codebase uses a feature-based structure with modules for trips, expenses, map markers, and profile management (`pasted-text.txt:1`, `pasted-text.txt:2`, `pasted-text.txt:3`, `pasted-text.txt:4`).

## Project Structure

The app is organized around feature modules such as:

- `features/trip`
- `features/expenses`
- `features/markers`
- `features/profile`
- `core`

Repository and provider patterns are used for data access and state composition; for example, expense data is accessed through `expenseRepositoryProvider` (`pasted-text.txt:71`).

## Screenshots

### Splash Screen

![Splash Screen](assets/images/screens/splash%20screen.jpg)

### Login and Sign Up

![Login](assets/images/screens/login.jpg)
![Sign Up](assets/images/screens/sign%20up.jpg)

### Home

![Home](assets/images/screens/home.jpg)

### Trips

![Add New Trip](assets/images/screens/add%20new%20trip.jpg)
![Trip Detail](assets/images/screens/trip%20detail.jpg)
![Invite Code](assets/images/screens/invite%20code.jpg)

### Map and Markers

![Map](assets/images/screens/map.jpg)
![Add New Marker](assets/images/screens/add%20marker.jpg)
![Edit Marker](assets/images/screens/edit%20marker.jpg)
![Marker Detail](assets/images/screens/marker%20detail.jpg)

### Expenses

![Expenses](assets/images/screens/expenses.jpg)
![Add New Expenses](assets/images/screens/new%20expenses.jpg)
![Balance](assets/images/screens/ballance.jpg)

### Profile

![Profile](assets/images/screens/profile.jpg)

## Main Workflows

### Trip Management

Users can create a new trip, view trip details, and join trips through an invite code.

### Marker Management

Users can add markers to a trip, edit them later, and attach media such as images or audio.

### Expense Management

Users can create and edit expenses, choose a payer, select involved members, and split the expense among trip participants. The expense screen in the code clearly supports amount, description, category, payer, involved users, and date selection (`pasted-text.txt:19`, `pasted-text.txt:31`, `pasted-text.txt:56`).

## Data Model

TripSync uses a relational schema in Supabase with tables such as:

- `profiles`
- `trips`
- `trip_members`
- `trip_markers`
- `marker_media`
- `expenses`
- `expense_splits`

## Notes

- The app is designed for collaborative trip planning.
- Supabase Row Level Security is expected to protect trip-related data.
- The UI screenshots included in this repository demonstrate the core user flows.
