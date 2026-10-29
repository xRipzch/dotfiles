# Input:  {ws: hyprctl -j workspaces, mon: hyprctl -j monitors}
# Output: array of {id, label, state, cmd} for the bar.
# Kanji numerals are the same ones the old waybar used.
["一","二","三","四","五","六","七","八","九","十"] as $kanji
| 5 as $persistent
| ([.mon[] | select(.focused) | .activeWorkspace.id] | first // 1) as $active
| ([.ws[] | select(.windows > 0) | .id]) as $occupied
| ([.mon[] | .specialWorkspace.name] | map(select(. != "")) | first // "") as $special
| ([range(1; $persistent + 1)] + [$occupied[] | select(. > $persistent)] + [$active]
   | unique | map(select(. > 0))) as $ids
| [ $ids[]
    | . as $id
    | { id: $id,
        label: ($kanji[$id - 1] // ($id | tostring)),
        state: (if $id == $active then "focused"
                elif ($occupied | index($id)) != null then "occupied"
                else "empty" end),
        cmd: "hyprctl dispatch 'hl.dsp.focus({ workspace = \($id) })'" } ]
  + (if $special != "" then
       [{ id: -99, label: "特別", state: "special",
          cmd: "hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"\")'" }]
     else [] end)
