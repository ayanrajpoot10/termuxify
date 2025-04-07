#!/data/data/com.termux/files/usr/bin/bash
set -e

VERSION="0.1.5"
PKGNAME="termuxify"
DEB_DIR="debian/${PKGNAME}"
USR_DIR="${DEB_DIR}/data/data/com.termux/files/usr"
BIN_DIR="${USR_DIR}/bin"
SHARE_DIR="${USR_DIR}/share/${PKGNAME}"

rm -rf "$DEB_DIR" "${PKGNAME}_${VERSION}.deb"

mkdir -p "$DEB_DIR/DEBIAN" "$BIN_DIR" "$SHARE_DIR/colors" "$SHARE_DIR/fonts"

for script in control postinst prerm postrm; do
    [[ -f "debian/$script" ]] || { echo "Error: debian/$script not found"; exit 1; }
    sed -i 's/\r$//' "debian/$script"
    install -m $([ "$script" = "control" ] && echo "644" || echo "755") "debian/$script" "$DEB_DIR/DEBIAN/$script"
done

install -m755 termuxify.sh "$BIN_DIR/termuxify.sh"
cp -a colors/. "$SHARE_DIR/colors/"
cp -a fonts/. "$SHARE_DIR/fonts/"

chmod 755 "$DEB_DIR"/DEBIAN/post* "$DEB_DIR"/DEBIAN/pre* 2>/dev/null || true

chmod 755 "$DEB_DIR/DEBIAN"

dpkg-deb -Zxz --build "$DEB_DIR" "${PKGNAME}_${VERSION}.deb"

echo "Package built: ${PKGNAME}_${VERSION}.deb"
