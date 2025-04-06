# TermuXify

Terminal customization tool for Termux

## Installation

### Method 1: Using dpkg (Recommended)
```bash
# Download the latest .deb package
wget https://github.com/yourusername/TermuXify/releases/latest/download/termuxify.deb

# Install the package
dpkg -i termuxify.deb
```

### Method 2: Manual Installation
```bash
# Clone the repository
git clone https://github.com/yourusername/TermuXify.git

# Change to directory
cd TermuXify

# Make install script executable
chmod +x install.sh

# Run installer
./install.sh
```

After installation, you can run TermuXify from anywhere by typing:
```bash
termuxify
```

## Features

### Appearance
- **Font Customization**: Size and style options
- **Color Schemes**: Professional presets including Dark, Light, Solarized themes
- **Cursor Styling**: Choose from block, underline, or bar

### Configuration
- **Extra Keys**: Quick access to essential keyboard shortcuts
- **Terminal Settings**: Configure bell behavior and other options
- **Custom Shortcuts**: Create your own keyboard combinations
- **MOTD**: Customize your Message of the Day

### Management
- **Alias System**: Create and manage terminal shortcuts
- **Backup & Restore**: Preserve your perfect setup
- **Clean Uninstall**: Remove all customizations when needed

## Advanced Usage

### Clean Uninstall
The clean uninstall option completely removes all customizations, returning your Termux environment to default settings.

## Building from Source

### Prerequisites
```bash
apt update
apt install build-essential dpkg
```

### Building the Package
```bash
# Make build script executable
chmod +x build.sh

# Run build script
./build.sh
```

This will create a file named `termuxify_0.1.0.deb` in the current directory.

### Installing the Package
```bash
# Install the package
dpkg -i termuxify_0.1.0.deb

# If you see any dependency errors, run:
apt install -f
```

### Removing the Package
```bash
# Remove the package
dpkg -r termuxify

# Or purge (remove including config files)
dpkg -P termuxify
```

## Design Philosophy

TermuXify follows a minimal and professional design approach, focusing on:
- Clean, distraction-free interface
- Consistent visual language
- Efficient workflow optimization
- Subtle visual feedback

All configuration files are automatically backed up before any changes are made, allowing for safe experimentation with your terminal's appearance.
