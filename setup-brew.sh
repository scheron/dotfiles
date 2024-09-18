# Upgrade brew
brew upgrade

# Add some taps
brew tap joedrago/repo
brew tap homebrew/cask-versions

# Install CLI tools
brew install fd
brew install node
brew install git
brew install lazygit
brew install pnpm
brew install fzf
brew install nvim

# Install Yazi & other tools
brew install yazi
brew install ffmpegthumbnailer  # for video thumbnails
brew install sevenzip # for 7z
brew install jq # for json
brew install poppler # for pdf
brew install fd # for file search
brew install ripgrep # for file content search
brew install fzf # for filetree navigation
brew install zoxide # for historical navigation
brew install imagemagick # for image preview

# Install casks
brew install --cask 1password
brew install --cask wezterm
brew install --cask cleanmymac
brew install --cask firefox
brew install --cask brave-browser
brew install --cask insomnia
brew install --cask logi-options+
brew install --cask raycast
brew install --cask telegram
brew install --cask visual-studio-code

# Install fonts
brew install --cask font-symbols-only-nerd-font
brew install --cask font-zed-mono-nerd-font
brew install --cask font-jetbrains-mono
brew install --cask font-fira-code-nerd-font
brew install --cask font-iosevka
brew install --cask font-victor-mono
brew install --cask font-commit-mono-nerd-font
brew install --cask font-hack-nerd-font


# Remove outdated versions from the cellar.
brew cleanup
