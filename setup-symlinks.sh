# Create directory if it doesn't exist
[ -d ~/.config ] || mkdir ~/.config

ln -s ~/.dotfiles/nvim ~/.config/
ln -s ~/.dotfiles/skhd ~/.config/
ln -s ~/.dotfiles/yabai ~/.config/
ln -s ~/.dotfiles/wezterm ~/.config/
ln -s ~/.dotfiles/lazygit ~/.config/
ln -s ~/.dotfiles/yazi ~/.config/
ln -s ~/.dotfiles/VSCode ~/.config/

ln -s ~/.dotfiles/.gitconfig ~/.gitconfig

