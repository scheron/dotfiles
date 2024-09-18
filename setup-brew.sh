# Upgrade brew
brew upgrade

# Add some taps
brew tap joedrago/repo
brew tap homebrew/cask-versions

# Install CLI tools
brew install node
brew install fd
brew install git
brew install lazygit
brew install pnpm
brew install fzf
brew install nvim
brew install ripgrep 

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
