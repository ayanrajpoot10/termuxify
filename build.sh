#!/bin/bash

VERSION="0.1.0"
PKGNAME="termuxify"

rm -rf "debian/${PKGNAME}"
rm -f "${PKGNAME}_${VERSION}.deb"

mkdir -p "debian/${PKGNAME}/DEBIAN"
mkdir -p "debian/${PKGNAME}/data/data/com.termux/files/usr/bin"
mkdir -p "debian/${PKGNAME}/data/data/com.termux/files/usr/share/termuxify/colors"
mkdir -p "debian/${PKGNAME}/data/data/com.termux/files/usr/share/termuxify/fonts"

for file in control postinst prerm postrm; do
    if [ ! -f "debian/$file" ]; then
        echo "Error: debian/$file not found"
        exit 1
    fi
    sed -i 's/\r$//' "debian/$file"
    cp "debian/$file" "debian/${PKGNAME}/DEBIAN/"
done

chmod 755 "debian/${PKGNAME}/DEBIAN/postinst"
chmod 755 "debian/${PKGNAME}/DEBIAN/prerm"
chmod 755 "debian/${PKGNAME}/DEBIAN/postrm"
chmod 644 "debian/${PKGNAME}/DEBIAN/control"

cp termuxify.sh "debian/${PKGNAME}/data/data/com.termux/files/usr/bin/"
chmod 755 "debian/${PKGNAME}/data/data/com.termux/files/usr/bin/termuxify.sh"

cp -r colors/* "debian/${PKGNAME}/data/data/com.termux/files/usr/share/termuxify/colors/"
cp -r fonts/* "debian/${PKGNAME}/data/data/com.termux/files/usr/share/termuxify/fonts/"

chmod -R 644 "debian/${PKGNAME}/data/data/com.termux/files/usr/share/termuxify/colors/"*
chmod -R 644 "debian/${PKGNAME}/data/data/com.termux/files/usr/share/termuxify/fonts/"*

find "debian/${PKGNAME}" -type d -exec chmod 755 {} \;
find "debian/${PKGNAME}" -type f -exec chmod 644 {} \;
find "debian/${PKGNAME}/DEBIAN" -type f -name "post*" -exec chmod 755 {} \;
find "debian/${PKGNAME}/DEBIAN" -type f -name "pre*" -exec chmod 755 {} \;

INSTALLED_SIZE=$(du -sk "debian/${PKGNAME}" | cut -f1)

sed -i "/^Section:/a\Installed-Size: ${INSTALLED_SIZE}" "debian/${PKGNAME}/DEBIAN/control"

dpkg-deb --build "debian/${PKGNAME}" "${PKGNAME}_${VERSION}.deb"

echo "Package built successfully: ${PKGNAME}_${VERSION}.deb"
echo "Installed Size: ${INSTALLED_SIZE} KB"
