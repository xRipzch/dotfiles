#!/usr/bin/env bash
# Atomic Arch / atomic-lockfile AUR campaign check
# Sources:
# - https://lists.archlinux.org/archives/list/aur-general@lists.archlinux.org/thread/FGXPCB3ZVCJIV7FX323SBAX2JHYB7ZS4/
# - https://www.sonatype.com/blog/atomic-arch-npm-campaign-adds-malicious-dependency
# - https://ioctl.fail/preliminary-analysis-of-aur-malware/
set -uo pipefail

# Malicious npm dep names this campaign rotates through, plus the payload path.
IOC_NAMES='atomic-lockfile|js-digest|lockfile-js|nextfile-js|src/hooks/deps'

# A JS pkg manager executed from an install scriptlet/hook is almost certainly bad.
# Command position only (start, or after ; & | ( ) { } `) so help-text mentions don't match.
PM_ACTION='(^|[;&|(){}`])[[:space:]]*(npm|npx|pnpm|yarn|bun|bunx)[[:space:]]'

# Exec mechanism, spelling-independent (pm_match): base64/base32 -d, xxd -r,
# curl/wget piped to a shell, eval of a string/subst, $'\xNN'/$'\NNN' escapes.
OBF_MACHINERY='(base64|base32)[[:space:]]+-{1,2}[A-Za-z]*[dD]|xxd[[:space:]]+-[A-Za-z]*r|(curl|wget)[^|]*[|][[:space:]]*(sh|bash|zsh|dash)([^[:alnum:]_]|$)|(^|[;&|(){}`])[[:space:]]*eval[[:space:]]+["$(`]|\$'"'"'\\(x[0-9a-fA-F]|[0-7])'

# Shell-startup tamper: scriptlet writing (> >> tee) into a SYSTEM /etc shell init
# file (bash.bashrc, zsh, fish, profile.d). pm_match only.
RC_TAMPER='(>>?|tee([[:space:]]+-a)?)[[:space:]]*['"'"'"]?/etc/(bash\.bashrc|bash\.bash_logout|zsh(/zshrc|/zshenv|rc|env)|fish/config\.fish|profile(\.d/[^[:space:]'"'"'"]*)?)'

_deobf() { # strip quote/backslash splices and rewrite $IFS -> space
	LC_ALL=C tr -d '\\"'"'" <"$1" 2>/dev/null |
		LC_ALL=C sed -E 's/\$\{IFS[^}]*\}/ /g; s/\$IFS/ /g'
}
_is_text() { # 0 only for a NON-EMPTY text file.
	LC_ALL=C grep -qI . "$1" 2>/dev/null
}
pm_match() { # install scriptlet / hook: ANY JS pkg mgr at install time is the red flag
	_is_text "$1" || return 1
	_deobf "$1" | grep -Eq "$PM_ACTION|$IOC_NAMES" && return 0
	grep -EqI "$OBF_MACHINERY|$RC_TAMPER" "$1" 2>/dev/null # machinery / shell-rc tamper on RAW text
}
pkgbuild_match() { # The only meaningful malicious signal in a PKGBUILD is the dep NAME.
	_is_text "$1" || return 1
	_deobf "$1" | grep -Eq "$IOC_NAMES"
}
# Print the matched line(s) tagged by rule, makes review easier of eventual false positives.
_why() {
	_deobf "$1" 2>/dev/null | grep -nE "$PM_ACTION" | head -1 | sed 's/^/      │    [pkg-mgr]  /'
	_deobf "$1" 2>/dev/null | grep -nE "$IOC_NAMES" | head -1 | sed 's/^/      │    [ioc-name] /'
	grep -nEI "$OBF_MACHINERY" "$1" 2>/dev/null | head -1 | sed 's/^/      │    [machinery]/'
	grep -nEI "$RC_TAMPER" "$1" 2>/dev/null | head -1 | sed 's/^/      │    [shell-rc] /'
}
pm_scan() { # pm_scan <matcher-fn> <name-glob> <root>...  ->  prints files the matcher flags.
	local fn=$1 glob=$2
	shift 2       # honors $PM_MAXDEPTH so a per-package scan can be
	local f md=() # limited to recipe files (not extracted src/ payload).
	[ -n "${PM_MAXDEPTH:-}" ] && md=(-maxdepth "$PM_MAXDEPTH")
	while IFS= read -r -d '' f; do
		"$fn" "$f" && printf '%s\n' "$f"
	done < <(find "$@" "${md[@]}" -type f -name "$glob" -print0 2>/dev/null)
}

nb_hits=0
ebpf_ran=0                  # set to 1 only if the (root-only) eBPF rootkit scan actually runs
CAMPAIGN_START='2026-06-09' # Sources vary but this is the earliest observed date of activity I found

# Community-maintained reported-compromised package list (Arch HedgeDoc). Edit if it moves.
# Source: https://lists.archlinux.org/archives/list/aur-general@lists.archlinux.org/message/FCH7TT6IOVT7D477JKSVJALBKADAARSW/
LIST_URL="https://md.archlinux.org/s/SxbqukK6IA/download"

echo "Atomic Arch / atomic-lockfile AUR check"
echo

# --- Setup: find the AUR helper clone caches ----
# Honor XDG dirs (helpers fall back to these when XDG_* is unset).
echo "Locating AUR helper caches..."
xch="${XDG_CACHE_HOME:-$HOME/.cache}"
xdh="${XDG_DATA_HOME:-$HOME/.local/share}"
caches=()
for d in "$xch/yay" "$xch/paru" \
	"$xdh/pikaur/aur_repos" "$xch/pikaur/aur_repos" \
	"$xch/trizen" "$xch/aurutils" "$HOME/aur"; do
	[ -d "$d" ] && caches+=("$d")
done
if [ ${#caches[@]} -eq 0 ]; then
	echo "  None found - the AUR-cache part of the scan will be skipped."
	echo "  This does NOT mean you are safe: installed packages are still checked"
	echo "  below via pacman's database and hooks."
else
	for c in "${caches[@]}"; do echo "  using: $c"; done
fi
echo

# --- Informational: any AUR install/upgrade since the campaign began? -----------------
# No AUR activity in the window is a good sign and activity in it is worth a look.
window_hits=""
log=/var/log/pacman.log
echo "Note: AUR activity since the campaign began ($CAMPAIGN_START):"
if [ -r "$log" ]; then
	events=$(awk '/\[ALPM\] (installed|upgraded)/{
      ts=$1; gsub(/[][]/,"",ts); d=substr(ts,1,10)
      for(i=1;i<=NF;i++) if($i=="installed"||$i=="upgraded") print d, $(i+1)
    }' "$log" 2>/dev/null)
	foreign=$(printf '%s\n' "$events" | grep -Fwf <(pacman -Qmq 2>/dev/null) 2>/dev/null)
	last=$(printf '%s\n' "$foreign" | awk 'NF' | sort | tail -1)
	window_hits=$(printf '%s\n' "$foreign" | awk -v s="$CAMPAIGN_START" 'NF && $1 >= s' | sort -u)
	if [ -n "$window_hits" ]; then
		echo "  Installed/upgraded AUR package(s) in the campaign window (Worth checking) :"
		printf '%s\n' "$window_hits" | sed 's/^/    /'
	elif [ -n "$last" ]; then
		echo "  Last AUR install/upgrade: $last"
		echo "  (Before $CAMPAIGN_START: Risk is lower but not zero (not a guarantee))"
	else
		echo "  no AUR install/upgrade events found in the log."
	fi
else
	echo "  (cannot read $log - Skipping...)"
fi
echo

# --- Check 1: Find the malicious dependency / its delivery mechanism ----------
echo "[1/2] Looking for the malicious dependency or its delivery..."
hits=""

label="  - Local scan (scriptlets, hooks, AUR caches)..."
printf '%s ' "$label"
phase=$(
	pm_scan pm_match 'install' /var/lib/pacman/local
	pm_scan pm_match '*.hook' /usr/share/libalpm/hooks /etc/pacman.d/hooks
)
[ -n "$phase" ] && hits+="$phase"$'\n'
if [ ${#caches[@]} -gt 0 ]; then
	repos=()
	for cache in "${caches[@]}"; do
		for d in "$cache"/*/; do [ -d "$d" ] && repos+=("$d"); done
	done
	total=${#repos[@]}
	i=0
	for d in "${repos[@]}"; do
		i=$((i + 1))
		[ -t 1 ] && printf '\r%s %d/%d ' "$label" "$i" "$total"
		phase=$(
			find "$d" -maxdepth 1 -type f -print0 2>/dev/null | xargs -r -0 grep -lEI "$IOC_NAMES" 2>/dev/null
			PM_MAXDEPTH=1 pm_scan pm_match '*.install' "$d"
			PM_MAXDEPTH=1 pm_scan pm_match '*.hook' "$d"
			PM_MAXDEPTH=1 pm_scan pkgbuild_match 'PKGBUILD' "$d"
		)
		[ -n "$phase" ] && hits+="$phase"$'\n'
	done
	[ -t 1 ] && printf '\r%s ' "$label"
fi
hits=$(printf '%s\n' "$hits" | sed '/^$/d' | sort -u)
if [ -n "$hits" ]; then
	echo # break off the inline progress label
	echo "    FOUND (COMPROMISED):"
	while IFS= read -r hf; do
		[ -n "$hf" ] || continue
		echo "      ├─ $hf"
		_why "$hf" # show the matched line(s) so False Positives are obvious
	done <<<"$hits"
	echo "      │"
	echo "      └─ [!] Malicious install-time code; see remediation below."
	echo
	nb_hits=$((nb_hits + 1))
else
	echo "NOT FOUND"
fi

# Probably not exhaustive but nice to have, sourced from the AUR mailing list
printf "  - Check against known impacted AUR packages list... (Uses curl|wget, but can be skipped)"
fetch=""
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
	echo "SKIPPED (no curl/wget)"
elif [ -t 0 ]; then
	echo
	printf '    Download from %s ? [y/N]: ' "$LIST_URL"
	read -r ans
	case "$ans" in
	[yY]*)
		if command -v curl >/dev/null 2>&1; then
			fetch=$(curl -fsSL --max-time 20 "$LIST_URL" 2>/dev/null)
		else
			fetch=$(wget -qO- --timeout=20 "$LIST_URL" 2>/dev/null)
		fi
		;;
	*) echo "    SKIPPED" ;;
	esac
else
	echo "SKIPPED (non-interactive; would download $LIST_URL)"
fi
if [ -n "$fetch" ]; then
	reported=$(printf '%s' "$fetch" | tr -s ' \t\r\n' '\n' |
		grep -E '^[a-zA-Z0-9][a-zA-Z0-9@._+-]+$' | sort -u)
	match=$(comm -12 <(pacman -Qmq 2>/dev/null | sort -u) <(printf '%s\n' "$reported"))
	if [ -n "$match" ]; then
		# Name match only proves the package was reported, not that THIS build is poisoned.
		# The build date decides: built before the campaign = predates poisoning = likely safe.
		echo "    ON REPORTED LIST:"
		cs=$(date -d "$CAMPAIGN_START" +%s 2>/dev/null)
		inwin=0
		while IFS= read -r p; do
			[ -n "$p" ] || continue
			v=$(pacman -Q "$p" 2>/dev/null | awk '{print $2}')
			desc="/var/lib/pacman/local/$p-$v/desc"
			bd=$(awk '/^%BUILDDATE%/{getline;print;exit}' "$desc" 2>/dev/null)
			idt=$(awk '/^%INSTALLDATE%/{getline;print;exit}' "$desc" 2>/dev/null)
			if [ -n "$bd" ] && [ -n "$cs" ] && [ "$bd" -lt "$cs" ]; then
				verdict="[OK] built before $CAMPAIGN_START"
			else
				verdict="[!] built in/after campaign window, TO INSPECT"
				inwin=1
			fi
			echo "      ├─ $p $v"
			echo "      │    built     $([ -n "$bd" ] && date -d "@$bd" '+%F %H:%M' || echo '?')  ($verdict)"
			echo "      │    installed $([ -n "$idt" ] && date -d "@$idt" '+%F %H:%M' || echo '?')"
			if [ "${#caches[@]}" -gt 0 ]; then
				for c in "${caches[@]}"; do [ -d "$c/$p" ] && echo "      │    recipe    $c/$p"; done
			fi
			pf=$(ls -1 /var/cache/pacman/pkg/"$p"-"$v"-*.pkg.tar.* 2>/dev/null | grep -v '\.sig$' | head -1)
			[ -n "$pf" ] && echo "      │    pkgfile   $pf"
		done <<<"$match"
		if [ "$inwin" -eq 1 ]; then
			echo "      │"
			echo "      └─ [!] Built in the campaign window: inspect the recipe/pkgfile above before trusting."
			nb_hits=$((nb_hits + 1))
		else
			echo "      │"
			echo "      └─ [OK] All built before the campaign: likely safe."
		fi
	else
		echo "    $(printf '%s\n' "$reported" | grep -c .) names checked, no matches with installed packages."
	fi
fi
echo

# --- Check 2: Look for leftovers if the payload actually ran (ioctl.fail, unverified) ---
echo "[2/2] Checking for payload leftovers..."

# systemd persistence fingerprint (Restart=always + RestartSec=30).
printf "  - Scan for systemd persistence fingerprint... "
review=""
for unit in /etc/systemd/system/*.service ~/.config/systemd/user/*.service; do
	[ -f "$unit" ] || continue
	if grep -q '^Restart=always' "$unit" 2>/dev/null &&
		grep -q '^RestartSec=30' "$unit" 2>/dev/null; then
		review+="      ├─ $unit  ->  $(grep -m1 '^ExecStart=' "$unit" 2>/dev/null)"$'\n'
	fi
done
if [ -n "$review" ]; then
	echo
	echo "    TO REVIEW:"
	printf '%s' "$review"
	echo "      │"
	echo "      └─ [!] Confirm each ExecStart is something you installed."
	echo
else
	echo "NOT FOUND"
fi

# Staging target: the payload fetches a cryptominer and references this path.
# A file here that NO package owns is a red flag; an owned one can be verified.
mwg=/usr/bin/monero-wallet-gui
printf "  - Check %s (cryptominer staging target)... " "$mwg"
if [ -e "$mwg" ]; then
	if pacman -Qo "$mwg" >/dev/null 2>&1; then
		echo "present, package-owned (expected if you use monero-gui; check integrity with pacman -Qkk monero-gui)"
	else
		echo
		echo "    FOUND:"
		echo "      ├─ $mwg  ->  owned by no package"
		echo "      │"
		echo "      └─ [!] Cryptominer staging target; verify it is not a dropped payload."
		echo
		nb_hits=$((nb_hits + 1))
	fi
else
	echo "NOT PRESENT"
fi

# eBPF rootkit maps, bpffs is root-only, so this can't run unprivileged.
# Kept last because it is the only interactive (sudo prompt) step.
printf "  - Scan for eBPF rootkit maps (hidden_pids/hidden_names/hidden_inodes)... "
if [ -t 0 ]; then
	echo "(needs root)"
	echo
	# If the host is compromised the rootkit hooks getdents64(), so 'ls /sys/fs/bpf'
	# hides the maps. bpftool is preferred: it enumerates maps by ID through the bpf()
	# syscall, so it sees them whether or not they're pinned to bpffs.
	# The stat() fallback is best-effort only: it finds a map ONLY if the rootkit
	# pinned it at one of the known IOC names, and a rootkit hiding pins from getdents64
	# can hide them from stat() too.
	ebpf_scan() {
		if ! mountpoint -q /sys/fs/bpf 2>/dev/null; then
			echo "    bpffs not mounted at /sys/fs/bpf - nothing to check" >&2
			return 0
		fi
		if command -v bpftool >/dev/null 2>&1; then
			echo >&2
			echo "    Method: bpftool map list (asks the kernel directly)" >&2
			local all
			all=$(bpftool map list 2>/dev/null)
			# Known-IOC names => hard hit on stdout (counts toward findings).
			printf '%s\n' "$all" | grep -Eo 'hidden_(pids|names|inodes)' | sort -u
			# Triage the rest: collapse each map to one line (id/type/name/owner) and
			# hide maps owned by known BPF users (systemd, NetworkManager) plus bpftool's
			# own iteration maps (pid_iter / libbpf_*) - those are the usual false positives,
			# since running 'bpftool' itself creates them. Only the remainder needs eyes.
			local triage counts total hidden toreview review
			triage=$(printf '%s\n' "$all" | awk '
        function flush(){
          if (id=="") return
          good=0
          if (name ~ /^(pid_iter|libbpf_|bpftool)/) good=1
          if (owner ~ /(^|[ (])(bpftool|systemd|systemd-[a-z]+|NetworkManager|dbus-daemon|dbus-broker|polkitd|firewalld)\(/) good=1
          total++
          if (good) hidden++
          else printf "      | %-4s %-14s %-20s %s\n", id, type, (name==""?"(unnamed)":name), (owner==""?"(no owning pid)":owner)
          id=""; type=""; name=""; owner=""
        }
        /^[0-9]+:/  { flush(); id=$1; sub(/:/,"",id); type=$2; for(i=3;i<=NF;i++) if($i=="name") name=$(i+1) }
        /^[[:space:]]*pids[[:space:]]/ { o=$0; sub(/^[[:space:]]*pids[[:space:]]+/,"",o); owner=o }
        END { flush(); printf "COUNTS %d %d\n", total, hidden }
      ')
			counts=$(printf '%s\n' "$triage" | sed -n 's/^COUNTS //p')
			review=$(printf '%s\n' "$triage" | grep -v '^COUNTS ')
			total=${counts%% *}
			hidden=${counts##* }
			toreview=$((total - hidden))
			echo "    $total map(s): $hidden known-good (systemd/NetworkManager/bpftool), $toreview to review." >&2
			if [ "$toreview" -gt 0 ]; then
				echo "      | ID   TYPE           NAME                 OWNER" >&2
				printf '%s\n' "$review" >&2
				echo "      (not necessarily malicious - verify each OWNER is a service you expect)" >&2
			else
				echo "      (all maps belong to known system services; nothing unexpected)" >&2
			fi
			# Report the review count back to the caller
			echo "__TOREVIEW__=$toreview"
		else
			echo "    Method: stat() on known paths (bpftool absent; best-effort, only the 3 known pin names)" >&2
			echo "    Tip: 'sudo pacman -S bpf' and run this script again for a reliable, pin-independent scan" >&2
			for f in /sys/fs/bpf/hidden_pids /sys/fs/bpf/hidden_names /sys/fs/bpf/hidden_inodes; do
				[ -e "$f" ] && echo "$f"
			done
		fi
	}
	echo "    Will use 'bpftool' if available, else direct stat(), to dodge a compromised getdents64()."
	echo
	echo "    To run it yourself instead:"
	command -v bpftool >/dev/null 2>&1 ||
		echo "      sudo pacman -S --needed bpf                                    # Provides bpftool"
	echo "      sudo bpftool map list                                          # Review suspicious maps"
	echo "      sudo bpftool map list | grep -E 'hidden_(pids|names|inodes)'   # Known IOC names"
	echo
	while :; do
		printf "    Run it now? (you'll be prompted for your password)\n    [y]es / [s]how exact command / [N]o skip: "
		read -r ans
		case "$ans" in
		[sS]*)
			echo
			declare -f ebpf_scan | sed 's/^/      | /'
			echo
			continue
			;;
		[yY]*)
			ebpf_ran=1
			echo
			out=$(sudo bash -c "$(declare -f ebpf_scan); ebpf_scan")
			# Split off the review-count marker; what remains is the IOC-name hit list.
			toreview=$(printf '%s\n' "$out" | sed -n 's/^__TOREVIEW__=//p')
			maps=$(printf '%s\n' "$out" | grep -v '^__TOREVIEW__=')
			echo
			if [ -n "$maps" ]; then
				echo "    FOUND:"
				printf '%s\n' "$maps" | sed 's/^/      ├─ /'
				echo "      │"
				echo "      └─ [!] eBPF rootkit maps present; treat the host as fully compromised."
				nb_hits=$((nb_hits + 1))
			elif [ "${toreview:-0}" -gt 0 ]; then
				echo "    No known-IOC map names matched (see the triage above for the $toreview map(s) to review)."
			else
				echo "    No known-IOC map names matched; all maps belong to known system services."
			fi
			break
			;;
		*)
			echo "    SKIPPED"
			break
			;;
		esac
	done
else
	echo "SKIPPED (needs root)"
fi
echo

rule=$(printf '=%.0s' {1..77})
lightrule=${rule//=/-}
echo "$rule"
if [ "$nb_hits" -eq 0 ]; then
	echo "LIKELY CLEAN: no Atomic Arch payload found."
	echo "$lightrule"
	[ "$ebpf_ran" -eq 0 ] && echo "  - eBPF rootkit check did NOT run."
	[ -n "$review" ] && echo "  - Confirm the 'TO REVIEW' unit(s) above are yours."
	[ -n "$window_hits" ] && echo "  - You updated AUR package(s) in the campaign window."
else
	echo "/!\\ IMPACTED /!\\: $nb_hits finding(s) above. See the FOUND lines."
	echo "$lightrule"
	echo "This payload is a credential stealer. If it ran, act now:"
	echo
	echo "  1. Consider any credentials accessible by your current user as compromised."
	echo "  2. From ANOTHER, clean machine, rotate every secret readable by you:"
	echo "     SSH/GPG keys, cloud/CI/API tokens, npm/Docker/Vault creds, browser,"
	echo "     app sessions, any password in shell history."
	echo "  3. If a rootkit map or systemd unit was found, treat the host as fully"
	echo "     compromised: back up DATA only, reinstall from trusted media (live USB),"
	echo "     and bring only the clean, reinstalled system back online."
	echo "  4. Going forward: review PKGBUILD/.install diffs before building, and"
	echo "     prefer 'npm install --ignore-scripts' for any manual npm/bun use."
fi
echo "$rule"
