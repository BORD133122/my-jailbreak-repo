#!/bin/bash
# Generate Sileo-compatible APT repository
set -e

REPO_DIR="$HOME/my-project/repo"

# Step 1: Generate Packages file
cd "$REPO_DIR"
apt-ftparchive packages debs/ > Packages 2>/dev/null || {
    # Fallback: generate Packages manually from .deb files
    echo "Generating Packages manually..."
    > Packages
    for deb in debs/*.deb; do
        [ -f "$deb" ] || continue
        echo "Processing: $(basename $deb)"
        {
            ar -p "$deb" control.tar.gz | tar -xzO ./control 2>/dev/null
            echo "Filename: debs/$(basename $deb)"
            echo "Size: $(stat -c%s "$deb")"
            echo "MD5sum: $(md5sum "$deb" | cut -d' ' -f1)"
            echo "SHA256: $(sha256sum "$deb" | cut -d' ' -f1)"
            echo ""
        } >> Packages
    done
}

# Step 2: Compress Packages in multiple formats
gzip -9kf Packages 2>/dev/null || gzip -f Packages
bzip2 -9kf Packages 2>/dev/null || bzip2 -f Packages
xz -9kf Packages 2>/dev/null || xz -f Packages
zstd -19 -f Packages -o Packages.zst 2>/dev/null || echo "zstd not available, skipping"

# Step 3: Generate Release file
SIZE_PACKAGES=$(stat -c%s Packages 2>/dev/null || echo 0)
SIZE_GZ=$(stat -c%s Packages.gz 2>/dev/null || echo 0)
SIZE_BZ2=$(stat -c%s Packages.bz2 2>/dev/null || echo 0)
SIZE_XZ=$(stat -c%s Packages.xz 2>/dev/null || echo 0)
SIZE_ZST=$(stat -c%s Packages.zst 2>/dev/null || echo 0)

MD5_PACKAGES=$(md5sum Packages | cut -d' ' -f1)
MD5_GZ=$(md5sum Packages.gz | cut -d' ' -f1)
MD5_BZ2=$(md5sum Packages.bz2 | cut -d' ' -f1)
MD5_XZ=$(md5sum Packages.xz | cut -d' ' -f1)
MD5_ZST=$(md5sum Packages.zst 2>/dev/null | cut -d' ' -f1 || echo "")

SHA256_PACKAGES=$(sha256sum Packages | cut -d' ' -f1)
SHA256_GZ=$(sha256sum Packages.gz | cut -d' ' -f1)
SHA256_BZ2=$(sha256sum Packages.bz2 | cut -d' ' -f1)
SHA256_XZ=$(sha256sum Packages.xz | cut -d' ' -f1)
SHA256_ZST=$(sha256sum Packages.zst 2>/dev/null | cut -d' ' -f1 || echo "")

DATE=$(date -Ru)

cat > Release << EOF
Origin: Pulse Repo
Label: Pulse Repository
Suite: stable
Version: 1.0
Codename: pulse-repo
Architectures: iphoneos-arm iphoneos-arm64
Components: main
Description: My personal jailbreak tweak repository
Date: $DATE
Default-Release: stable

MD5Sum:
 $MD5_PACKAGES $SIZE_PACKAGES Packages
 $MD5_GZ $SIZE_GZ Packages.gz
 $MD5_BZ2 $SIZE_BZ2 Packages.bz2
 $MD5_XZ $SIZE_XZ Packages.xz
 $( [ -n "$SIZE_ZST" ] && [ "$SIZE_ZST" -gt 0 ] && echo "$MD5_ZST $SIZE_ZST Packages.zst" )

SHA256:
 $SHA256_PACKAGES $SIZE_PACKAGES Packages
 $SHA256_GZ $SIZE_GZ Packages.gz
 $SHA256_BZ2 $SIZE_BZ2 Packages.bz2
 $SHA256_XZ $SIZE_XZ Packages.xz
 $( [ -n "$SIZE_ZST" ] && [ "$SIZE_ZST" -gt 0 ] && echo "$SHA256_ZST $SIZE_ZST Packages.zst" )
EOF

# Step 4: Generate simple icon
if ! [ -f CydiaIcon.png ]; then
    python3 -c "
from PIL import Image
img = Image.new('RGBA', (256, 256), (20, 20, 40, 255))
# Draw a simple pulse shape
pixels = img.load()
for x in range(256):
    for y in range(256):
        dx = x - 128
        dy = y - 128
        d = (dx*dx + dy*dy) ** 0.5
        if d < 80:
            brightness = max(0, int(255 * (1 - d/80)))
            offset = int(d * 0.3)
            r = min(255, 60 + offset)
            b = min(255, 200 - offset)
            pixels[x, y] = (r, int(brightness * 0.5), b, brightness)
        elif d < 100:
            pixels[x, y] = (100, 50, 150, max(0, int(100 * (1 - (d-80)/20))))
img.save('CydiaIcon.png')
" 2>/dev/null && echo "Icon created with Python/PIL" || {
    # Fallback: create a minimal PNG using shell
    echo "Creating icon with python3..."
    python3 -c "
import struct, zlib
width, height = 256, 256
pixels = []
for y in range(height):
    pixels.append(b'\x00')  # filter byte
    for x in range(width):
        dx, dy = x - 128, y - 128
        d = (dx*dx + dy*dy) ** 0.5
        if d < 80:
            brightness = max(0, int(255 * (1 - d/80)))
            pixels.append(struct.pack('BBBB', brightness, brightness//2, brightness, brightness))
        elif d < 100:
            a = max(0, int(100 * (1 - (d-80)/20)))
            pixels.append(struct.pack('BBBB', 80, 40, 120, a))
        else:
            pixels.append(b'\x00\x00\x00\x00')
raw = b''.join(pixels)
compress = zlib.compress(raw)
def make_chunk(t, d):
    c = struct.pack('>I', len(d)) + t + d
    return c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
with open('CydiaIcon.png', 'wb') as f:
    f.write(b'\x89PNG\r\n\x1a\n')
    f.write(make_chunk(b'IHDR', ihdr))
    f.write(make_chunk(b'IDAT', compress))
    f.write(make_chunk(b'IEND', b''))
"
}
fi

echo "=== Repository generated ==="
echo "Location: $REPO_DIR"
echo "Files:"
ls -lh "$REPO_DIR/Packages" "$REPO_DIR/Packages.gz" "$REPO_DIR/Packages.bz2" "$REPO_DIR/Packages.xz" "$REPO_DIR/Release" "$REPO_DIR/CydiaIcon.png" 2>/dev/null