#!/bin/bash

# --- Programming Runtimes Version Variables ---
NODE_VERSION="18.20.7"
RUBY_VERSION="3.1.6"
RUBY_VERSION_PATCH="3.1.6p260"
JAVA_VERSION="17.0.14-zulu"
JAVA_VENDOR_STRING="Zulu17.56+15-CA"
JAVA_VERSION_DISPLAY="17.0.14"
# ---------------------------------------------

# Helper: check if nvm is installed (by directory)
is_nvm_installed() {
    [ -d "$HOME/.nvm" ]
}

# Helper: check if rbenv is installed (by command)
is_rbenv_installed() {
    command -v rbenv &>/dev/null
}

# Helper: check if sdkman is installed (by directory)
is_sdkman_installed() {
    [ -d "$HOME/.sdkman" ]
}

# Helper: check if nvm has a specific Node.js version
is_nvm_version_installed() {
    nvm ls "$1" 2>/dev/null | grep -q "v$1"
}

# Helper: check if rbenv has a specific Ruby version
is_rbenv_version_installed() {
    rbenv versions --bare 2>/dev/null | grep -q "^$1$"
}

# Helper: check if sdkman has a specific Java version
is_sdkman_java_installed() {
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk list java | grep -q "$1"
}

main() {
echo "🛠️  Starting macOS setup..."

# Menu-driven selection
echo ""
echo "Select what you want to install:"
echo "1) Install All"
echo "2) Essentials Apps"
echo "3) Developer Tools"
echo "4) Programming Runtimes (Node.js, Ruby, Java)"
echo "5) Entertainment Apps"
echo "6) Work Apps"
echo "7) Custom Selection"
echo "8) Doctor (Check Environment)"
read -p "Enter your choice [1-8]: " main_choice

# Define install flags
INSTALL_ESSENTIALS=false
INSTALL_DEVTOOLS=false
INSTALL_LANGVERSIONS=false
CUSTOM_SELECTION=false

case "$main_choice" in
    1)
        INSTALL_ESSENTIALS=true
        INSTALL_DEVTOOLS=true
        INSTALL_LANGVERSIONS=true
        INSTALL_ENTERTAINMENT=true
        INSTALL_WORK=true
        ;;
    2)
        INSTALL_ESSENTIALS=true
        ;;
    3)
        INSTALL_DEVTOOLS=true
        ;;
    4)
        INSTALL_LANGVERSIONS=true
        ;;
    5)
        INSTALL_ENTERTAINMENT=true
        ;;
    6)
        INSTALL_WORK=true
        ;;
    7)
        CUSTOM_SELECTION=true
        ;;
    8)
        DOCTOR_MODE=true
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# -- Doctor: Environment Check --
if [ "${DOCTOR_MODE:-false}" = true ]; then
    echo ""
    echo "=============================="
    echo "🩺 Doctor: Environment Check"
    echo "=============================="
    echo ""

    # Developer Tools
    echo "Developer Tools:"
    if is_nvm_installed; then
        echo "  ✅ nvm is installed"
    else
        echo "  ❌ nvm is NOT installed"
    fi
    if is_rbenv_installed; then
        echo "  ✅ rbenv is installed"
    else
        echo "  ❌ rbenv is NOT installed"
    fi
    if is_sdkman_installed; then
        echo "  ✅ sdkman is installed"
    else
        echo "  ❌ sdkman is NOT installed"
    fi
    echo ""

    # Programming Runtimes
    echo "Programming Runtimes:"
    # Node.js
    if is_nvm_installed; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        if is_nvm_version_installed "$NODE_VERSION"; then
            echo "  ✅ Node.js v$NODE_VERSION (nvm)"
        else
            echo "  ❌ Node.js v$NODE_VERSION (nvm) NOT installed"
            echo -n "     Installed Node.js versions: "
            nvm ls | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' | tr '\n' ' '
            echo
            if command -v node &>/dev/null; then
                echo -n "     node -v: "
                node -v
            fi
        fi
    else
        echo "  ⚠️  Skipping Node.js check (nvm not installed)"
    fi
    # Ruby
    if is_rbenv_installed; then
        if is_rbenv_version_installed "$RUBY_VERSION"; then
            echo "  ✅ Ruby $RUBY_VERSION_PATCH (rbenv)"
        else
            echo "  ❌ Ruby $RUBY_VERSION_PATCH (rbenv) NOT installed"
            echo -n "     Installed Ruby versions (rbenv): "
            rbenv versions --bare | tr '\n' ' '
            echo
            if command -v ruby &>/dev/null; then
                echo -n "     ruby -v: "
                ruby -v
            fi
        fi
    else
        echo "  ⚠️  Skipping Ruby check (rbenv not installed)"
    fi
    # Java
    if is_sdkman_installed; then
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        if sdk list java | grep -q "$JAVA_VERSION"; then
            JAVA_VERSION_OUTPUT=$(java -version 2>&1 | head -n 1)
            if echo "$JAVA_VERSION_OUTPUT" | grep -q "$JAVA_VERSION_DISPLAY"; then
                if echo "$JAVA_VERSION_OUTPUT" | grep -q "$JAVA_VENDOR_STRING"; then
                    echo "  ✅ OpenJDK $JAVA_VERSION_DISPLAY $JAVA_VENDOR_STRING (sdkman)"
                else
                    echo "  ⚠️  OpenJDK $JAVA_VERSION_DISPLAY is active, but vendor string ($JAVA_VENDOR_STRING) not found"
                    echo "     java -version: $JAVA_VERSION_OUTPUT"
                fi
            else
                echo "  ❌ OpenJDK $JAVA_VERSION_DISPLAY $JAVA_VENDOR_STRING (sdkman) installed but not active"
                echo "     java -version: $JAVA_VERSION_OUTPUT"
            fi
            echo -n "     Installed Java versions (sdkman): "
            sdk list java | grep -E '^[ >*] +[0-9]+\.[0-9]+\.[0-9]+.*zulu' | awk '{print $1}' | tr '\n' ' '
            echo
        else
            echo "  ❌ OpenJDK $JAVA_VERSION_DISPLAY $JAVA_VENDOR_STRING (sdkman) NOT installed"
        fi
    else
        echo "  ⚠️  Skipping Java check (sdkman not installed)"
    fi

    echo ""
    echo "Doctor check complete."
    exit 0
fi

# Custom selection submenu
INSTALL_REMINDERS=false
INSTALL_ICE=false
INSTALL_STATS=false
INSTALL_WARP=false
INSTALL_NVM=false
INSTALL_RBENV=false
INSTALL_SDKMAN=false
INSTALL_NODE_VERSION=false
INSTALL_RUBY_VERSION=false
INSTALL_JAVA_VERSION=false

if [ "$CUSTOM_SELECTION" = true ]; then
    echo ""
    echo "Select which tools to install (y/n):"
    prompt_and_set_flag "Reminders Menu Bar?" INSTALL_REMINDERS
    prompt_and_set_flag "JordanBaird Ice?" INSTALL_ICE
    prompt_and_set_flag "Stats CLI Tool?" INSTALL_STATS
    prompt_and_set_flag "Cloudflare WARP?" INSTALL_WARP
    prompt_and_set_flag "nvm (Node Version Manager)?" INSTALL_NVM
    prompt_and_set_flag "rbenv (Ruby Version Manager)?" INSTALL_RBENV
    prompt_and_set_flag "SDKMAN (Java, Kotlin, etc.)?" INSTALL_SDKMAN

    echo ""
    echo "Select which entertainment apps to install (y/n):"
    prompt_and_set_flag "Spotify?" INSTALL_SPOTIFY

    echo ""
    echo "Select which work apps to install (y/n):"
    prompt_and_set_flag "Slack?" INSTALL_SLACK

    echo ""
    echo "Select which language versions to install (y/n):"
    # Node.js via nvm
    if command -v nvm &>/dev/null; then
        prompt_and_set_flag "Node.js v$NODE_VERSION via nvm?" INSTALL_NODE_VERSION
    else
        echo "⚠️  nvm not found, skipping Node.js version install."
    fi
    # Ruby via rvm
    if command -v rvm &>/dev/null; then
        prompt_and_set_flag "Ruby $RUBY_VERSION_PATCH via rvm?" INSTALL_RUBY_VERSION
    else
        echo "⚠️  rvm not found, skipping Ruby version install."
    fi
    # Java via sdkman
    if [ -d "$HOME/.sdkman" ]; then
        prompt_and_set_flag "OpenJDK $JAVA_VERSION_DISPLAY ($JAVA_VENDOR_STRING) via sdkman?" INSTALL_JAVA_VERSION
    else
        echo "⚠️  sdkman not found, skipping Java version install."
    fi
fi

# -- Essentials & Developer Tools (DRY) --
ESSENTIALS_LIST=(
    "reminders-menubar:cask:Reminders Menu Bar:INSTALL_REMINDERS"
    "jordanbaird-ice:cask:JordanBaird Ice:INSTALL_ICE"
    "stats:cli:Stats CLI Tool:INSTALL_STATS"
    "raycast:cask:Raycast"
    "cloudflare-warp:cask:Cloudflare WARP:INSTALL_WARP"
    "bitwarden:cask:Bitwarden"
    "google-chrome:cask:Google Chrome"
)
DEVTOOLS_LIST=(
    "nvm:custom:nvm (Node Version Manager):INSTALL_NVM"
    "rbenv:custom:rbenv (Ruby Version Manager):INSTALL_RBENV"
    "sdkman:custom:SDKMAN (Java, Kotlin, etc.):INSTALL_SDKMAN"
)
ENTERTAINMENT_APPS_LIST=(
    "spotify:cask:Spotify:INSTALL_SPOTIFY"
)

for entry in "${ESSENTIALS_LIST[@]}"; do
    IFS=":" read -r app type name flag <<< "$entry"
    if [ "$INSTALL_ESSENTIALS" = true ] || [ "${!flag}" = true ]; then
        if [ "$type" = "cask" ]; then
            install_cask_app "$app" "$name"
        elif [ "$type" = "cli" ]; then
            install_cli_tool "$app" "$name"
        fi
    fi
done

WORK_APPS_LIST=(
    "slack:cask:Slack:INSTALL_SLACK"
)

for entry in "${DEVTOOLS_LIST[@]}"; do
    IFS=":" read -r tool type name flag <<< "$entry"
    if [ "$INSTALL_DEVTOOLS" = true ] || [ "${!flag}" = true ]; then
        case "$tool" in
            nvm)
                if [ -d "$HOME/.nvm" ]; then
                    echo "✅ nvm is already installed."
                else
                    if prompt_install "$name"; then
                        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
                        {
                            echo ''
                            echo 'export NVM_DIR="$HOME/.nvm"'
                            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
                        } >> ~/.zshrc
                    fi
                fi
                ;;
            rbenv)
                if command -v rbenv &>/dev/null; then
                    echo "✅ rbenv is already installed."
                else
                    if prompt_install "$name"; then
                        brew install rbenv
                        echo 'eval "$(rbenv init -)"' >> ~/.zshrc
                    fi
                fi
                ;;
            sdkman)
                if [ -d "$HOME/.sdkman" ]; then
                    echo "✅ SDKMAN is already installed."
                else
                    if prompt_install "$name"; then
                        curl -s "https://get.sdkman.io" | bash
                        echo 'source "$HOME/.sdkman/bin/sdkman-init.sh"' >> ~/.zshrc
                    fi
                fi
                ;;
            xcodes)
                if command -v xcodes &>/dev/null; then
                    echo "✅ Xcodes is already installed."
                else
                    if prompt_install "$name"; then
                        brew install xcodes
                    fi
                fi
                ;;
        esac
    fi
done

# Entertainment Apps Section
for entry in "${ENTERTAINMENT_APPS_LIST[@]}"; do
    IFS=":" read -r app type name flag <<< "$entry"
    if [ "$INSTALL_ENTERTAINMENT" = true ] || [ "${!flag}" = true ]; then
        if [ "$type" = "cask" ]; then
            install_cask_app "$app" "$name"
        elif [ "$type" = "cli" ]; then
            install_cli_tool "$app" "$name"
        fi
    fi
done

# Work Apps Section
for entry in "${WORK_APPS_LIST[@]}"; do
    IFS=":" read -r app type name flag <<< "$entry"
    if [ "$INSTALL_WORK" = true ] || [ "${!flag}" = true ]; then
        if [ "$type" = "cask" ]; then
            install_cask_app "$app" "$name"
        elif [ "$type" = "cli" ]; then
            install_cli_tool "$app" "$name"
        fi
    fi
done
# -- Programming Runtimes Installs --
if [ "$INSTALL_LANGVERSIONS" = true ]; then
    echo ""
    echo "=============================="
    echo "🔧 Programming Runtimes Setup"
    echo "=============================="
    echo ""
    echo "Select which programming runtimes to install (y/n):"
    # Node.js via nvm
    echo "→ Checking Node.js (nvm)..."
    if is_nvm_installed; then
        read -p "Node.js v$NODE_VERSION via nvm? (y/n): " ans
        [[ "$ans" =~ ^[Yy]$ ]] && INSTALL_NODE_VERSION=true
    else
        echo "⚠️  nvm not found, skipping Node.js version install."
    fi
    # Ruby via rbenv
    echo "→ Checking Ruby (rbenv)..."
    if is_rbenv_installed; then
        read -p "Ruby $RUBY_VERSION_PATCH via rbenv? (y/n): " ans
        [[ "$ans" =~ ^[Yy]$ ]] && INSTALL_RUBY_VERSION=true
    else
        echo "⚠️  rbenv not found, skipping Ruby version install."
    fi
    # Java via sdkman
    echo "→ Checking Java (sdkman)..."
    if is_sdkman_installed; then
        read -p "OpenJDK $JAVA_VERSION_DISPLAY ($JAVA_VENDOR_STRING) via sdkman? (y/n): " ans
        [[ "$ans" =~ ^[Yy]$ ]] && INSTALL_JAVA_VERSION=true
    else
        echo "⚠️  sdkman not found, skipping Java version install."
    fi
    echo ""
    echo "------------------------------"
    echo "Starting Programming Runtimes installation..."
    echo "------------------------------"
fi

[ "$INSTALL_NODE_VERSION" = true ] && install_runtime node
[ "$INSTALL_RUBY_VERSION" = true ] && install_runtime ruby
[ "$INSTALL_JAVA_VERSION" = true ] && install_runtime java

# Final message
echo ""
echo "🚀 Setup complete!"
echo "🔁 Tools like nvm, rbenv, and sdkman require reloading your shell configuration."

# Offer to source .zshrc
read -p $'\nWould you like to source your ~/.zshrc now to apply changes? (y/n): ' should_source
if [[ "$should_source" =~ ^[Yy]$ ]]; then
    echo "📦 Sourcing ~/.zshrc..."
    source ~/.zshrc
    echo "✅ Environment updated!"
else
    echo "⚠️  Remember to run: source ~/.zshrc before using tools like nvm."
fi
}

# Only run main if script is executed, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi


