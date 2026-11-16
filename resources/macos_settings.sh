#!/bin/bash
echo "show the ~/Library folder in Finder"
chflags nohidden ~/Library

echo "Enable Quit Menu item on finder"
defaults write com.apple.Finder QuitMenuItem 1
killall -HUP Finder

# Check for software updates daily, not just once per week
echo "Software updates checking daily"
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

echo "Finder: show all filename extensions"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo "show hidden files by default"
defaults write com.apple.Finder AppleShowAllFiles -bool true

echo "only use UTF-8 in Terminal.app"
defaults write com.apple.terminal StringEncodings -array 4

echo "expand save dialog by default"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

echo "Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)"
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

echo "Enable subpixel font rendering on non-Apple LCDs"
defaults write NSGlobalDomain AppleFontSmoothing -int 2

echo "Use current directory as default search scope in Finder"
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

echo "Show Path bar in Finder"
defaults write com.apple.finder ShowPathbar -bool true

echo "Show Status bar in Finder"
defaults write com.apple.finder ShowStatusBar -bool true

echo "Disable press-and-hold for keys in favor of key repeat"
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

echo "Set a blazingly fast keyboard repeat rate"
defaults write NSGlobalDomain KeyRepeat -int 1

echo "Set a shorter Delay until key repeat"
defaults write NSGlobalDomain InitialKeyRepeat -int 15

echo "Enable tap to click (Trackpad)"
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

echo "Enable Safari’s debug menu"
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

echo "Set custom location for screenshots and screen recordings"
mkdir -p ~/Pictures/Screenshots
defaults write com.apple.screencapture location ~/Pictures/Screenshots
killall SystemUIServer

echo "Group windows by application in Mission Control (fixes tiny window previews with AeroSpace, see nikitabobko/AeroSpace#315)"
defaults write com.apple.dock expose-group-apps -bool true

# Undocumented keys. Apps pick them up at launch, system items (Control Center,
# clock) only after a logout. Revert with `defaults -currentHost delete -globalDomain <key>`.
echo "Tighten menu bar item spacing (fits more items beside the notch)"
defaults -currentHost write -globalDomain NSStatusItemSpacing -int 8
defaults -currentHost write -globalDomain NSStatusItemSelectionPadding -int 6

# macOS pins its clock to the far right; Itsycal's can be ⌘-dragged anywhere.
echo "Show the time in Itsycal, shrink the system clock to analog"
defaults write com.mowglii.ItsycalApp ClockFormat -string "HH:mm:ss"
defaults write com.apple.menuextra.clock IsAnalog -bool true
killall ControlCenter >/dev/null 2>&1

# Stats rewrites its prefs on quit, so this only sticks while it is not running.
# The separator adds the spacing on both sides of it: 1 gives 9pt between modules.
echo "Stats: combine modules in one menu bar item, tight spacing, with separators"
defaults write eu.exelban.Stats CombinedModules -bool true
defaults write eu.exelban.Stats CombinedModules_spacing -string 1
defaults write eu.exelban.Stats CombinedModules_separator -bool true

echo "Appearance: switch light/dark automatically at sunrise/sunset"
defaults delete -g AppleInterfaceStyle >/dev/null 2>&1
defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool true

# Root-owned and cached by corebrightnessd, hence sudo and the restart. The keys
# only exist once the setting has been touched in System Settings > Keyboard.
echo "Keyboard backlight: turn off after 10s idle"
plist=/var/root/Library/Preferences/com.apple.CoreBrightness.plist
sudo /usr/libexec/PlistBuddy -c "Set :KeyboardBacklight:KeyboardBacklightIdleDimTime 10" \
  -c "Set ':Keyboard Dim Time' 10" "$plist" && sudo killall corebrightnessd \
  || echo "⚠️  Keyboard dim time not set: change it once in System Settings > Keyboard, then rerun" >&2

echo "Kill affected applications"
for app in Safari Finder Dock Mail SystemUIServer; do killall "$app" >/dev/null 2>&1; done
