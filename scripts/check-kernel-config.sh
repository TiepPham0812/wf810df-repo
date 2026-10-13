#!/bin/sh
# Kiem tra moi dong trong file tuy chinh kernel da vao dung .config cuoi cung.
# Cach dung: sh scripts/check-kernel-config.sh <file-tuy-chinh> <.config-kernel-da-build>
FRAG="$1"; FINAL="$2"
[ -f "$FRAG" ] || { echo "LOI: khong thay $FRAG"; exit 1; }
[ -f "$FINAL" ] || { echo "LOI: khong thay $FINAL"; exit 1; }
fail=0; n=0
while IFS= read -r line; do
	case "$line" in
	CONFIG_*=*)
		sym=${line%%=*}
		want=$line
		;;
	"# CONFIG_"*" is not set")
		sym=${line#\# }; sym=${sym%% *}
		want=""
		;;
	*) continue ;;
	esac
	n=$((n+1))
	got=$(grep -E "^($sym=|# $sym is not set)" "$FINAL" | head -1)
	# "khong co trong .config" tuong duong "is not set"
	if [ -z "$want" ]; then
		case "$got" in ""|"# $sym is not set") echo "OK   $sym tat"; continue ;; esac
	elif [ "$got" = "$want" ]; then
		echo "OK   $want"; continue
	fi
	echo "LECH $sym: muon '${want:-tat}', kernel nhan '${got:-khong co}'"
	fail=1
done < "$FRAG"
echo "Da kiem tra $n dong tuy chinh."
exit $fail
