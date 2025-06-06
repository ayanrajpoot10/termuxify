#!/usr/bin/env bash

set -e

[[ $# -eq 1 ]] || { echo "Usage: $0 <version>"; exit 1; }

VERSION="$1"
PKGNAME="termuxify"
DEB_DIR="debian/$PKGNAME"
USR_DIR="$DEB_DIR/data/data/com.termux/files/usr"

rm -rf "$DEB_DIR" "${PKGNAME}_${VERSION}.deb"

mkdir -p "$DEB_DIR/DEBIAN" "$USR_DIR/bin" "$USR_DIR/share/$PKGNAME"/{colors,fonts}

cp debian/control "$DEB_DIR/DEBIAN/"
cp debian/{postinst,prerm,postrm} "$DEB_DIR/DEBIAN/"
chmod 755 "$DEB_DIR/DEBIAN"/{postinst,prerm,postrm}

install -m755 termuxify.sh "$USR_DIR/bin/"
cp -r colors/* "$USR_DIR/share/$PKGNAME/colors/"
cp -r fonts/* "$USR_DIR/share/$PKGNAME/fonts/"

INSTALLED_SIZE=$(du -sk "$DEB_DIR/data" | cut -f1)
sed -i "/^Version:/a Installed-Size: $INSTALLED_SIZE" "$DEB_DIR/DEBIAN/control"

dpkg-deb -Zxz --build "$DEB_DIR" "${PKGNAME}_${VERSION}.deb"

echo "Built: ${PKGNAME}_${VERSION}.deb"
