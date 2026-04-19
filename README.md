a fast, minimalist cli-tool to manage and synchronize multiple git repositories at once.

## installation

1. clone the repository to your home folder:
```bash
git clone [https://github.com/aGuyCalledT/git-all.git](https://github.com/aGuyCalledT/git-all.git) ~/.git-all
```
2. create a symbolic link to make it act like a native system command.
```bash
mkdir -p ~/.local/bin

ln -sf PATH/git-all.sh ~/.local/bin/git-all

source ~/.zshrc
```

initialize with ```git-all init``` and edit blacklisted repositories with ```git-all blacklist```.
