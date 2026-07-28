# mupen64plus-libretro-nx — Claude Instructions

RetroNest's N64 core: fork of libretro/mupen64plus-libretro-nx (GPL — public
repo is fine), loaded in-process by RetroNest. Branch: `develop`, remote
`MarkrPearce96/mupen64plus-libretro-nx`. Renderer: GLideN64 (OpenGL via glsm);
parallel-RSP/RDP are compiled OUT for macOS.

## Build + stage (local dev loop)

```sh
make platform=osx WITH_DYNAREC=aarch64 HAVE_PARALLEL_RSP=0 HAVE_PARALLEL_RDP=0 -j8
codesign --force --sign - mupen64plus_next_libretro.dylib
cp -f mupen64plus_next_libretro.dylib ~/Documents/Projects/n64-test/
```

- **Stale-.o trap:** switching arch/flags without `find . -name "*.o" -delete`
  produces wrong-arch or undefined-symbol link failures. Delete the touched
  .o files (or all) before rebuilding after any flag change.
- The shell cannot write into `~/Documents/RetroNest` (TCC): stage to
  `~/Documents/Projects/n64-test/` and have the user Finder-copy the dylib
  into `.../RetroNest/emulators/libretro/cores/`.
- x86_64 slice (CI parity builds) needs the x86 Homebrew nasm:
  `ASFLAGS="-f macho64 -DLEADING_UNDERSCORE"`.

## CI release

Tag push `v*` → `.github/workflows/libretro_release.yml` builds **both arches
sequentially on macos-14** (with `*.o` clean between slices), lipo-merges,
re-signs, verifies (both slices present, no Homebrew refs), and publishes ONE
universal `mupen64plus_next_libretro.dylib.zip` under the historical asset
name (RetroNest arch-invisible install policy). Current release: v2026.07.27.

## Apple/aarch64 dynarec invariants (do not regress)

- **`-DNO_ASM` must NOT be defined when a dynarec is built.** The osx block
  adds it only when `WITH_DYNAREC` is empty, and AFTER the Makefile's
  `WITH_DYNAREC =` reset line. NO_ASM compiles out `generic_jump_to`'s
  EMUMODE_DYNAREC branch → exception dispatch no-ops → EXL-stuck boot freeze.
- **x18 is reserved on Darwin** (kernel-trashed): excluded from the register
  allocator via the EXCLUDED_HOST_REG predicate in `arm64/assem_arm64.h`.
- **Veneer scratch registers are per-target**: x17 generally, x16 for the
  `jump_vaddr_x17` veneer (x17 is its live argument).
- **W^X**: JIT pages are MAP_JIT; all code writes sit inside depth-counted
  `jit_write_begin()/jit_write_end()` (pthread_jit_write_protect_np), with
  batching around `invalidate_page`'s jump_out kill loop and
  `invalidate_all_pages`. Cache flush = `sys_icache_invalidate`.

## GL / glsm contracts (RetroNest frontend — hard-won, do not regress)

The frontend may retire and REPLACE its output FBO mid-session (RetroNest
rebuilds it under a fresh id if the id gets aliased in the core's GL world).
Everything below exists so the core tolerates that:

- **`rglBindFramebuffer` resolves "framebuffer 0" LIVE** from
  `hw_render.get_current_framebuffer()` on every 0-bind — never trust a
  value latched at context reset.
- **glsm attach wrappers never skip** the real
  `glFramebufferTexture2D/Renderbuffer` based on the cached per-FBO
  attachment record: GL recycles texture ids, so after a delete/create storm
  (savestate load) the record can match numerically while the real
  attachment was auto-detached.
- **`CachedBindFramebuffer` never skip-caches binds** — glsm/frontend raw
  binds around each frame are invisible to it, so "redundant" binds
  frequently aren't.
- **`gln64_invalidate_gl_cache()`** (Context::resetCachedState) runs after
  every `GLSM_CTL_STATE_BIND` in retro_run: STATE_BIND re-imposes glsm's
  tracked GL state with real calls GLideN64's cached-function layer never
  sees.
- **`gln64_reset_framebuffer_state()`** runs in `retro_unserialize` after a
  successful load: `FrameBufferList::clearBuffers()` (LIST-ONLY — a full
  FrameBuffer_Destroy/Init re-runs the overscan/geometry init mid-session
  and mis-sizes the present), depth-list reset, resetCachedState, full
  gSP/gDP dirty. Purges stale pre-load framebuffers.
- **GLideN64 present**: `refreshDefaultFramebuffer()` re-queries the
  frontend FBO every present; `blitParams.invertY` pre-flips because
  `enableOverscan` is forced 0 on Apple (`custom/.../Config_mupenplus.cpp`)
  — RetroNest's blit assumes bottom-left-origin frames from every GL core.
  The overscan pass (and its core options) are therefore inert on macOS.
- `retro_unserialize` **returns false while the core is initializing**
  (clears in EmuThreadFunction's first frame); RetroNest retries across
  frames — do not "fix" the early return.

## Diagnostics gotchas

- `backtrace()` is useless on the libco coroutine stack (returns 1 frame).
- GL work runs on the worker thread via co_switch — same OS thread, same
  GL context as retro_run.
