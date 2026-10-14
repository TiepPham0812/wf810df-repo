#!/bin/sh
# Ket noi router WF810DF (firmware wf810df-fw) voi kho kmod wf810df-repo.
# Chay tren router qua SSH:
#   wget -qO- __BASE__/setup.sh | sh
# Chay lai sau moi lan nang cap firmware (kernel moi -> thu muc kmod moi).
# R=<thu muc> chi dung de thu nghiem tren may khac, router that de trong.
set -e
BASE="__BASE__"
R="${R:-}"
KEY="$R/etc/apk/keys/wf810df-repo.pem"
LIST="$R/etc/apk/repositories.d/customfeeds.list"
DB="$R/lib/apk/db/installed"

# Phien ban kernel dang chay, dang 6.12.103~38a2e620...-r1 -> 6.12.103-38a2e620...
KV=$(awk '/^P:kernel$/{f=1} f&&/^V:/{v=substr($0,3); sub(/-r[0-9]+$/,"",v); print v; exit}' "$DB" 2>/dev/null)
[ -n "$KV" ] || { echo "LOI: khong doc duoc phien ban kernel tu $DB"; exit 1; }
DIR=$(echo "$KV" | tr '~' '-')
echo "Kernel dang chay: $KV"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
wget -q -O "$TMP/kmods.txt" "$BASE/kmods.txt" || { echo "LOI: khong tai duoc $BASE/kmods.txt (kiem tra mang)"; exit 1; }
if ! grep -qx "$DIR" "$TMP/kmods.txt"; then
	echo "LOI: kho chua co kmod cho kernel nay. Kernel dang co trong kho:"
	sed 's/^/  /' "$TMP/kmods.txt"
	echo "Nguyen nhan: firmware khong build tu wf810df-fw, hoac ban build qua cu da bi cuon khoi kho."
	exit 1
fi
wget -q -O "$TMP/key.pem" "$BASE/wf810df-repo.pem" && grep -q "BEGIN PUBLIC KEY" "$TMP/key.pem" \
	|| { echo "LOI: khong tai duoc khoa cong khai cua kho"; exit 1; }

mkdir -p "$(dirname "$KEY")" "$(dirname "$LIST")"
cp "$TMP/key.pem" "$KEY"
touch "$LIST"
# Bo dong kho kmod cu (wf810df-fw tu ky theo tung ban build, wf810df-repo cu), giu dong khac
sed -i '/github\.io\/wf810df-fw\//d; /github\.io\/wf810df-repo\//d; /^# Kho kmod/d' "$LIST"
printf '# Kho kmod wf810df-repo cho kernel %s\n%s\n' "$KV" "$BASE/kmods/$DIR/packages.adb" >> "$LIST"
# Giu khoa qua nang cap firmware co giu cau hinh
touch "$R/etc/sysupgrade.conf"
grep -qx "/etc/apk/keys/wf810df-repo.pem" "$R/etc/sysupgrade.conf" || echo "/etc/apk/keys/wf810df-repo.pem" >> "$R/etc/sysupgrade.conf"

echo "Da them kho: $BASE/kmods/$DIR/packages.adb"
if [ -z "$R" ]; then
	apk update
	echo "Xong. Cai kmod: apk add kmod-<ten>   (hoac LuCI -> He thong -> Phan mem)"
fi
