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
brew install yazi
brew install fzf
brew install nvim

# Install casks
brew install 1password
brew install --cask wezterm
brew install --cask cleanmymac
brew install --cask docker
brew install figma
brew install firefox
brew install firefox@developer-edition
brew install forklift
brew install google-chrome
brew install google@chrome-canary
brew install insomnia
brew install logi-options+
brew install raycast
brew install safari-technology-preview
brew install --cask telegram
brew install visual-studio-code

# Install fonts
brew install --cask font-zed-mono-nerd-font
brew install --cask font-jetbrains-mono
brew install --cask font-fira-code-nerd-font
brew install --cask font-iosevka
brew install --cask font-victor-mono
brew install --cask font-commit-mono-nerd-font
brew install --cask font-hack-nerd-font


# Install tap formulas
brew install joedrago/repo/avifenc

# Remove outdated versions from the cellar.
brew cleanup
