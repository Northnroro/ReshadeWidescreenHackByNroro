# FakeResolution

## Problem This Tries To Fix

Some games can render to a `3840x1080` Full SBS-style window, but still calculate camera projection, UI layout, and aspect ratio as if `3840x1080` is one normal ultra-wide image. When viewed in Full SBS mode, that can make the game look horizontally squeezed or make the camera/UI logic feel wrong.

For XREAL Full SBS testing, the desired behavior is:

- the real window/backbuffer stays `3840x1080`
- the game logic thinks the window is `1920x1080`
- ReShade still receives a full `3840x1080` image for later effects

`FakeResolution` attempts that by reporting a logical `1920x1080` window size to the game, while preserving a physical `3840x1080` swapchain/backbuffer.

It does not generate SBS by itself. Use your ReShade SBS/depth effect after this add-on and shader.

## Supported Games

This build is not locked to one game. It loads in any game where ReShade loads the add-on.

It may work in other DXGI games that use normal window-size and swapchain paths, but it is not guaranteed. Different engines may calculate aspect ratio from internal settings, monitor modes, render-graph sizes, or cached startup values that this add-on cannot fully override.

Tested working example: Hogwarts Legacy DX12.

## Install

Install ReShade 6.7.3 with add-on support into the game you want to test.

Copy these two files next to the game executable:

```text
FakeResolution.addon64
FakeResolution.ini
```

Copy this shader to the game's ReShade shader folder:

```text
FakeResolutionStretch.fx
```

For Hogwarts Legacy, the exact add-on folder is:

```text
Hogwarts Legacy/Phoenix/Binaries/Win64/
```

For Hogwarts Legacy, the shader folder is:

```text
Hogwarts Legacy/Phoenix/Binaries/Win64/reshade-shaders/Shaders/
```

Hogwarts Legacy final layout:

```text
Hogwarts Legacy/Phoenix/Binaries/Win64/FakeResolution.addon64
Hogwarts Legacy/Phoenix/Binaries/Win64/FakeResolution.ini
Hogwarts Legacy/Phoenix/Binaries/Win64/reshade-shaders/Shaders/FakeResolutionStretch.fx
```

## Enable In Game

1. Start the game.
2. Open ReShade.
3. In the effect list, enable `FakeResolutionStretch`.
4. Put `FakeResolutionStretch` before SuperDepth3D or any SBS/depth effect.
5. Keep `Source Width Ratio` at `0.5` for `1920 -> 3840`.
6. Set the game output to the physical target size, for example `3840x1080`.
7. If the image does not update correctly, force the game to recreate or resize the swapchain:

```text
Change resolution to another value, apply it, then change back to 3840x1080.
```

If the game has display-mode options, toggling between windowed, borderless, and fullscreen can also force this refresh. Restart the game after replacing `FakeResolution.addon64` or changing `FakeResolution.ini`.

For the tested Hogwarts Legacy setup, use a `3840x1080` game window/output and let the add-on report `1920x1080` logic.


## Default Config

`FakeResolution.ini`:

```ini
[FakeResolution]
Enabled=1
FakeWidth=1920
FakeHeight=1080
TargetWidth=3840
TargetHeight=1080
HookWindowSize=1
HookIgnoreReShade=1
HookIgnoreGraphicsModules=1
HookOnlyMainModule=0
PromoteDepthStencil=0
PromoteDepthAspectWidth=1
MinPromoteDepthHeight=600
LogDepthResources=1
MaxDepthResourceLogs=128
MaxDepthUsageLogs=256
MaxViewportLogs=64
StartupResolutionNudge=1
```

Use these first. Restart the game after changing the INI.

## Startup Notice

The add-on is developed by u/nroro, the same developer as ScreenLab XR app. The app allows you to resize, recolor, VR360, and more!

- See resize demo: https://www.reddit.com/r/Xreal/comments/1r12rix/define_your_side_view_unroro_shader_app_v024/
- See VR360 demo: https://www.reddit.com/r/Xreal/comments/1t84y6c/vr360_for_xreal_glasses_try_it_now_screenlab_xr/
- Available now on Play Store: https://play.google.com/store/apps/details?id=com.northnroro.nroro_shader

### Problem: No Depth At All, Depth Map Is Solid Black

1. Open ReShade -> `Add-ons` -> `Generic Depth`.
2. Disable aspect-ratio heuristics/filtering.
3. Enable copy-depth-before-clear options if available.
4. Manually try depth buffers one by one, for example `S2D32`, `S1D32`, `S0D32`, `S2D24S8`, or similar scene-sized entries.
5. Use `DisplayDepth` or SuperDepth3D depth preview to check each one.
6. Pick the buffer that shows real scene depth and stays stable while moving.

The default build logs depth resources, but does not resize them:

```ini
PromoteDepthStencil=0
PromoteDepthAspectWidth=1
MinPromoteDepthHeight=600
```

Earlier test builds tried to widen dynamic 16:9 depth buffers, for example `1284x724 -> 2568x724`. That can make ReShade see a non-black depth image, but it also changes Unreal render-graph resource sizes and can cause cropped depth, broken rendering, or a crash.

Do not enable depth promotion unless you are deliberately testing that unsafe path:

```ini
PromoteDepthStencil=1
```

If the game render breaks or crashes, keep depth promotion disabled:

```ini
PromoteDepthStencil=0
```

If the depth view is still black or flat, confirm you copied the new INI from the release zip and restarted the game.

Also keep this enabled so the ReShade runtime does not receive the fake logical size:

```ini
HookIgnoreReShade=1
HookIgnoreGraphicsModules=1
```

Depth diagnostics are enabled by default and capped:

```ini
LogDepthResources=1
MaxDepthResourceLogs=128
MaxDepthUsageLogs=256
MaxViewportLogs=64
```

The log should show depth resources, depth views, depth clears/binds, and viewport sizes. If those entries do not appear, ReShade is not seeing depth resources through the add-on event path.

`PromoteDepthStencil=1` is experimental because changing game depth texture sizes can break ReShade depth detection or the game render path.

If the add-on stops affecting a game whose engine logic lives in a separate DLL, keep:

```ini
HookOnlyMainModule=0
```

Only set `HookOnlyMainModule=1` for debugging if the hook affects too much of the process.

After DisplayDepth shows a real non-black depth image, this ReShade global preprocessor definition may help only if the depth exists but is horizontally mapped wrong:

```text
RESHADE_DEPTH_INPUT_X_SCALE=2
```

## Disable

To disable the add-on behavior without deleting files:

```ini
Enabled=0
```

To disable only the depth experiment:

```ini
PromoteDepthStencil=0
```
