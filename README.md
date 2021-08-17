# shop_app

Tutorial from [Flutter & Dart - The Complete Guide [2021 Edition]](https://www.udemy.com/course/learn-flutter-dart-to-build-ios-android-apps/)

## Setup 

Create a firebase project and enable `Realtime Database`
copy the url and also gram api key of the project from project settings 
create file in `/lib/config.dart` fill it up with
```dart
const String SERVER_URL = 'https://your-firebase-project'; // do not add `/` in end
const String API_KEY = 'firebase-api-key';
```
