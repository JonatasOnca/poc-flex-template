git config --global user.name "Nome"

git config --global user.email "email@email.com"

ssh-keygen -t ed25519 -C "email@email.com"

eval "$(ssh-agent -s)"

touch ~/.ssh/config

open ~/.ssh/config

pbcopy < ~/.ssh/id_ed25519.pub

ssh -T git@github.com  