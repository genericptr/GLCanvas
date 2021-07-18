# GLCanvas - Minimalistic rendering library

GLCanvas provides a minimalistic rendering API in the same vein as [raylib](https://www.raylib.com) or [libGDX](https://libgdx.badlogicgames.com).

A simple program with GLCanvas:

```pascal
program Test;
uses
  CThreads, GeometryTypes, GLCanvas, GLPT;
const
  window_size_width = 600;
  window_size_height = 600;
var
  texture: TTexture;
begin
  SetupCanvas(window_size_width, window_size_height);
  texture := TTexture.Create('deer.png');
  while IsRunning do
    begin
      ClearBackground;
      DrawTexture(texture, RectMake(50, 50, texture.GetSize));
      SwapBuffers;
    end;
  QuitApp;
end.
```

### Features:

 - Flat procedural API
 - Standard vector types and matrix math
 - Texture loading (only supports PNG format currently)
 - Bitmap and Freetype fonts
 - Shaders (optional)
 - Frame buffers (optional)
 - GLUI for many common UI elements like windows, buttons etc...

### Platforms:

 - [GLPT](https://github.com/genericptr/GLPT) enable using `-dPLATFORM_GLPT` (GLPT is the default platform)
 - [SDL](https://github.com/libsdl-org/SDL) enable using `-dPLATFORM_SDL`