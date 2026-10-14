#!/bin/bash
# Dung kho kmod cho router WF810DF tu cac ban phat hanh (Releases) cua wf810df-fw.
#
# Moi ban build cua wf810df-fw co file kmods-wf810df.tar.gz = toan bo kmod cua dung
# kernel ban do. Script nay:
#   1. Duyet cac Releases tu MOI -> CU.
#   2. Moi kernel (phien ban + vermagic, vd 6.12.103~38a2...) chi lay ban build moi nhat.
#   3. Lap lai chi muc packages.adb, ky bang khoa CO DINH cua kho nay
#      (goi .apk khong mang chu ky, chi chi muc duoc ky) -> router chi can tin 1 khoa.
#   4. Cuon chieu: tong dung luong cham MAX_MB thi dung, bo cac kernel cu hon.
#
# Bien moi truong:
#   SRC_REPO  repo nguon (vd TiepPham0812/wf810df-fw)
#   OUT       thu muc trang web dau ra
#   SIGN_KEY  file khoa rieng EC (prime256v1) dung ky chi muc
#   APK       duong dan chuong trinh apk (apk-tools 3.x)
#   MAX_MB    nguong cuon chieu (MB), mac dinh 900
#   GH_TOKEN  token doc Releases (GitHub Actions co san)
set -euo pipefail
: "${SRC_REPO:?}" "${OUT:?}" "${SIGN_KEY:?}" "${APK:?}"
MAX_MB=${MAX_MB:-900}

openssl ec -in "$SIGN_KEY" -noout 2>/dev/null || { echo "LOI: SIGN_KEY khong phai khoa EC hop le"; exit 1; }
mkdir -p "$OUT/kmods"
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT

# created_at <TAB> tag <TAB> asset_id, chi lay release co kmods-wf810df.tar.gz, moi -> cu
gh api --paginate "repos/$SRC_REPO/releases?per_page=100" \
	--jq '.[] | select(.draft | not) | [.created_at, .tag_name, (.assets[] | select(.name == "kmods-wf810df.tar.gz") | .id)] | @tsv' \
	| sort -r > "$WORK/releases.tsv"
echo "Releases co kmod: $(wc -l < "$WORK/releases.tsv")"
[ -s "$WORK/releases.tsv" ] || { echo "LOI: $SRC_REPO khong co release nao kem kmods-wf810df.tar.gz"; exit 1; }

: > "$OUT/kmods.txt"
: > "$OUT/builds.tsv"
while IFS=$'\t' read -r created tag asset; do
	rm -rf "$WORK/x"; mkdir -p "$WORK/x"
	if ! gh api -H "Accept: application/octet-stream" "repos/$SRC_REPO/releases/assets/$asset" > "$WORK/k.tgz" \
		|| ! tar -xzf "$WORK/k.tgz" -C "$WORK/x"; then
		echo "BO QUA $tag: tai/giai nen kmods-wf810df.tar.gz loi"; continue
	fi
	P="$WORK/x/packages"
	KAPK=$(cd "$P" 2>/dev/null && ls kernel-*.apk 2>/dev/null | head -1 || true)
	[ -n "$KAPK" ] || { echo "BO QUA $tag: khong thay kernel-*.apk"; continue; }
	# kernel-6.12.103~38a2...-r1.apk -> 6.12.103~38a2... -> thu muc 6.12.103-38a2...
	KV=${KAPK#kernel-}; KV=${KV%.apk}; KV=${KV%-r[0-9]*}
	DIR=$(printf '%s' "$KV" | tr '~' '-')
	if [ -d "$OUT/kmods/$DIR" ]; then
		echo "TRUNG $tag: kernel $KV da lay tu ban moi hon"; continue
	fi
	rm -f "$P/packages.adb" "$P/index.json"
	(cd "$P" && "$APK" mkndx --allow-untrusted --sign "$SIGN_KEY" --output packages.adb ./*.apk >/dev/null)
	test -s "$P/packages.adb" || { echo "LOI: lap chi muc $tag that bai"; exit 1; }
	mv "$P" "$OUT/kmods/$DIR"
	SZ=$(du -sm "$OUT" | cut -f1)
	if [ "$SZ" -gt "$MAX_MB" ]; then
		rm -rf "${OUT:?}/kmods/$DIR"
		echo "CUON CHIEU: dung o $tag (tong se ${SZ} MB > ${MAX_MB} MB) - kernel cu hon chi con trong Releases cua $SRC_REPO"
		break
	fi
	printf '%s\n' "$DIR" >> "$OUT/kmods.txt"
	printf '%s\t%s\t%s\n' "$DIR" "$tag" "$created" >> "$OUT/builds.tsv"
	echo "OK   $tag -> kmods/$DIR ($(ls "$OUT/kmods/$DIR"/*.apk | wc -l) goi, tong ${SZ} MB)"
done < "$WORK/releases.tsv"

[ -s "$OUT/kmods.txt" ] || { echo "LOI: khong dung duoc kho kmod nao"; exit 1; }
openssl ec -in "$SIGN_KEY" -pubout -out "$OUT/wf810df-repo.pem" 2>/dev/null
echo "Kho co $(wc -l < "$OUT/kmods.txt") kernel, $(du -sm "$OUT" | cut -f1) MB"
