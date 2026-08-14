#!/bin/sh
# Installs a root LaunchDaemon for MacFan SMC writes.
# No nohup. No python3 (often an Xcode stub). No ad-hoc runtime codesign.
set -u

SRC="${1:-}"
HELPER="/Library/PrivilegedHelperTools/com.macfan.smc"
PLIST="/Library/LaunchDaemons/com.macfan.smchelper.plist"
LABEL="system/com.macfan.smchelper"
LOG="/tmp/macfan-helper.log"
SOCKET="/tmp/macfan-smc.sock"
PIDF="/tmp/macfan-helper.pid"

log() {
  printf '%s [installer] %s\n' "$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >>"$LOG"
}

/bin/rm -f "$LOG" "$PIDF" "$SOCKET"
/usr/bin/printf 'MacFan installer 1.1.5\n' >"$LOG"
/bin/chmod 666 "$LOG" 2>/dev/null || true

if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
  log "source missing: ${SRC:-<empty>}"
  exit 1
fi

/bin/mkdir -p /Library/PrivilegedHelperTools /Library/LaunchDaemons
/bin/cp -f "$SRC" "$HELPER" || { log "copy failed from $SRC"; exit 1; }
/usr/sbin/chown root:wheel "$HELPER"
/bin/chmod 755 "$HELPER"
/usr/bin/xattr -cr "$HELPER" 2>/dev/null || true
log "copied helper from $SRC"

/bin/launchctl bootout "$LABEL" 2>/dev/null || true
/bin/launchctl unload "$PLIST" 2>/dev/null || true
/usr/bin/killall com.macfan.smc 2>/dev/null || true
/usr/bin/pkill -f '/Library/PrivilegedHelperTools/com.macfan.smc --smc-helper' 2>/dev/null || true
/usr/bin/pkill -f 'MacFan --smc-helper' 2>/dev/null || true
/bin/sleep 0.25
/bin/rm -f "$SOCKET"

/bin/cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.macfan.smchelper</string>
	<key>ProgramArguments</key>
	<array>
		<string>${HELPER}</string>
		<string>--smc-helper</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
	<key>StandardOutPath</key>
	<string>${LOG}</string>
	<key>StandardErrorPath</key>
	<string>${LOG}</string>
	<key>ProcessType</key>
	<string>Background</string>
</dict>
</plist>
EOF
/usr/sbin/chown root:wheel "$PLIST"
/bin/chmod 644 "$PLIST"
log "wrote $PLIST"

if /bin/launchctl bootstrap system "$PLIST" >>"$LOG" 2>&1; then
  log "launchctl bootstrap ok"
else
  log "bootstrap failed, trying launchctl load -w"
  /bin/launchctl load -w "$PLIST" >>"$LOG" 2>&1 || log "launchctl load failed"
fi

if [ ! -S "$SOCKET" ]; then
  log "perl daemon fallback"
  /usr/bin/perl -e '
    use POSIX qw(setsid);
    my ($exe, $log) = @ARGV;
    exit 0 if fork;
    setsid();
    exit 0 if fork;
    chdir "/";
    open STDOUT, ">>", $log;
    open STDERR, ">>&STDOUT";
    exec $exe, "--smc-helper" or POSIX::_exit(127);
  ' "$HELPER" "$LOG" || log "perl spawn failed"
fi

i=0
while [ "$i" -lt 80 ]; do
  if [ -S "$SOCKET" ]; then
    /bin/chmod 666 "$SOCKET" "$LOG" 2>/dev/null || true
    log "socket ready"
    echo OK
    exit 0
  fi
  /bin/sleep 0.15
  i=$((i + 1))
done

log "timeout waiting for $SOCKET"
/usr/bin/tail -20 "$LOG" >>"$LOG" 2>/dev/null || true
exit 1
