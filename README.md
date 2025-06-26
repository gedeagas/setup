# macOS Setup Script

This repository provides [`setup.sh`](setup.sh:1), an interactive Bash script to automate the installation and configuration of essential applications, developer tools, and programming runtimes on macOS.

## Features

- **Menu-driven installation**: Choose between installing all tools, essentials, developer tools, programming runtimes, or a custom selection.
- **Programming runtimes**: Installs and configures Node.js (via nvm), Ruby (via rbenv), and Java (via sdkman) with specific versions.
- **Doctor mode**: Checks your environment for required tools and runtimes, reporting their installation status.
- **Custom selection**: Fine-grained control over which tools and language versions to install.
- **Post-install guidance**: Reminds you to reload your shell configuration for new tools to take effect.

## Prerequisites

- macOS with [Homebrew](https://brew.sh/) installed (for some developer tools).
- Internet connection for downloading tools and runtimes.
- Terminal access with Bash or Zsh.

## Usage

1. **Clone or download this repository.**
2. **Make the script executable:**
   ```sh
   chmod +x setup.sh
   ```
3. **Run the script:**
   ```sh
   ./setup.sh
   ```

## Menu Options

Upon running the script, you'll be presented with the following options:

1. **Install All**
   Installs essential apps, developer tools, programming runtimes, entertainment apps, work apps, and social media/messaging apps.

2. **Essentials Apps**
   Installs a curated set of productivity and utility applications:
   - Reminders Menu Bar
   - JordanBaird Ice
   - Stats CLI Tool
   - Raycast
   - Rectangle
   - Cloudflare WARP
   - Bitwarden
   - Google Chrome
   - Pearcleaner

3. **Developer Tools**
   Installs:
   - nvm (Node Version Manager)
   - rbenv (Ruby Version Manager)
   - sdkman (Java, Kotlin, etc.)
   - Xcodes
   - Visual Studio Code
   - Postman
   - pyenv (Python Version Manager)
   - DBeaver Community (Database Client)
   - Oh My Zsh (Zsh Framework)
   - MeetingBar (Menu Bar Calendar)

4. **Programming Runtimes (Node.js, Ruby, Java)**
   Installs specific versions:
   - Node.js v18.20.7 (via nvm)
   - Ruby 3.1.6p260 (via rbenv)
   - OpenJDK 17.0.14 Zulu (via sdkman)

5. **Entertainment Apps**
   Installs popular entertainment applications:
   - Spotify
   - VLC

6. **Work Apps**
   Installs popular work applications:
   - Slack
   - TradingView
   - Notion

7. **Social Media and Messaging**
   Installs messaging and social media applications:
   - WhatsApp
   - Discord

8. **Custom Selection**
   Allows you to choose which tools, entertainment apps, work apps, social media/messaging apps, and language versions to install, with interactive prompts for each.

9. **Doctor (Check Environment)**
   Checks for the presence and versions of nvm, rbenv, sdkman, Node.js, Ruby, Java, and other tools. Reports status and provides troubleshooting info.

## Interactive Prompts

- For some options, you'll be prompted to confirm installation of specific tools or language versions (y/n).
- After installation, you'll be asked if you want to source your `~/.zshrc` to apply changes immediately.

## Post-Installation

- **Reload your shell configuration**:  
  The script appends necessary initialization lines to your `~/.zshrc` for nvm, rbenv, and sdkman.  
  You can reload it with:
  ```sh
  source ~/.zshrc
  ```
  This step is required before using newly installed tools.

## Troubleshooting

- If a tool is reported as "not installed" in Doctor mode, re-run the script and select the appropriate install option.
- Ensure you have Homebrew installed for developer tools.
- For issues with shell initialization, check your `~/.zshrc` for the added lines.

## Script Structure

- **Helper functions**: Check for installed tools and versions.
- **Menu logic**: Sets install flags based on your choices.
- **Install routines**: Installs apps/tools via Homebrew, cask, or direct download.
- **Doctor mode**: Verifies environment and prints status.
- **Finalization**: Offers to reload your shell configuration.

## License

MIT License

---

*Generated from [`setup.sh`](setup.sh:1)*