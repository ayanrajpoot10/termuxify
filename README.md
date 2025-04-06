# TermuXify

Terminal customization tool for Termux

## Installation

### Method 1: Using apt (Recommended)
```bash
# Add the apt repository
echo "deb [trusted=yes] https://ayanrajpoot10.github.io/termuxify/ stable main" >> $PREFIX/etc/apt/sources.list

# Install termuxify
pkg install termuxify
```

### Method 2: Manual Installation
```bash
# Clone the repository
git clone https://github.com/Ayanrajpoot10/termuxify.git

# Change to directory
cd termuxify

# Make install script executable
chmod +x install.sh

# Run installer
./install.sh
```

After installation, you can run termuxify from anywhere by typing:
```bash
termuxify
```

## Features

### Appearance
- **Font Customization**: Size and style options
- **Color Schemes**: Professional presets including Dark, Light, Solarized themes
- **Cursor Styling**: Choose from block, underline, or bar

### Configuration
- **MOTD**: Customize your Message of the Day

### Management
- **Alias System**: Create and manage terminal shortcuts
