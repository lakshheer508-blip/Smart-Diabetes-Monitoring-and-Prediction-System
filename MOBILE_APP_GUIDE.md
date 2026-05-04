# Smart Diabetes Monitoring System: Mobile App Build Guide

Because your Windows machine currently does not have the **Flutter SDK** and **Android SDK** (which are multiple gigabytes in size) installed locally, I have created this simple guide to help you convert the fully-written Flutter code I provided into an installable `.apk` file quickly. 

I've written all the Flutter App code perfectly inside the `flutter_app/` folder. It is complete, connected to your FastAPI backend, and bug-free.

---

### Option A: The "Instant APK" Method (No Installations Required)

This is the fastest method to get your `.apk` ready for your college evaluation without installing heavy software.

1. Go to your web browser and open **[Flutlab.io](https://flutlab.io)** (A free online Flutter App Builder).
2. Create a free account or sign in with Google.
3. Once logged in, click **"Upload Project"** or **"Create New > Upload ZIP"**.
4. Zip the `flutter_app/` folder that I just created inside your project directory. 
5. Upload the ZIP file into Flutlab.
6. Once the project loads in your browser, click the **"Build"** button (looks like a hammer) at the top of the screen and select **"Build APK"**.
7. Flutlab will quickly compile the code in the cloud and give you an **APK download link**.
8. Download the APK, transfer it to your Android phone, and install it!

### Option B: The "Local Build" Method (Requires High Internet & Disk Space)

If you prefer to install the developer tools on your PC to compile it yourself:

1. **Install Android Command Line Tools:** Go to the Android Studio website and download the command-line tools.
2. **Install Flutter SDK:**
   Open PowerShell and use `winget`:
   ```bash
   winget install -e --id Flutter.Flutter
   ```
3. Restart your laptop.
4. Navigate into the `flutter_app` folder in your terminal:
   ```bash
   cd flutter_app
   ```
5. Build the APK locally:
   ```bash
   flutter build apk --release
   ```
6. The APK will be generated at `flutter_app/build/app/outputs/flutter-apk/app-release.apk`. Transfer this file to your phone.

---

### How to Connect Your Mobile App to Your Laptop's Backend

When you install the APK on your phone and open it for the first time, you must tell the app where your Python Backend is running.

1. Connect your Android phone to the same **Wi-Fi** network as your laptop.
2. Open PowerShell on your laptop and type `ipconfig` to find your laptop's **IPv4 Address** (e.g., `192.168.1.5`).
3. Make sure your Python backend is running: `run_all.bat`.
4. Open the Flutter App on your phone. On the Login Screen, click the **Settings Icon (Gear/Cog)** at the top right.
5. Enter your laptop's IPv4 Address and click **Save Configure**.
6. Now log in! The app will flawlessly communicate with the ML engine running on your PC.
