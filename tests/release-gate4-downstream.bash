#!/usr/bin/env bash
#
# Downstream driver for the release gate defined by docs/release-gate.md (#27).
#
# Runs ON an epics-ioc-runner golden testbed as vmadmin (never on the dev host).
# Verifies the con release candidate in its deployed role: pin assert inside the
# console-holding principal (opb), S10 attach and monitor access probes, the
# two-con shared-console check, and S4 removal-under-attach. Order matters: S4
# removes the IOC, so it runs last according to the pinned upstream runbook.
#
# Prerequisites on the golden come from the pinned epics-ioc-runner runbook:
#   - candidate con staged at /opt/con-rc/con (root-owned 755; scp + install)
#   - fixture accounts opa/opb (group ioc) and obs, provisioned per run
#   - payload IOC "conrc" installed and running (softIoc shebang st.cmd in
#     /opt/epics-iocs/conrc; ioc-runner generate + install + start as opa)
#   - golden utilities assumed present, absence fails loud: script(1),
#     timeout(1); git is needed by the runner INSTALLER, not this driver
# Usage: scp this file to the golden, then: ssh vmadmin@<golden> bash <file>
# Exit status = number of failed checks.
#
# The DEPS preamble asserts the PINNED environment identity (ioc-runner -V,
# OS VERSION_ID, sudo version) before any scenario and aborts on mismatch;
# pin advancement follows docs/release-gate.md "Dependency pins and
# advancement" (GATE_DEPS_EXPECT re-targets the runner assertion for the
# advancement run itself).
#
# The default dependency pin is the released runner environment accepted by the
# active release plan. GATE_DEPS_EXPECT remains available only for the separate
# advancement run defined by docs/release-gate.md.
set -u
CONRC=/opt/con-rc/con
IOC=conrc
SOCK_DIR=/run/procserv/${IOC}
T=/tmp/gate4.$$
mkdir -p "$T"
pass=0; fail=0
ok()  { echo "[ PASS ] $1"; pass=$((pass+1)); }
bad() { echo "[ FAIL ] $1"; fail=$((fail+1)); }

echo "==== DEPS: pinned environment identity ===="
# This driver is the seam's ONLY guard (the upstream gate is con-agnostic), so
# the environment is pinned and asserted before any scenario runs. Pin home =
# these variables; the advancement process is docs/release-gate.md
# "Dependency pins and advancement". The released-con compatibility result
# lands in the active G row; the local driver update and candidate evidence
# land in the final release detail. For an advancement run, GATE_DEPS_EXPECT re-targets the
# runner assertion to the declared NEW identity -- it never skips, and a
# set-but-empty value fails.
RUNNER_PIN="epics-ioc-runner version 1.2.4 (1961fbf)"
. /etc/os-release
case "$ID" in
    rocky)  OS_PIN="8.10"; SUDO_PIN="Sudo version 1.9.5p2" ;;
    debian) OS_PIN="13";   SUDO_PIN="Sudo version 1.9.16p2" ;;
    *)      OS_PIN=""; SUDO_PIN="" ;;
esac
RUNNER_EXPECT="${GATE_DEPS_EXPECT-$RUNNER_PIN}"
if [ "${GATE_DEPS_EXPECT+set}" = "set" ]; then
    echo "  ADVANCEMENT RUN: runner assertion re-targeted to: '${GATE_DEPS_EXPECT}'"
fi
RUNNER_V=$(ioc-runner -V 2>/dev/null | head -1)
echo "  runner: $RUNNER_V"
echo "  expect: $RUNNER_EXPECT"
if [ -n "$RUNNER_EXPECT" ] && [ "$RUNNER_V" = "$RUNNER_EXPECT" ]; then ok "DEPS: runner identity matches the pin"; else bad "DEPS: runner identity mismatch"; fi
echo "  os: $ID $VERSION_ID (pin: $OS_PIN)"
if [ -n "$OS_PIN" ] && [ "$VERSION_ID" = "$OS_PIN" ]; then ok "DEPS: OS identity matches the per-golden pin"; else bad "DEPS: OS mismatch or unpinned golden ($ID $VERSION_ID)"; fi
SUDO_V=$(sudo -V 2>/dev/null | head -1)
echo "  sudo: $SUDO_V (pin: $SUDO_PIN)"
if [ -n "$SUDO_PIN" ] && [ "$SUDO_V" = "$SUDO_PIN" ]; then ok "DEPS: sudo identity matches the per-golden pin"; else bad "DEPS: sudo mismatch"; fi
if [ $fail -ne 0 ]; then
    echo "==== DEPS mismatch: this is not the pinned environment; aborting before scenarios ===="
    echo "==== RESULT: PASS=$pass FAIL=$fail ===="
    rm -rf "$T"
    exit $fail
fi

echo "==== PIN: candidate identity inside opb's context ===="
# Candidate-agnostic: the reference is the staged binary itself, never a
# hardcoded version string -- a hardcoded hash false-fails every later
# candidate. The releaser eyeballs the printed identity against the intended
# release version.
CAND_V=$("$CONRC" -V 2>/dev/null | head -1)
PIN_OUT=$(sudo -nu opb env IOC_RUNNER_CON_TOOL=$CONRC bash -c '"$IOC_RUNNER_CON_TOOL" -V' 2>&1 | head -1)
echo "  staged candidate: $CAND_V"
echo "  opb resolves:     $PIN_OUT"
if [ -n "$CAND_V" ] && [ "$PIN_OUT" = "$CAND_V" ]; then ok "opb-context resolution matches the staged candidate ($CAND_V)"; else bad "opb-context mismatch: staged=$CAND_V opb=$PIN_OUT"; fi

printf "%s\n" "==== S10: console socket access probes ===="
# The wrapper owns the member attach and monitor exit codes. The connection
# banner is the success evidence for those bounded sessions.
mkfifo "$T/opb.fifo"
( sleep 2.5; printf '\x01'; sleep 0.3 ) > "$T/opb.fifo" &
W1=$!
timeout -k 2 10 script -qec "sudo -niu opb env IOC_RUNNER_CON_TOOL=$CONRC ioc-runner attach $IOC" /dev/null < "$T/opb.fifo" > "$T/opb_attach.out" 2>&1
RC=$?
kill $W1 2>/dev/null; wait $W1 2>/dev/null
if grep -qaF "Child \"$IOC\"" "$T/opb_attach.out"; then ok "S10: opb attach reached the console (wrapper rc=$RC)"; else bad "S10: opb attach shows no console banner (wrapper rc=$RC)"; fi

timeout -k 2 10 script -qec "sudo -niu opb env IOC_RUNNER_CON_TOOL=$CONRC ioc-runner monitor $IOC" /dev/null < /dev/null > "$T/opb_monitor.out" 2>&1
RC=$?
if grep -qaF "Child \"$IOC\"" "$T/opb_monitor.out"; then ok "S10: opb monitor reached the console (wrapper rc=$RC)"; else bad "S10: opb monitor shows no console banner (wrapper rc=$RC)"; fi

# obs (non-ioc) attach and monitor are denied before reaching the socket.
timeout -k 2 10 script -qec "sudo -niu obs env IOC_RUNNER_CON_TOOL=$CONRC ioc-runner attach $IOC" /dev/null < /dev/null > "$T/obs_attach.out" 2>&1
RC=$?
if [ $RC -ne 0 ] && ! grep -qaF "Child \"$IOC\"" "$T/obs_attach.out"; then ok "S10: obs attach denied before the console (rc=$RC)"; else bad "S10: obs attach reached the console or returned zero (rc=$RC)"; fi
head -2 "$T/obs_attach.out" | sed 's/^/  obs: /'

timeout -k 2 10 script -qec "sudo -niu obs env IOC_RUNNER_CON_TOOL=$CONRC ioc-runner monitor $IOC" /dev/null < /dev/null > "$T/obs_monitor.out" 2>&1
RC=$?
if [ $RC -ne 0 ] && ! grep -qaF "Child \"$IOC\"" "$T/obs_monitor.out"; then ok "S10: obs monitor denied before the console (rc=$RC)"; else bad "S10: obs monitor reached the console or returned zero (rc=$RC)"; fi

# inspect is root-gated for every non-root principal.
timeout -k 2 10 script -qec "sudo -niu opb ioc-runner inspect $IOC" /dev/null < /dev/null > "$T/opb_inspect.out" 2>&1
RC=$?
if [ $RC -ne 0 ]; then ok "S10: opb inspect root-gated (rc=$RC)"; else bad "S10: opb inspect unexpectedly succeeded"; fi

timeout -k 2 10 script -qec "sudo -niu obs ioc-runner inspect $IOC" /dev/null < /dev/null > "$T/obs_inspect.out" 2>&1
RC=$?
if [ $RC -ne 0 ]; then ok "S10: obs inspect root-gated (rc=$RC)"; else bad "S10: obs inspect unexpectedly succeeded"; fi

SOCK_DIR_MODE=$(sudo -nu opb stat -c '%U:%G %a' "$SOCK_DIR" 2>/dev/null)
SOCK_MODE=$(sudo -nu opb stat -c '%U:%G %a' "$SOCK_DIR/control" 2>/dev/null)
if [ "$SOCK_DIR_MODE" = "ioc-srv:ioc 770" ]; then ok "S10: socket directory mode matches the pin"; else bad "S10: socket directory mode mismatch ($SOCK_DIR_MODE)"; fi
if [ "$SOCK_MODE" = "ioc-srv:ioc 660" ]; then ok "S10: control socket mode matches the pin"; else bad "S10: control socket mode mismatch ($SOCK_MODE)"; fi

echo "==== TWO-CON: shared procServ console, both typing ===="
MARK_A="GATE4_FROM_OPA_$$"
MARK_B="GATE4_FROM_OPB_$$"
mkfifo "$T/a.fifo" "$T/b.fifo"
( sleep 2.5; printf '%s\n' "$MARK_A"; sleep 3.5; printf '\x01'; sleep 0.3 ) > "$T/a.fifo" &
WA=$!
( sleep 4.0; printf '%s\n' "$MARK_B"; sleep 2.5; printf '\x01'; sleep 0.3 ) > "$T/b.fifo" &
WB=$!
timeout -k 2 15 script -qec "sudo -niu opa env IOC_RUNNER_CON_TOOL=$CONRC ioc-runner attach $IOC" /dev/null < "$T/a.fifo" > "$T/two_a.out" 2>&1 &
PA=$!
timeout -k 2 15 script -qec "sudo -niu opb env IOC_RUNNER_CON_TOOL=$CONRC ioc-runner attach $IOC" /dev/null < "$T/b.fifo" > "$T/two_b.out" 2>&1 &
PB=$!
wait $PA 2>/dev/null; wait $PB 2>/dev/null
kill $WA $WB 2>/dev/null; wait $WA $WB 2>/dev/null
grep -qaF "$MARK_A" "$T/two_b.out" && ok "two-con: opb's console shows opa's line (shared console)" || bad "two-con: opa's line missing from opb's console"
grep -qaF "$MARK_B" "$T/two_a.out" && ok "two-con: opa's console shows opb's line (shared console)" || bad "two-con: opb's line missing from opa's console"
systemctl is-active epics-@${IOC}.service >/dev/null 2>&1 && ok "two-con: IOC still active after both detached" || bad "two-con: IOC not active after detach"

printf "%s\n" "==== S4: removal while opb holds a con attach ===="
mkfifo "$T/s4.fifo"
( sleep 120 ) > "$T/s4.fifo" &
WH=$!
timeout -k 2 120 script -qec "sudo -niu opb env IOC_RUNNER_CON_TOOL=$CONRC ioc-runner attach $IOC" /dev/null < "$T/s4.fifo" > "$T/s4_opb.out" 2>&1 &
PH=$!
ATTACHED=0
for _attempt in $(seq 30); do
    if grep -qaF "Child \"$IOC\"" "$T/s4_opb.out" 2>/dev/null; then ATTACHED=1; break; fi
    sleep 1
done
if [ "$ATTACHED" -eq 1 ]; then
    ok "S4: opb held the con console before removal"
else
    bad "S4: opb did not reach the console before removal"
    kill "$PH" "$WH" 2>/dev/null
    wait "$PH" "$WH" 2>/dev/null
    printf "==== RESULT: PASS=%s FAIL=%s ====\n" "$pass" "$fail"
    rm -rf "$T"
    exit "$fail"
fi

timeout -k 2 40 script -qec "sudo -niu opa ioc-runner remove $IOC --force" /dev/null < /dev/null > "$T/s4_remove.out" 2>&1
REMOVE_RC=$?
T0=$(date +%s)
CLIENT_RC=0
wait "$PH" 2>/dev/null || CLIENT_RC=$?
T1=$(date +%s)
kill "$WH" 2>/dev/null; wait "$WH" 2>/dev/null
DT=$((T1-T0))
if [ "$REMOVE_RC" -eq 0 ]; then ok "S4: remove --force completed"; else bad "S4: remove --force failed (rc=$REMOVE_RC)"; fi
if [ "$CLIENT_RC" -eq 0 ] && grep -qaF 'EOF' "$T/s4_opb.out"; then ok "S4: con exited on EOF after removal"; else bad "S4: con did not exit cleanly on EOF (rc=$CLIENT_RC)"; fi
if [ "$DT" -le 5 ]; then ok "S4: opb's con session ended promptly after remove (${DT}s)"; else bad "S4: opb's session lingered ${DT}s"; fi
if [ ! -e "$SOCK_DIR" ]; then ok "S4: socket directory removed with the unit"; else bad "S4: stale socket directory remains"; fi
if systemctl is-active "epics-@${IOC}.service" >/dev/null 2>&1; then bad "S4: unit still active"; else ok "S4: unit gone"; fi

echo "==== RESULT: PASS=$pass FAIL=$fail ===="
rm -rf "$T"
exit $fail
