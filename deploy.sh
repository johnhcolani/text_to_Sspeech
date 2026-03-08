#!/usr/bin/env bash
# Deploy script for Mac/Linux: git push, Flutter clean, build web + iOS + Android, Firebase hosting

set -e

read -p "Enter commit message: " MESSAGE
MESSAGE=${MESSAGE:-update web app}

echo ""
echo "Adding files..."
git add .

echo ""
echo "Committing..."
git commit -m "$MESSAGE"

echo ""
echo "Pushing to GitHub..."
git push origin main

echo ""
echo "Clean Flutter project..."
flutter clean

echo ""
echo "Building Flutter web..."
flutter build web --release

echo ""
echo "Deploying to Firebase Hosting..."
firebase deploy --only hosting

echo ""
echo "Building iOS..."
flutter build ios --release

echo ""
echo "Building Android..."
flutter build appbundle --release

echo ""
echo "Done!"
