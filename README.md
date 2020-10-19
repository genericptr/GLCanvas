# GLCanvas - Minimalistic drawing library

GLCanvas provides a minimalistic drawing API in the same vein as [raylib](https://www.raylib.com) or [libGDX](https://libgdx.badlogicgames.com).

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

 - Flat procedural API like
 - Standard vector types and matrix math
 - Texture loading
 - Bitmap and Freetype fonts
 - Shaders (optional)
 - Frame buffers (optional)
 - GLGUI for many common UI elements like windows, buttons etc...

### ⛓ Dependancies:

 - [GLPT](https://github.com/genericptr/GLPT) for the platform layer.