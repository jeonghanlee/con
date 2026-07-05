#!/usr/bin/env bash
#
# Release-gate step 4 downstream driver -- testplan_1.1.0.md "Release Gate" (#27).
#
# Runs ON an epics-ioc-runner golden testbed as vmadmin (never on the dev host).
# Verifies the con release candidate in its deployed role: pin assert inside the
# console-holding principal (opb), multiuser S10 access probes, the two-con
# shared-console check, and S4 removal-under-attach. Order matters: S4 removes
# the IOC, so it runs last (testplan_multiuser.md Notes).
#
# Prerequisites on the golden (see epics-ioc-runner docs/testplan_multiuser.md
# for the environment: golden images, fixtures, harness):
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
# Provenance: validated 2026-07-02 with candidate 7dff13c, 11/11 PASS on both
# goldens (testbed-rocky8/debian13-iocrunner-server); the stale con 1.0.0 on
# the fixed path was correctly bypassed by the IOC_RUNNER_CON_TOOL pin.
# Re-validated 2026-07-04 with candidate d714c13 in a docs-only dry run, which
# exposed the pin assert's hardcoded hash (false FAIL on any later candidate);
# the assert is candidate-agnostic since. Same day: the DEPS preamble and the
# S4 existence-then-absence pre-check were added (dependency-pinning session),
# initial pin epics-ioc-runner 1.2.0 (6c50604) after the goldens were updated
# from the unreproducible 1.2.0-dev dirty build.
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
# "Dependency pins and advancement"; each bump lands one ledger line in
# docs/milestone.md. For an advancement run, GATE_DEPS_EXPECT re-targets the
# runner assertion to the declared NEW identity -- it never skips, and a
# set-but-empty value fails.
RUNNER_PIN="epics-ioc-runner version 1.2.0 (6c50604)"
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

echo "==== S10: console socket access probes ===="
# opb (ioc member) attach: hold ~2s, detach via Ctrl-A. Expect clean run, banner captured.
mkfifo "$T/opb.fifo"
( sleep 2.5; printf '\x01'; sleep 0.3 ) > "$T/opb.fifo" &
W1=$!
timeout -k 2 10 script -qec "sudo -niu opb env IOC_RUNNER_CON_TOOL=$CONRC ioc-runner attach $IOC" /dev/null < "$T/opb.fifo" > "$T/opb_attach.out" 2>&1
RC=$?
kill $W1 2>/dev/null; wait $W1 2>/dev/null
if [ $RC -eq 0 ] || [ $RC -eq 1 ]; then ok "S10: opb (ioc) attach ran and detached (rc=$RC)"; else bad "S10: opb attach rc=$RC"; fi
grep -qa "conrc" "$T/opb_attach.out" && ok "S10: opb attach reached the console (banner)" || bad "S10: opb attach shows no console banner"

# obs (non-ioc) attach: denied before reaching the socket. Expect non-zero.
timeout -k 2 10 script -qec "sudo -niu obs env IOC_RUNNER_CON_TOOL=$CONRC ioc-runner attach $IOC" /dev/null < /dev/null > "$T/obs_attach.out" 2>&1
RC=$?
[ $RC -ne 0 ] && ok "S10: obs (non-ioc) attach denied (rc=$RC)" || bad "S10: obs attach unexpectedly succeeded"
head -2 "$T/obs_attach.out" | sed 's/^/  obs: /'

# inspect root-gated for non-root (opb).
timeout -k 2 10 script -qec "sudo -niu opb ioc-runner inspect $IOC" /dev/null < /dev/null > "$T/opb_inspect.out" 2>&1
RC=$?
[ $RC -ne 0 ] && ok "S10: opb inspect root-gated (rc=$RC)" || bad "S10: opb inspect unexpectedly succeeded"

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

echo "==== S4: removal while opb holds a con attach ===="
mkfifo "$T/s4.fifo"
( sleep 60 ) > "$T/s4.fifo" &
WH=$!
timeout -k 2 30 script -qec "sudo -niu opb env IOC_RUNNER_CON_TOOL=$CONRC ioc-runner attach $IOC" /dev/null < "$T/s4.fifo" > "$T/s4_opb.out" 2>&1 &
PH=$!
sleep 3
# Existence-then-absence: prove the socket path is real while the IOC runs, or
# the post-remove absence check would false-pass on a drifted path.
[ -e "$SOCK_DIR" ] && ok "S4: socket path present while attached (pre-check)" || bad "S4: socket path absent while running -- path drift? ($SOCK_DIR)"
sudo -niu opa ioc-runner stop $IOC > "$T/s4_stop.out" 2>&1
timeout -k 2 20 script -qec "sudo -niu opa ioc-runner remove $IOC" /dev/null < /dev/null > "$T/s4_remove.out" 2>&1
T0=$(date +%s)
wait $PH 2>/dev/null
T1=$(date +%s)
kill $WH 2>/dev/null; wait $WH 2>/dev/null
DT=$((T1-T0))
[ $DT -le 5 ] && ok "S4: opb's con session ended promptly after remove (${DT}s, EOF not hang)" || bad "S4: opb's session lingered ${DT}s"
[ ! -e "$SOCK_DIR" ] && ok "S4: socket directory removed with the unit" || bad "S4: stale socket dir remains"
systemctl is-active epics-@${IOC}.service >/dev/null 2>&1 && bad "S4: unit still active" || ok "S4: unit gone"

echo "==== RESULT: PASS=$pass FAIL=$fail ===="
rm -rf "$T"
exit $fail
