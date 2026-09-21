function hdmi
    set internal (hyprctl monitors | grep "^Monitor eDP" | awk '{print $2}')
    set external (hyprctl monitors | grep "^Monitor" | grep -v "eDP" | awk '{print $2}')

    if test -z "$external"
        echo "No external display detected"
        return 1
    end

    switch $argv[1]
        case mirror --mirror
            hyprctl keyword monitor $external,preferred,0x0,1,mirror,$internal
            echo "Mirroring $internal → $external"
        case extend --extend
            set width (hyprctl monitors | grep -A2 "^Monitor $internal" | grep "@" | awk '{print $1}' | cut -dx -f1)
            set pos (string join "" $width x0)
            hyprctl keyword monitor $external,preferred,$pos,1
            echo "Extending to $external at offset $width"
        case off --off
            hyprctl keyword monitor $external,disable
            echo "Turned off $external"
        case '*'
            echo "Usage: hdmi [mirror|extend|off]"
            return 1
    end
end
