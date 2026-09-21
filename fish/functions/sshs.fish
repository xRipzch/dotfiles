# Læs kun min egen ssh-config. Standarden tager også /etc/ssh/ssh_config med,
# som via Include trækker systemds og libvirts drop-ins ind — de dukker op som
# .host, machine/.host og qemu/*, der ikke er rigtige værter.
function sshs --wraps sshs --description 'sshs uden systemets drop-in-værter'
    command sshs --config $HOME/.ssh/config $argv
end
