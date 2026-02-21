if status is-interactive
    starship init fish | source

    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end
end

function konek
	if test (count $argv) -eq 0
		echo "Usage: connect <nama wifi>"
		return 1
	end
	nmcli connection up "$argv" --ask
end

set -gx PNPM_HOME "$HOME/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end

set -gx PATH $HOME/.local/bin $PATH

set -gx ADW_DISABLE_PORTAL 1
