## Dotfiles

Symlinks
ln -s ~/dotfiles/.vimrc ~/.vimrc  
ln -s ~/dotfiles/.bashrc ~/.bashrc  
ln -s ~/dotfiles/.tmux.conf ~/.tmux.conf  
ln -s ~/dotfiles/.vim/colors/jellybeans.vim jellybeans.vim

Install Pathogen
mkdir -p ~/.vim/autoload ~/.vim/bundle && \
curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

Install Tmux on Centos 6.5
https://gist.github.com/ekiara/11023782
