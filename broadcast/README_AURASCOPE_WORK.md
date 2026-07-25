# Aurascope nRF5340 Audio Bring-Up — Work Log

This documents the work done getting the nRF5340 Audio application (broadcast
source/sink, Auracast) running on the custom **Aurascope** board, including a
USB-audio-card ("mic-only" USB sink) mode for the headset. It also covers a
comparative analysis of a separate, older unicast project on the same
hardware family (`~/Downloads/1_blau_compatibility_old_badges`).

Board files: `nrf/boards/aurascope/`. App: `nrf/applications/nrf5340_audio/`.

## Canonical build commands

Environment (every build):
```bash
source /home/t/asset-tracker-template/.venv/bin/activate
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export ZEPHYR_SDK_INSTALL_DIR=/home/t/ncs/toolchains/c5be9c56c7/opt/zephyr-sdk
```

**Gateway (broadcast_source)** — defaults to USB audio source; add
`-DCONFIG_AUDIO_SOURCE_I2S=y` to use the physical I2S microphone instead:
```bash
west build -b aurascope/nrf5340/cpuapp -d build_broadcast_source -- \
  -DEXTRA_CONF_FILE="broadcast_source/overlay-broadcast_source.conf" \
  -DFILE_SUFFIX=fota -DCONFIG_AUDIO_SOURCE_I2S=y
```

**Headset (broadcast_sink)**, as a USB audio card receiving both channels
of the broadcast on one device:
```bash
west build -b aurascope/nrf5340/cpuapp -d build_broadcast_sink -- \
  -DEXTRA_CONF_FILE="broadcast_sink/overlay-broadcast_sink.conf" \
  -DCONFIG_AUDIO_SINK_USB=y -DFILE_SUFFIX=fota \
  -DEXTRA_DTC_OVERLAY_FILE="boards/aurascope_usb_mic_only.overlay" \
  -DCONFIG_DEVICE_LOCATION_SET_COMPILE_TIME=y -DCONFIG_DEVICE_LOCATION_AT_COMPILE_TIME=3
```

Flash: `west flash -d <build_dir>`. After changing devicetree/Kconfig,
prefer a full `rm -rf <build_dir>` over `--pristine` — see the MCUboot
stale-slot note below for why a **full chip erase** (`west flash -d <dir>
--erase`) matters after FOTA testing.

## What was built

- **I2S microphone wiring** for the gateway: `I2S_SCK_M`→P0.06, `I2S_LRCK_M`→P0.07,
  `I2S_SDIN`→P0.26 (real hardware pins, confirmed against actual board wiring
  during this session — do not assume these match any reference board).
- **External QSPI flash** (`mx25r64`, same chip/pins as `nrf5340dk`) added to
  `nrf/boards/aurascope/aurascope/aurascope_nrf5340_cpuapp_common.dtsi` +
  pinctrl, needed for FOTA external-flash secondary slot.
- **`CONFIG_AUDIO_SINK_USB`** (new Kconfig, `src/audio/Kconfig`): lets the
  *headset* role send its decoded downlink audio to a USB host as a UAC2
  microphone-only device, instead of the default I2S/HW-codec output.
  Implemented via:
  - `src/modules/audio_usb.c`: new `host_in`-only branch in `audio_usb_init()`
    (previously `-ENOTSUP`), reusing the bidirectional `uac2_headset`
    descriptor since no mic-only UAC2 devicetree binding exists.
  - `src/audio/audio_system.c`: `AUDIO_DEV_USES_USB` macro extends the
    existing gateway-only USB gating to also cover `HEADSET + AUDIO_SINK_USB`.
  - `src/audio/le_audio_rx.c`: routes decoded audio through
    `audio_system_decode()` (which already splits into 1ms USB blocks)
    instead of `audio_datapath_stream_out()` (I2S) when in USB-sink mode.
  - `src/modules/CMakeLists.txt`: `audio_usb.c`/`audio_usb_init.c` now compile
    for `AUDIO_SOURCE_USB` **or** `AUDIO_SINK_USB` (was gateway-only before).

## Bugs found and fixed (chronological)

1. **`ZEPHYR_TOOLCHAIN_VARIANT`/SDK mismatch** — needed to point at the
   correct NCS toolchain bundle (`/home/t/ncs/toolchains/c5be9c56c7/opt/zephyr-sdk`,
   SDK 0.17.0), not the standalone `/home/t/zephyr-sdk-1.0.1` (wrong major version).

2. **Missing `audioleds` devicetree node** — the app's LED module requires a
   board-level `audioleds` node; added to `boards/aurascope_nrf5340_cpuapp.overlay`
   (copied from `nrf5340dk`'s equivalent, since Aurascope shares that pinout).

3. **QSPI external flash devicetree + Kconfig** for FOTA — added the `mx25r64`
   node/pinctrl at the board level, and a `nordic,pm-ext-flash` chosen node
   in both `boards/aurascope_nrf5340_cpuapp_fota.overlay` (app image) *and*
   `sysbuild/mcuboot/boards/aurascope_nrf5340_cpuapp_fota.overlay` (MCUboot
   image needs its own copy — it's a separate sysbuild image with its own
   devicetree, doesn't inherit the app's).

4. **`bt_mgmt_init()` crash (`-EINVAL`) on headset+FOTA** — `CONFIG_AUDIO_BT_MGMT_DFU`
   (button-triggered DFU mode) requires `BT_PERIPHERAL` (set by headset, not
   gateway) + `BOOTLOADER_MCUBOOT`. It calls `button_pressed(BUTTON_4, ...)`
   unconditionally; Aurascope only has 4 buttons (`sw0-sw3`, no `sw4`), so
   `BUTTON_4` is always `BUTTON_NOT_ASSIGNED`, and `button_pressed()` treats
   that as a hard error. **Not a bug in the button-check logic** — every other
   caller in the codebase has the same "no guard" pattern; it's a board
   capability gap. Fixed by disabling the feature for this board:
   `boards/aurascope_nrf5340_cpuapp_fota.conf` → `CONFIG_AUDIO_BT_MGMT_DFU=n`.
   Core FOTA (MCUboot image swap) doesn't depend on this feature at all.

5. **USB devicetree node merging** — the overlay (copied from `nrf5340dk`)
   defined `uac2_headset` and `uac2_headphones` as two `usb_audio2` blocks at
   the same devicetree path; Zephyr merges same-path nodes, so they became one
   node with two labels and colliding child names (`out_interface` used by
   both). Fixed by giving the second block a distinct path (`usb_audio2_hp`)
   and renaming its `out_interface` child to `hp_out_interface`.

6. **USB endpoint-assignment failure** (`"Failed to assign endpoint addresses"`,
   `usbd_is_initialized` assertion) — once separated, both `uac2_headset` and
   `uac2_headphones` became independent class instances, and having *both*
   active simultaneously exhausted available endpoint addresses. Since
   mic-only mode never uses `uac2_headphones`, added
   `boards/aurascope_usb_mic_only.overlay` (`&uac2_headphones { status =
   "disabled"; };`), applied only for the sink-USB build via
   `-DEXTRA_DTC_OVERLAY_FILE`. This required a matching guard in
   `audio_usb.c` (`#if DT_NODE_HAS_STATUS(...)`) since `DEVICE_DT_GET()` is a
   compile-time macro that stops resolving once the node is disabled.
   (Gateway's default build is unaffected — it doesn't pass this extra overlay.)

7. **Only syncing to one BIS stream (`Chan alloc: 0x1` only)** — not a bug:
   `broadcast_sink.c`'s `bis_per_subgroup_parse()` filters each BIS by
   whether its channel allocation matches `device_location_get()`. This app
   is designed for **pairs of separate physical headsets**, each assigned a
   single location. For one device to receive both channels (this project's
   actual goal — one board as a stereo USB sound card), its own location
   must be the *combination* `FRONT_LEFT | FRONT_RIGHT` (bitfield `3`), set via
   the already-existing `CONFIG_DEVICE_LOCATION_SET_COMPILE_TIME=y` +
   `CONFIG_DEVICE_LOCATION_AT_COMPILE_TIME=3` (no button press, no code change).

8. **MCUboot stale-slot revert** — after the location fix above compiled
   correctly (verified in `.config`/`autoconf.h`), the device kept booting
   with the *old* location. Root cause: MCUboot's swap-based upgrade can
   revert to an unconfirmed image left in the external-flash secondary slot
   from earlier FOTA testing, even though the new flash to the primary slot
   succeeded. Fixed by a full erase before reflashing (`west flash --erase`).

9. **`audio_system_decode()` hardcoding mono output** — `*meta_out =
   decoder_meta;` unconditionally set `meta_out->locations =
   BT_AUDIO_LOCATION_MONO_AUDIO`. `sw_codec_decode()` uses
   `audio_metadata_num_loc_get(meta_out)` to decide how many channels to
   actually decode into the output buffer, so even after both BIS streams
   were correctly received and paired on input, only one channel ever made
   it to the USB output. This function was originally written only for
   gateway's mono bidirectional uplink, where the hardcode was correct; it
   silently broke once reused for a genuinely stereo headset-USB-sink case.
   Fixed by setting `meta_out->locations = sw_codec_cfg.decoder.audio_loc;`
   (the decoder's real configured locations) instead of the hardcoded mono
   value.

After fixes 7–9: confirmed `"Syncing to broadcast stream index 0x0003"` (both
bits), both `Stream index 0`/`Chan alloc 0x1` and `Stream index 1`/`Chan alloc
0x2` starting, and — for the first time — an actual recognizable audio wave
over USB, not noise.

## Current open issue: residual jitter/glitches

With the wave now correct, audible jitter/glitches remain. Diagnostic steps
taken, in order:

- **USB TX buffer depth bump** (`CONFIG_FIFO_TX_FRAME_COUNT` 3→6, i.e. 30ms→60ms
  of buffering before the USB consumer): **no improvement**.
- **Sender-side RX FIFO bump** (`CONFIG_FIFO_RX_FRAME_COUNT` 1→3, the raw PCM
  buffer before LC3 encoding): **no improvement**.
- **BLE link quality check** (`CONFIG_LE_AUDIO_RX_LOG_LEVEL_DBG=y`, watching
  `"ISO RX SDUs: Loc: N Total: T Bad: B"`): **`Bad: 0`** across 1600+ packets
  per channel over ~16s. BLE reception is provably clean — rules out radio
  interference/packet loss entirely.

**Working theory**: the USB-sink decode path
(`audio_system_decode()`/`le_audio_rx.c`) never engages the drift/presentation
compensation state machines that exist in `audio_datapath.c`
(`DRIFT_STATE_INIT/CALIB/OFFSET/LOCKED`, `PRES_STATE_*`) — those only run for
the I2S output path. There is no correction at all for clock-domain mismatch
between the BLE/LC3 timing reference and the USB host's own clock. Since no
two independent oscillators match exactly, the uncorrected rate difference
accumulates until the buffer over/underruns — a periodic glitch, at a rate
buffer depth alone can only slow down, not eliminate (consistent with both
buffer bumps failing to help).

### Comparative data point: `1_blau_compatibility_old_badges` (unicast)

A separate, older unicast (CIS) project on the same hardware family
(`mic` = `unicast_server`, `receiver` = `unicast_client`) has the *same*
missing-drift-compensation gap on its USB path, and even the same hardcoded
`sw_codec_cfg.decoder.sample_rate_hz = 24000` pattern in `receiver`'s
`audio_system.c` (confirmed at two call sites) — but is reported to run with
**no jitter**. Two non-exclusive explanations:

1. That project may genuinely run at 24kHz (a common unicast preset), making
   the hardcode coincidentally correct there, unlike the 48kHz aurascope
   broadcast case where it would be a real mismatch.
2. CIS connections are two-way (connection events, ACKs, a link-layer-maintained
   shared timing reference), whereas a BIS broadcast sink is a purely passive
   listener with no feedback path to the source at all. Missing drift
   compensation may be a mostly-invisible gap under CIS but fully exposed
   under BIS, since nothing else is correcting for it there.

This is consistent with, not a contradiction of, the drift-compensation
theory — it suggests BIS reception is specifically the case where the
missing piece actually matters.

### Proposed next step (not yet implemented)

Add a lightweight buffer-level drift corrector on the USB decode path:
monitor `audio_q_tx` fill level, and when it drifts too far from its target
midpoint, skip or duplicate a single 1ms block to nudge it back — rather than
restructuring the decode path to reuse the full I2S presentation/drift-comp
state machine. Requires iterative testing on real hardware (not verifiable
from this environment) to tune correction aggressiveness against audible
side effects.

## Notes on working environment

This session's assistant had direct filesystem access to
`/home/t/asset-tracker-template` (this repo) *and*
`/home/t/Downloads/1_blau_compatibility_old_badges` on the same machine
(`t-ThinkPad-T460`) — a fact discovered partway through the session, after
initially assuming (incorrectly) that pasted code from the latter was on an
inaccessible separate machine. Earlier back-and-forth in this session
involved unnecessary paste/grep round-trips before that was discovered.
