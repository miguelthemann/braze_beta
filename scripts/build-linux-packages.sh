#!/usr/bin/env bash
set -e

VERSION="${1:-1.0.1}"
BUILD_DIR="build/braze-linux"
OUT_DIR="build"

echo "Building Linux Packages for Braze v${VERSION}..."
mkdir -p "$BUILD_DIR/opt/braze"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/share/icons/hicolor/128x128/apps"

# 1. Download official Firefox Linux tarball
wget -qO firefox.tar.bz2 "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US"
tar -xf firefox.tar.bz2
mv firefox/* "$BUILD_DIR/opt/braze/"
rm -rf firefox firefox.tar.bz2

# 2. Inject Braze configurations
mkdir -p "$BUILD_DIR/opt/braze/distribution/extensions"
cp distribution/policies.json "$BUILD_DIR/opt/braze/distribution/"
cp braze-shields.xpi "$BUILD_DIR/opt/braze/distribution/"
cp braze-shields.xpi "$BUILD_DIR/opt/braze/distribution/extensions/braze-shields@miguelthemann.github.io.xpi"
cp -r extension home profile "$BUILD_DIR/opt/braze/"

# 3. Create standalone wrapper script
cat << 'EOF' > "$BUILD_DIR/usr/bin/braze"
#!/usr/bin/env bash
BRAZE_DIR="/opt/braze"
export MOZ_APP_DISPLAYNAME="Braze"
export MOZ_APP_NAME="braze"
export MOZ_APP_VENDOR="Braze"
SOCK_PATH="/tmp/braze-rdp-$$.sock"
rm -f "$SOCK_PATH"
trap 'rm -f "$SOCK_PATH"' EXIT INT TERM

# Start silent native extension bridge
python3 -c '
import os, sys, socket, json, time
sock_path = sys.argv[1]
ext_dir = sys.argv[2]
for _ in range(50):
    if os.path.exists(sock_path): break
    time.sleep(0.05)
if not os.path.exists(sock_path): sys.exit(0)
try:
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(sock_path)
    s.settimeout(5)
    def recv_pkt():
        buf = b""
        while b":" not in buf:
            c = s.recv(1)
            if not c: raise EOFError()
            buf += c
        l, rest = buf.split(b":", 1)
        l = int(l)
        body = rest
        while len(body) < l:
            body += s.recv(l - len(body))
        return json.loads(body.decode("utf-8"))
    def send_pkt(obj):
        msg = json.dumps(obj)
        s.sendall(f"{len(msg)}:{msg}".encode("utf-8"))
    recv_pkt()
    send_pkt({"to": "root", "type": "getRoot"})
    r = recv_pkt()
    actor = r.get("addonsActor")
    if actor:
        send_pkt({"to": actor, "type": "installTemporaryAddon", "addonPath": ext_dir})
        recv_pkt()
    s.close()
except:
    pass
' "$SOCK_PATH" "$BRAZE_DIR/extension" >/dev/null 2>&1 &

exec "$BRAZE_DIR/firefox" --class "Braze" --name "Braze" --profile "$BRAZE_DIR/profile" --start-debugger-server "$SOCK_PATH" "$@"
EOF

chmod +x "$BUILD_DIR/usr/bin/braze"

# 4. Desktop entry and icons
cp braze.desktop "$BUILD_DIR/usr/share/applications/"
cp assets/icon-128.png "$BUILD_DIR/usr/share/icons/hicolor/128x128/apps/braze.png"

# 5. Package with FPM
fpm -s dir -t deb \
  -n "braze" -v "$VERSION" --architecture amd64 \
  --description "O rival caótico do Microfost Ledge" \
  --maintainer "Miguel The Mann" \
  -C "$BUILD_DIR" -p "$OUT_DIR/braze_${VERSION}_amd64.deb" \
  opt usr

fpm -s dir -t rpm \
  -n "braze" -v "$VERSION" --architecture x86_64 \
  --description "O rival caótico do Microfost Ledge" \
  --maintainer "Miguel The Mann" \
  -C "$BUILD_DIR" -p "$OUT_DIR/braze-${VERSION}-1.x86_64.rpm" \
  opt usr

echo "Done! Built .deb and .rpm"
