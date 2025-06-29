#!/bin/bash

# --- Programming Runtimes Version Variables ---
NODE_VERSION="18.20.7"
RUBY_VERSION="3.1.6"
RUBY_VERSION_PATCH="3.1.6p260"
JAVA_VERSION="17.0.14-zulu"
JAVA_VENDOR_STRING="Zulu17.56+15-CA"
JAVA_VERSION_DISPLAY="17.0.14"
# ---------------------------------------------

# --- Interactive Prompt Helper ---
prompt_and_set_flag() {
    local prompt="$1"
    local flag_var="$2"
    local ans
    read -p "$prompt [y/n]: " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        eval "$flag_var=true"
    else
        eval "$flag_var=false"
    fi
}

# --- Missing prompt_install function ---
prompt_install() {
    local app_name="$1"
    local ans
    read -p "Install $app_name? [y/n]: " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# --- Category Install Prompt Helper ---
prompt_install_all_or_individual() {
    local category_name="$1"
    local list_var="$2"
    local category_flag="$3"
    local all_ans

    echo "[DEBUG] Entered prompt_install_all_or_individual"
    echo "[DEBUG] category_name: $category_name"
    echo "[DEBUG] list_var: $list_var"
    echo "[DEBUG] category_flag: $category_flag"

    read -p "Install all $category_name? (y/n): " all_ans
    echo "[DEBUG] User answered: $all_ans"

    # Helper: install a single entry immediately
    local install_entry
    install_entry() {
        local app="$1"
        local type="$2"
        local name="$3"
        # Only print install message for the category if not already printed
        if [ -z "$_printed_category" ]; then
            echo ""
            echo "Installing $category_name..."
            _printed_category=1
        fi
        if [ "$type" = "cask" ]; then
            install_cask_app "$app" "$name"
        elif [ "$type" = "cli" ]; then
            install_cli_tool "$app" "$name"
        elif [ "$type" = "custom" ]; then
            # Custom install logic for devtools
            case "$app" in
                nvm)
                    if [ -d "$HOME/.nvm" ]; then
                        echo "✅ nvm is already installed."
                    else
                        echo "⬇️  Installing nvm..."
                        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
                        {
                            echo ''
                            echo 'export NVM_DIR="$HOME/.nvm"'
                            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
                        } >> ~/.zshrc
                    fi
                    ;;
                rbenv)
                    if command -v rbenv &>/dev/null; then
                        echo "✅ rbenv is already installed."
                    else
                        echo "⬇️  Installing rbenv..."
                        brew install rbenv
                        echo 'eval \"$(rbenv init -)\"' >> ~/.zshrc
                    fi
                    ;;
                sdkman)
                    if [ -d "$HOME/.sdkman" ]; then
                        echo "✅ SDKMAN is already installed."
                    else
                        echo "⬇️  Installing SDKMAN..."
                        curl -s \"https://get.sdkman.io\" | bash
                        echo 'source \"$HOME/.sdkman/bin/sdkman-init.sh\"' >> ~/.zshrc
                    fi
                    ;;
                oh-my-zsh)
                    if [ -d "$HOME/.oh-my-zsh" ]; then
                        echo "✅ Oh My Zsh is already installed."
                    else
                        echo "⬇️  Installing Oh My Zsh..."
                        sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended
                    fi
                    ;;
            esac
        fi
    }

    if [[ "$all_ans" =~ ^[Yy]$ ]]; then
        eval "$category_flag=true"
        echo "[DEBUG] Set $category_flag to true"
        # Install all entries immediately
        local entry app type name flag
        eval "entries=(\"\${${list_var}[@]}\")"
        for entry in "${entries[@]}"; do
            IFS=":" read -r app type name flag <<< "$entry"
            install_entry "$app" "$type" "$name"
            eval "$flag=true"
        done
    else
        eval "$category_flag=false"
        echo "[DEBUG] Set $category_flag to false"
        local entry app type name flag
        eval "entries=(\"\${${list_var}[@]}\")"
        for entry in "${entries[@]}"; do
            IFS=":" read -r app type name flag <<< "$entry"
            prompt_and_set_flag "Install $name?" "$flag"
            if [ "${!flag}" = true ]; then
                install_entry "$app" "$type" "$name"
            fi
        done
    fi
    unset _printed_category
}

# --- App Install Helper Functions ---
install_cask_app() {
    local app_id="$1"
    local app_name="$2"
    if brew list --cask "$app_id" &>/dev/null; then
        echo "✅ $app_name ($app_id) is already installed (cask)."
    else
        echo "⬇️  Installing $app_name ($app_id) via Homebrew Cask..."
        brew install --cask "$app_id"
    fi
}

install_cli_tool() {
    local cli_id="$1"
    local cli_name="$2"
    if brew list "$cli_id" &>/dev/null; then
        echo "✅ $cli_name ($cli_id) is already installed (cli)."
    else
        echo "⬇️  Installing $cli_name ($cli_id) via Homebrew..."
        brew install "$cli_id"
    fi
}

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
    if ! is_nvm_installed; then
        return 1
    fi
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm ls "$1" 2>/dev/null | grep -q "v$1"
}

# Helper: check if rbenv has a specific Ruby version
is_rbenv_version_installed() {
    if ! is_rbenv_installed; then
        return 1
    fi
    rbenv versions --bare 2>/dev/null | grep -q "^$1$"
}

# Helper: check if sdkman has a specific Java version
is_sdkman_java_installed() {
    if ! is_sdkman_installed; then
        return 1
    fi
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk list java | grep -q "$1"
}

# --- Missing install_runtime function ---
install_runtime() {
    local runtime="$1"
    
    case "$runtime" in
        node)
            if [ "$INSTALL_LANGVERSIONS" = true ] || [ "$INSTALL_NODE_VERSION" = true ]; then
                if is_nvm_installed; then
                    export NVM_DIR="$HOME/.nvm"
                    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
                    
                    if is_nvm_version_installed "$NODE_VERSION"; then
                        echo "✅ Node.js v$NODE_VERSION is already installed via nvm."
                    else
                        echo "⬇️  Installing Node.js v$NODE_VERSION via nvm..."
                        nvm install "$NODE_VERSION"
                        nvm use "$NODE_VERSION"
                        nvm alias default "$NODE_VERSION"
                    fi
                else
                    echo "⚠️  nvm is not installed. Cannot install Node.js version."
                fi
            fi
            ;;
        ruby)
            if [ "$INSTALL_LANGVERSIONS" = true ] || [ "$INSTALL_RUBY_VERSION" = true ]; then
                if is_rbenv_installed; then
                    if is_rbenv_version_installed "$RUBY_VERSION"; then
                        echo "✅ Ruby $RUBY_VERSION is already installed via rbenv."
                    else
                        echo "⬇️  Installing Ruby $RUBY_VERSION via rbenv..."
                        rbenv install "$RUBY_VERSION"
                        rbenv global "$RUBY_VERSION"
                    fi
                else
                    echo "⚠️  rbenv is not installed. Cannot install Ruby version."
                fi
            fi
            ;;
        java)
            if [ "$INSTALL_LANGVERSIONS" = true ] || [ "$INSTALL_JAVA_VERSION" = true ]; then
                if is_sdkman_installed; then
                    source "$HOME/.sdkman/bin/sdkman-init.sh"
                    if is_sdkman_java_installed "$JAVA_VERSION"; then
                        echo "✅ OpenJDK $JAVA_VERSION is already installed via SDKMAN."
                    else
                        echo "⬇️  Installing OpenJDK $JAVA_VERSION via SDKMAN..."
                        sdk install java "$JAVA_VERSION"
                        sdk default java "$JAVA_VERSION"
                    fi
                else
                    echo "⚠️  SDKMAN is not installed. Cannot install Java version."
                fi
            fi
            ;;
    esac
}

main() {
    echo "🛠️  Starting macOS setup..."

    # Check if Homebrew is installed
    if ! command -v brew &>/dev/null; then
        echo "❌ Homebrew is not installed. Please install Homebrew first:"
        echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi

    # Menu-driven selection
    echo ""
    echo "Select what you want to install:"
    echo "1) Install All"
    echo "2) Essentials Apps"
    echo "3) Developer Tools"
    echo "4) Programming Runtimes (Node.js, Ruby, Java)"
    echo "5) Entertainment Apps"
    echo "6) Work Apps"
    echo "7) Social Media and Messaging"
    echo "8) Custom Selection"
    echo "9) Doctor (Check Environment)"
    read -p "Enter your choice [1-9]: " main_choice

    # Define install flags
    INSTALL_ESSENTIALS=false
    INSTALL_DEVTOOLS=false
    INSTALL_LANGVERSIONS=false
    INSTALL_ENTERTAINMENT=false
    INSTALL_WORK=false
    INSTALL_SOCIAL_MEDIA=false
    CUSTOM_SELECTION=false
    DOCTOR_MODE=false

    # Define arrays at the top level for proper scope
    ESSENTIALS_LIST=(
        "reminders-menubar:cask:Reminders Menu Bar:INSTALL_REMINDERS"
        "jordanbaird-ice:cask:JordanBaird Ice:INSTALL_ICE"
        "stats:cli:Stats CLI Tool:INSTALL_STATS"
        "raycast:cask:Raycast:INSTALL_RAYCAST"
        "cloudflare-warp:cask:Cloudflare WARP:INSTALL_WARP"
        "bitwarden:cask:Bitwarden:INSTALL_BITWARDEN"
        "google-chrome:cask:Google Chrome:INSTALL_GOOGLE_CHROME"
        "rectangle:cask:Rectangle:INSTALL_RECTANGLE"
        "pearcleaner:cask:Pearcleaner:INSTALL_PEARCLEANER"
    )
    DEVTOOLS_LIST=(
        "nvm:custom:nvm (Node Version Manager):INSTALL_NVM"
        "rbenv:custom:rbenv (Ruby Version Manager):INSTALL_RBENV"
        "sdkman:custom:SDKMAN (Java, Kotlin, etc.):INSTALL_SDKMAN"
        "visual-studio-code:cask:Visual Studio Code:INSTALL_VSCODE"
        "postman:cask:Postman:INSTALL_POSTMAN"
        "pyenv:cli:pyenv:INSTALL_PYENV"
        "dbeaver-community:cask:DBeaver Community:INSTALL_DBEAVER"
        "oh-my-zsh:custom:Oh My Zsh:INSTALL_OHMYZSH"
        "meetingbar:cli:MeetingBar:INSTALL_MEETINGBAR"
    )
    ENTERTAINMENT_APPS_LIST=(
        "spotify:cask:Spotify:INSTALL_SPOTIFY"
        "vlc:cask:VLC:INSTALL_VLC"
    )
    WORK_APPS_LIST=(
        "slack:cask:Slack:INSTALL_SLACK"
        "tradingview:cask:TradingView:INSTALL_TRADINGVIEW"
        "notion:cask:Notion:INSTALL_NOTION"
    )
    SOCIAL_MEDIA_APPS_LIST=(
        "whatsapp:cask:WhatsApp:INSTALL_WHATSAPP"
        "discord:cask:Discord:INSTALL_DISCORD"
    )

    case "$main_choice" in
        1)
            INSTALL_ESSENTIALS=true
            INSTALL_DEVTOOLS=true
            INSTALL_LANGVERSIONS=true
            INSTALL_ENTERTAINMENT=true
            INSTALL_WORK=true
            INSTALL_SOCIAL_MEDIA=true
            ;;
        2)
            prompt_install_all_or_individual "Essentials Apps" ESSENTIALS_LIST INSTALL_ESSENTIALS
            ;;
        3)
            prompt_install_all_or_individual "Developer Tools" DEVTOOLS_LIST INSTALL_DEVTOOLS
            ;;
        4)
            # Programming Runtimes: prompt for all or individual
            local all_ans
            read -p "Install all Programming Runtimes (Node.js, Ruby, Java)? (y/n): " all_ans
            if [[ "$all_ans" =~ ^[Yy]$ ]]; then
                INSTALL_LANGVERSIONS=true
            else
                INSTALL_LANGVERSIONS=false
                # Set per-runtime flags via prompt
                prompt_and_set_flag "Node.js v$NODE_VERSION via nvm" INSTALL_NODE_VERSION
                prompt_and_set_flag "Ruby $RUBY_VERSION_PATCH via rbenv" INSTALL_RUBY_VERSION
                prompt_and_set_flag "OpenJDK $JAVA_VERSION_DISPLAY ($JAVA_VENDOR_STRING) via sdkman" INSTALL_JAVA_VERSION
            fi
            ;;
        5)
            prompt_install_all_or_individual "Entertainment Apps" ENTERTAINMENT_APPS_LIST INSTALL_ENTERTAINMENT
            ;;
        6)
            prompt_install_all_or_individual "Work Apps" WORK_APPS_LIST INSTALL_WORK
            ;;
        7)
            prompt_install_all_or_individual "Social Media and Messaging Apps" SOCIAL_MEDIA_APPS_LIST INSTALL_SOCIAL_MEDIA
            ;;
        8)
            CUSTOM_SELECTION=true
            ;;
        9)
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

        # System Tools
        echo "System Tools:"
        if command -v brew &>/dev/null; then
            echo "  ✅ Homebrew is installed"
        else
            echo "  ❌ Homebrew is NOT installed"
        fi
        if command -v git &>/dev/null; then
            echo "  ✅ git is installed"
        else
            echo "  ❌ git is NOT installed"
        fi
        if command -v curl &>/dev/null; then
            echo "  ✅ curl is installed"
        else
            echo "  ❌ curl is NOT installed"
        fi
        if [ -f "$HOME/.zshrc" ]; then
            echo "  ✅ ~/.zshrc exists"
        else
            echo "  ❌ ~/.zshrc does NOT exist"
        fi
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
        if command -v pyenv &>/dev/null; then
            echo "  ✅ pyenv is installed"
        else
            echo "  ❌ pyenv is NOT installed"
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

        # Python
        if command -v pyenv &>/dev/null; then
            echo "  → Checking Python (pyenv)..."
            PYENV_PYTHON_VERSION=$(pyenv versions --bare 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1)
            if [ -n "$PYENV_PYTHON_VERSION" ]; then
                echo "  ✅ Python $PYENV_PYTHON_VERSION (pyenv)"
            else
                echo "  ⚠️  No Python versions installed via pyenv"
            fi
            if command -v python3 &>/dev/null; then
                echo -n "     python3 --version: "
                python3 --version
            fi
        else
            echo "  ⚠️  Skipping Python check (pyenv not installed)"
        fi

        echo ""
        echo "Doctor check complete."
        exit 0
    fi

    # Initialize individual flags for custom selection
    INSTALL_REMINDERS=false
    INSTALL_ICE=false
    INSTALL_STATS=false
    INSTALL_RAYCAST=false
    INSTALL_WARP=false
    INSTALL_BITWARDEN=false
    INSTALL_GOOGLE_CHROME=false
    INSTALL_RECTANGLE=false
    INSTALL_PEARCLEANER=false
    INSTALL_NVM=false
    INSTALL_RBENV=false
    INSTALL_SDKMAN=false
    INSTALL_VSCODE=false
    INSTALL_POSTMAN=false
    INSTALL_PYENV=false
    INSTALL_DBEAVER=false
    INSTALL_OHMYZSH=false
    INSTALL_MEETINGBAR=false
    INSTALL_SPOTIFY=false
    INSTALL_VLC=false
    INSTALL_SLACK=false
    INSTALL_TRADINGVIEW=false
    INSTALL_NOTION=false
    INSTALL_WHATSAPP=false
    INSTALL_DISCORD=false
    INSTALL_NODE_VERSION=false
    INSTALL_RUBY_VERSION=false
    INSTALL_JAVA_VERSION=false

    # Custom selection submenu
    if [ "$CUSTOM_SELECTION" = true ]; then
        echo ""
        echo "Select which tools to install (y/n):"
        # Essentials
        for entry in "${ESSENTIALS_LIST[@]}"; do
            IFS=":" read -r app type name flag <<< "$entry"
            prompt_and_set_flag "$name?" "$flag"
            if [ "${!flag}" = true ]; then
                if [ "$type" = "cask" ]; then
                    install_cask_app "$app" "$name"
                elif [ "$type" = "cli" ]; then
                    install_cli_tool "$app" "$name"
                fi
            fi
        done
        # Devtools
        for entry in "${DEVTOOLS_LIST[@]}"; do
            IFS=":" read -r app type name flag <<< "$entry"
            prompt_and_set_flag "$name?" "$flag"
            if [ "${!flag}" = true ]; then
                if [ "$type" = "cask" ]; then
                    install_cask_app "$app" "$name"
                elif [ "$type" = "cli" ]; then
                    install_cli_tool "$app" "$name"
                elif [ "$type" = "custom" ]; then
                    case "$app" in
                        nvm)
                            if [ -d "$HOME/.nvm" ]; then
                                echo "✅ nvm is already installed."
                            else
                                echo "⬇️  Installing nvm..."
                                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
                                {
                                    echo ''
                                    echo 'export NVM_DIR=\"$HOME/.nvm\"'
                                    echo '[ -s \"$NVM_DIR/nvm.sh\" ] && \. \"$NVM_DIR/nvm.sh\"'
                                } >> ~/.zshrc
                            fi
                            ;;
                        rbenv)
                            if command -v rbenv &>/dev/null; then
                                echo "✅ rbenv is already installed."
                            else
                                echo "⬇️  Installing rbenv..."
                                brew install rbenv
                                echo 'eval \"$(rbenv init -)\"' >> ~/.zshrc
                            fi
                            ;;
                        sdkman)
                            if [ -d \"$HOME/.sdkman\" ]; then
                                echo \"✅ SDKMAN is already installed.\"
                            else
                                echo \"⬇️  Installing SDKMAN...\"
                                curl -s \"https://get.sdkman.io\" | bash
                                echo 'source \"$HOME/.sdkman/bin/sdkman-init.sh\"' >> ~/.zshrc
                            fi
                            ;;
                        oh-my-zsh)
                            if [ -d \"$HOME/.oh-my-zsh\" ]; then
                                echo \"✅ Oh My Zsh is already installed.\"
                            else
                                echo \"⬇️  Installing Oh My Zsh...\"
                                sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended
                            fi
                            ;;
                    esac
                fi
            fi
        done

        echo ""
        echo "Select which entertainment apps to install (y/n):"
        for entry in "${ENTERTAINMENT_APPS_LIST[@]}"; do
            IFS=":" read -r app type name flag <<< "$entry"
            prompt_and_set_flag "$name?" "$flag"
            if [ "${!flag}" = true ]; then
                if [ "$type" = "cask" ]; then
                    install_cask_app "$app" "$name"
                elif [ "$type" = "cli" ]; then
                    install_cli_tool "$app" "$name"
                fi
            fi
        done

        echo ""
        echo "Select which work apps to install (y/n):"
        for entry in "${WORK_APPS_LIST[@]}"; do
            IFS=":" read -r app type name flag <<< "$entry"
            prompt_and_set_flag "$name?" "$flag"
            if [ "${!flag}" = true ]; then
                if [ "$type" = "cask" ]; then
                    install_cask_app "$app" "$name"
                elif [ "$type" = "cli" ]; then
                    install_cli_tool "$app" "$name"
                fi
            fi
        done

        echo ""
        echo "Select which social media/messaging apps to install (y/n):"
        for entry in "${SOCIAL_MEDIA_APPS_LIST[@]}"; do
            IFS=":" read -r app type name flag <<< "$entry"
            prompt_and_set_flag "$name?" "$flag"
            if [ "${!flag}" = true ]; then
                if [ "$type" = "cask" ]; then
                    install_cask_app "$app" "$name"
                elif [ "$type" = "cli" ]; then
                    install_cli_tool "$app" "$name"
                fi
            fi
        done

        echo ""
        echo "Select which language versions to install (y/n):"
        # Node.js via nvm
        if is_nvm_installed; then
            prompt_and_set_flag "Node.js v$NODE_VERSION via nvm?" INSTALL_NODE_VERSION
            if [ "$INSTALL_NODE_VERSION" = true ]; then
                install_runtime node
            fi
        else
            echo "⚠️  nvm not found, skipping Node.js version install."
        fi
        # Ruby via rbenv
        if is_rbenv_installed; then
            prompt_and_set_flag "Ruby $RUBY_VERSION_PATCH via rbenv?" INSTALL_RUBY_VERSION
            if [ "$INSTALL_RUBY_VERSION" = true ]; then
                install_runtime ruby
            fi
        else
            echo "⚠️  rbenv not found, skipping Ruby version install."
        fi
        # Java via sdkman
        if is_sdkman_installed; then
            prompt_and_set_flag "OpenJDK $JAVA_VERSION_DISPLAY ($JAVA_VENDOR_STRING) via sdkman?" INSTALL_JAVA_VERSION
            if [ "$INSTALL_JAVA_VERSION" = true ]; then
                install_runtime java
            fi
        else
            echo "⚠️  sdkman not found, skipping Java version install."
        fi
    fi

    # -- Essentials Apps Installation --
    if [ "$INSTALL_ESSENTIALS" = true ]; then
        prompt_install_all_or_individual "Essentials Apps" ESSENTIALS_LIST INSTALL_ESSENTIALS
    fi

    if [ "$INSTALL_DEVTOOLS" = true ]; then
        prompt_install_all_or_individual "Developer Tools" DEVTOOLS_LIST INSTALL_DEVTOOLS
    fi

    if [ "$INSTALL_ENTERTAINMENT" = true ]; then
        prompt_install_all_or_individual "Entertainment Apps" ENTERTAINMENT_APPS_LIST INSTALL_ENTERTAINMENT
    fi

    if [ "$INSTALL_WORK" = true ]; then
        prompt_install_all_or_individual "Work Apps" WORK_APPS_LIST INSTALL_WORK
    fi

    if [ "$INSTALL_SOCIAL_MEDIA" = true ]; then
        prompt_install_all_or_individual "Social Media and Messaging Apps" SOCIAL_MEDIA_APPS_LIST INSTALL_SOCIAL_MEDIA
    fi

    # -- Programming Runtimes Installs --
    if [ "$INSTALL_LANGVERSIONS" = true ] || [ "$INSTALL_NODE_VERSION" = true ] || [ "$INSTALL_RUBY_VERSION" = true ] || [ "$INSTALL_JAVA_VERSION" = true ]; then
        echo ""
        echo "=============================="
        echo "🔧 Programming Runtimes Setup"
        echo "=============================="
        echo ""
        echo "Starting Programming Runtimes installation..."
        echo "------------------------------"

        [ "$INSTALL_LANGVERSIONS" = true ] && INSTALL_NODE_VERSION=true && INSTALL_RUBY_VERSION=true && INSTALL_JAVA_VERSION=true
        [ "$INSTALL_NODE_VERSION" = true ] && install_runtime node
        [ "$INSTALL_RUBY_VERSION" = true ] && install_runtime ruby
        [ "$INSTALL_JAVA_VERSION" = true ] && install_runtime java
    fi

    # Final message
    echo ""
    echo "🚀 Setup complete!"
    echo "🔁 Tools like nvm, rbenv, and sdkman require reloading your shell configuration."

    # Offer to source .zshrc
    read -p "Would you like to source your ~/.zshrc now to apply changes? (y/n): " should_source
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