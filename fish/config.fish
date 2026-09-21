if status is-interactive
    set -g fish_greeting
    starship init fish | source
    zoxide init fish | source
    fzf_key_bindings
end

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
set --export --prepend PATH "/home/ravn/.rd/bin"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
