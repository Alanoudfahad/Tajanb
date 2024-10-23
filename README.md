# Tajanb App

## Project Overview

The **Food Allergy Scanner App** is an iOS application designed to help individuals with food allergies quickly and easily identify safe food options. By leveraging **VisionKit** for text detection, **PhotoKit** for photo uploads, and **Core Haptics** for enhanced tactile feedback, this app provides an intuitive and accessible solution. The app focuses on providing a Minimum Viable Product (MVP) approach to help users detect allergens in food ingredients efficiently.

---

1. [Project Overview](#project-overview)
2. [Problem and Solution Overview](#problem-and-solution-overview)
3. [Features List](#features-list)
4. [Technologies Used](#technologies-used)
5. [Database Schema](#Database-Schema)
6. [Installation](#installation)
7. [Usage](#usage)
8. [Screenshots](#Screenshots)

---

## Problem and Solution Overview

### Project Problem/Opportunity
Adults with food allergies face the challenge of manually checking product ingredients, which can be time-consuming and error-prone. They need a fast, reliable solution to help them identify potential allergens in food products, enabling them to make informed decisions and maintain a healthy lifestyle.

### Project Solution
This iOS app uses **VisionKit** to scan product ingredients and helps users quickly detect potential allergens. By scanning or uploading a photo of the ingredient list, the app identifies allergens and provides instant feedback.

## Target Audience
- **Individuals with food allergies** who want a quick and reliable tool for detecting allergens in food products.


## Features List

### 1. Ingredient Scanning and Allergen Detection
- **VisionKit**: Use the text detection feature to scan product ingredients directly from the camera.
- **PhotoKit**: Allow users to upload a photo of the ingredient list for allergen detection if they prefer not to use the camera.

### 2. Accessibility and User Experience Enhancements
- **VoiceOver**: Integrate VoiceOver for visually impaired users, ensuring text is read aloud to provide a more accessible experience.
- **Core Haptics**: Implement tactile feedback to enhance user interaction, making the app engaging and intuitive.
  
## Technologies Used

- **Swift**: Core programming language for iOS development.
- **VisionKit**: Text detection from images for ingredient scanning.
- **PhotoKit**: Photo upload and management for allergen detection.
- **Core Haptics**: Tactile feedback to enhance user experience.
- **Swift Data**: Data persistence for storing user-specific allergy information.


## Database Schema


## Installation

### Prerequisites
- iOS 15.0+
- Xcode 14.0+

### Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/Afrah-saleh/MyAllergic.git
   ```
2. Open the project in Xcode.
3. Build and run:
   - Select a target device or simulator.
   - Build and run the app.

## Usage

1. Scanning Ingredients:
 - Open the app and point the camera at the ingredient list.
 - The app will automatically detect text and identify any allergens based on the user's preferences.
2. Upload a Photo:
 - If you have a photo of the ingredient list, use the upload feature via PhotoKit.
 - The app will process the image and highlight allergens.
3. Haptic Feedback:
 - Tactile feedback will notify you when allergens are detected.

## Screenshots

### 1. Ingredient Scanning Camera


### 2. Uplad photos Scanning


### 3. Allergen Detection


### 4. User Allergies 


