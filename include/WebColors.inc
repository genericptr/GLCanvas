
{$ifdef INTERFACE}

// https://htmlcolorcodes.com/color-names/

type
  TWebColorHelper = record helper for TVec4
    class function Gold(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Yellow(alpha: TScalar = 1.0): TVec4; static; inline;
    class function LightYellow(alpha: TScalar = 1.0): TVec4; static; inline;
    class function LemonChiffon(alpha: TScalar = 1.0): TVec4; static; inline;
    class function LightGoldenrodYellow(alpha: TScalar = 1.0): TVec4; static; inline;
    class function PapayaWhip(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Moccasin(alpha: TScalar = 1.0): TVec4; static; inline;
    class function PeachPuff(alpha: TScalar = 1.0): TVec4; static; inline;
    class function PaleGoldenrod(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Khaki(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DarkKhaki(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Lavender(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Thistle(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Plum(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Violet(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Orchid(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Fuchsia(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Magenta(alpha: TScalar = 1.0): TVec4; static; inline;
    class function MediumOrchid(alpha: TScalar = 1.0): TVec4; static; inline;
    class function MediumPurple(alpha: TScalar = 1.0): TVec4; static; inline;
    class function RebeccaPurple(alpha: TScalar = 1.0): TVec4; static; inline;
    class function BlueViolet(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DarkViolet(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DarkOrchid(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DarkMagenta(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Purple(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Indigo(alpha: TScalar = 1.0): TVec4; static; inline;
    class function SlateBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DarkSlateBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function MediumSlateBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function GreenYellow(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Chartreuse(alpha: TScalar = 1.0): TVec4; static; inline;
    class function LawnGreen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Lime(alpha: TScalar = 1.0): TVec4; static; inline;
    class function LimeGreen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function PaleGreen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function LightGreen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function MediumSpringGreen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function SpringGreen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function MediumSeaGreen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function SeaGreen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function ForestGreen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Green(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DarkGreen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function YellowGreen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function OliveDrab(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Olive(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DarkOliveGreen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function MediumAquamarine(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DarkSeaGreen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function LightSeaGreen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DarkCyan(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Teal(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Aqua(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Cyan(alpha: TScalar = 1.0): TVec4; static; inline;
    class function LightCyan(alpha: TScalar = 1.0): TVec4; static; inline;
    class function PaleTurquoise(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Aquamarine(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Turquoise(alpha: TScalar = 1.0): TVec4; static; inline;
    class function MediumTurquoise(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DarkTurquoise(alpha: TScalar = 1.0): TVec4; static; inline;
    class function CadetBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function SteelBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function LightSteelBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function PowderBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function LightBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function SkyBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function LightSkyBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DeepSkyBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DodgerBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function CornflowerBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function RoyalBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Blue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function MediumBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DarkBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Navy(alpha: TScalar = 1.0): TVec4; static; inline;
    class function MidnightBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Cornsilk(alpha: TScalar = 1.0): TVec4; static; inline;
    class function BlanchedAlmond(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Bisque(alpha: TScalar = 1.0): TVec4; static; inline;
    class function NavajoWhite(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Wheat(alpha: TScalar = 1.0): TVec4; static; inline;
    class function BurlyWood(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Tan(alpha: TScalar = 1.0): TVec4; static; inline;
    class function RosyBrown(alpha: TScalar = 1.0): TVec4; static; inline;
    class function SandyBrown(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Goldenrod(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DarkGoldenrod(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Peru(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Chocolate(alpha: TScalar = 1.0): TVec4; static; inline;
    class function SaddleBrown(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Sienna(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Brown(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Maroon(alpha: TScalar = 1.0): TVec4; static; inline;
    class function White(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Snow(alpha: TScalar = 1.0): TVec4; static; inline;
    class function HoneyDew(alpha: TScalar = 1.0): TVec4; static; inline;
    class function MintCream(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Azure(alpha: TScalar = 1.0): TVec4; static; inline;
    class function AliceBlue(alpha: TScalar = 1.0): TVec4; static; inline;
    class function GhostWhite(alpha: TScalar = 1.0): TVec4; static; inline;
    class function WhiteSmoke(alpha: TScalar = 1.0): TVec4; static; inline;
    class function SeaShell(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Beige(alpha: TScalar = 1.0): TVec4; static; inline;
    class function OldLace(alpha: TScalar = 1.0): TVec4; static; inline;
    class function FloralWhite(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Ivory(alpha: TScalar = 1.0): TVec4; static; inline;
    class function AntiqueWhite(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Linen(alpha: TScalar = 1.0): TVec4; static; inline;
    class function LavenderBlush(alpha: TScalar = 1.0): TVec4; static; inline;
    class function MistyRose(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Gainsboro(alpha: TScalar = 1.0): TVec4; static; inline;
    class function LightGray(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Silver(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DarkGray(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Gray(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DimGray(alpha: TScalar = 1.0): TVec4; static; inline;
    class function LightSlateGray(alpha: TScalar = 1.0): TVec4; static; inline;
    class function SlateGray(alpha: TScalar = 1.0): TVec4; static; inline;
    class function DarkSlateGray(alpha: TScalar = 1.0): TVec4; static; inline;
    class function Black(alpha: TScalar = 1.0): TVec4; static; inline;
end;

{$endif}

{$ifdef IMPLEMENTATION}

class function TWebColorHelper.Gold(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 215 / 255, 0 / 255, alpha);
end;

class function TWebColorHelper.Yellow(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 255 / 255, 0 / 255, alpha);
end;

class function TWebColorHelper.LightYellow(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 255 / 255, 224 / 255, alpha);
end;

class function TWebColorHelper.LemonChiffon(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 250 / 255, 205 / 255, alpha);
end;

class function TWebColorHelper.LightGoldenrodYellow(alpha: TScalar): TVec4;
begin
  result := V4(250 / 255, 250 / 255, 210 / 255, alpha);
end;

class function TWebColorHelper.PapayaWhip(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 239 / 255, 213 / 255, alpha);
end;

class function TWebColorHelper.Moccasin(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 228 / 255, 181 / 255, alpha);
end;

class function TWebColorHelper.PeachPuff(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 218 / 255, 185 / 255, alpha);
end;

class function TWebColorHelper.PaleGoldenrod(alpha: TScalar): TVec4;
begin
  result := V4(238 / 255, 232 / 255, 170 / 255, alpha);
end;

class function TWebColorHelper.Khaki(alpha: TScalar): TVec4;
begin
  result := V4(240 / 255, 230 / 255, 140 / 255, alpha);
end;

class function TWebColorHelper.DarkKhaki(alpha: TScalar): TVec4;
begin
  result := V4(189 / 255, 183 / 255, 107 / 255, alpha);
end;

class function TWebColorHelper.Lavender(alpha: TScalar): TVec4;
begin
  result := V4(230 / 255, 230 / 255, 250 / 255, alpha);
end;

class function TWebColorHelper.Thistle(alpha: TScalar): TVec4;
begin
  result := V4(216 / 255, 191 / 255, 216 / 255, alpha);
end;

class function TWebColorHelper.Plum(alpha: TScalar): TVec4;
begin
  result := V4(221 / 255, 160 / 255, 221 / 255, alpha);
end;

class function TWebColorHelper.Violet(alpha: TScalar): TVec4;
begin
  result := V4(238 / 255, 130 / 255, 238 / 255, alpha);
end;

class function TWebColorHelper.Orchid(alpha: TScalar): TVec4;
begin
  result := V4(218 / 255, 112 / 255, 214 / 255, alpha);
end;

class function TWebColorHelper.Fuchsia(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 0 / 255, 255 / 255, alpha);
end;

class function TWebColorHelper.Magenta(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 0 / 255, 255 / 255, alpha);
end;

class function TWebColorHelper.MediumOrchid(alpha: TScalar): TVec4;
begin
  result := V4(186 / 255, 85 / 255, 211 / 255, alpha);
end;

class function TWebColorHelper.MediumPurple(alpha: TScalar): TVec4;
begin
  result := V4(147 / 255, 112 / 255, 219 / 255, alpha);
end;

class function TWebColorHelper.RebeccaPurple(alpha: TScalar): TVec4;
begin
  result := V4(102 / 255, 51 / 255, 153 / 255, alpha);
end;

class function TWebColorHelper.BlueViolet(alpha: TScalar): TVec4;
begin
  result := V4(138 / 255, 43 / 255, 226 / 255, alpha);
end;

class function TWebColorHelper.DarkViolet(alpha: TScalar): TVec4;
begin
  result := V4(148 / 255, 0 / 255, 211 / 255, alpha);
end;

class function TWebColorHelper.DarkOrchid(alpha: TScalar): TVec4;
begin
  result := V4(153 / 255, 50 / 255, 204 / 255, alpha);
end;

class function TWebColorHelper.DarkMagenta(alpha: TScalar): TVec4;
begin
  result := V4(139 / 255, 0 / 255, 139 / 255, alpha);
end;

class function TWebColorHelper.Purple(alpha: TScalar): TVec4;
begin
  result := V4(128 / 255, 0 / 255, 128 / 255, alpha);
end;

class function TWebColorHelper.Indigo(alpha: TScalar): TVec4;
begin
  result := V4(75 / 255, 0 / 255, 130 / 255, alpha);
end;

class function TWebColorHelper.SlateBlue(alpha: TScalar): TVec4;
begin
  result := V4(106 / 255, 90 / 255, 205 / 255, alpha);
end;

class function TWebColorHelper.DarkSlateBlue(alpha: TScalar): TVec4;
begin
  result := V4(72 / 255, 61 / 255, 139 / 255, alpha);
end;

class function TWebColorHelper.MediumSlateBlue(alpha: TScalar): TVec4;
begin
  result := V4(123 / 255, 104 / 255, 238 / 255, alpha);
end;

class function TWebColorHelper.GreenYellow(alpha: TScalar): TVec4;
begin
  result := V4(173 / 255, 255 / 255, 47 / 255, alpha);
end;

class function TWebColorHelper.Chartreuse(alpha: TScalar): TVec4;
begin
  result := V4(127 / 255, 255 / 255, 0 / 255, alpha);
end;

class function TWebColorHelper.LawnGreen(alpha: TScalar): TVec4;
begin
  result := V4(124 / 255, 252 / 255, 0 / 255, alpha);
end;

class function TWebColorHelper.Lime(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 255 / 255, 0 / 255, alpha);
end;

class function TWebColorHelper.LimeGreen(alpha: TScalar): TVec4;
begin
  result := V4(50 / 255, 205 / 255, 50 / 255, alpha);
end;

class function TWebColorHelper.PaleGreen(alpha: TScalar): TVec4;
begin
  result := V4(152 / 255, 251 / 255, 152 / 255, alpha);
end;

class function TWebColorHelper.LightGreen(alpha: TScalar): TVec4;
begin
  result := V4(144 / 255, 238 / 255, 144 / 255, alpha);
end;

class function TWebColorHelper.MediumSpringGreen(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 250 / 255, 154 / 255, alpha);
end;

class function TWebColorHelper.SpringGreen(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 255 / 255, 127 / 255, alpha);
end;

class function TWebColorHelper.MediumSeaGreen(alpha: TScalar): TVec4;
begin
  result := V4(60 / 255, 179 / 255, 113 / 255, alpha);
end;

class function TWebColorHelper.SeaGreen(alpha: TScalar): TVec4;
begin
  result := V4(46 / 255, 139 / 255, 87 / 255, alpha);
end;

class function TWebColorHelper.ForestGreen(alpha: TScalar): TVec4;
begin
  result := V4(34 / 255, 139 / 255, 34 / 255, alpha);
end;

class function TWebColorHelper.Green(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 128 / 255, 0 / 255, alpha);
end;

class function TWebColorHelper.DarkGreen(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 100 / 255, 0 / 255, alpha);
end;

class function TWebColorHelper.YellowGreen(alpha: TScalar): TVec4;
begin
  result := V4(154 / 255, 205 / 255, 50 / 255, alpha);
end;

class function TWebColorHelper.OliveDrab(alpha: TScalar): TVec4;
begin
  result := V4(107 / 255, 142 / 255, 35 / 255, alpha);
end;

class function TWebColorHelper.Olive(alpha: TScalar): TVec4;
begin
  result := V4(128 / 255, 128 / 255, 0 / 255, alpha);
end;

class function TWebColorHelper.DarkOliveGreen(alpha: TScalar): TVec4;
begin
  result := V4(85 / 255, 107 / 255, 47 / 255, alpha);
end;

class function TWebColorHelper.MediumAquamarine(alpha: TScalar): TVec4;
begin
  result := V4(102 / 255, 205 / 255, 170 / 255, alpha);
end;

class function TWebColorHelper.DarkSeaGreen(alpha: TScalar): TVec4;
begin
  result := V4(143 / 255, 188 / 255, 139 / 255, alpha);
end;

class function TWebColorHelper.LightSeaGreen(alpha: TScalar): TVec4;
begin
  result := V4(32 / 255, 178 / 255, 170 / 255, alpha);
end;

class function TWebColorHelper.DarkCyan(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 139 / 255, 139 / 255, alpha);
end;

class function TWebColorHelper.Teal(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 128 / 255, 128 / 255, alpha);
end;

class function TWebColorHelper.Aqua(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 255 / 255, 255 / 255, alpha);
end;

class function TWebColorHelper.Cyan(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 255 / 255, 255 / 255, alpha);
end;

class function TWebColorHelper.LightCyan(alpha: TScalar): TVec4;
begin
  result := V4(224 / 255, 255 / 255, 255 / 255, alpha);
end;

class function TWebColorHelper.PaleTurquoise(alpha: TScalar): TVec4;
begin
  result := V4(175 / 255, 238 / 255, 238 / 255, alpha);
end;

class function TWebColorHelper.Aquamarine(alpha: TScalar): TVec4;
begin
  result := V4(127 / 255, 255 / 255, 212 / 255, alpha);
end;

class function TWebColorHelper.Turquoise(alpha: TScalar): TVec4;
begin
  result := V4(64 / 255, 224 / 255, 208 / 255, alpha);
end;

class function TWebColorHelper.MediumTurquoise(alpha: TScalar): TVec4;
begin
  result := V4(72 / 255, 209 / 255, 204 / 255, alpha);
end;

class function TWebColorHelper.DarkTurquoise(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 206 / 255, 209 / 255, alpha);
end;

class function TWebColorHelper.CadetBlue(alpha: TScalar): TVec4;
begin
  result := V4(95 / 255, 158 / 255, 160 / 255, alpha);
end;

class function TWebColorHelper.SteelBlue(alpha: TScalar): TVec4;
begin
  result := V4(70 / 255, 130 / 255, 180 / 255, alpha);
end;

class function TWebColorHelper.LightSteelBlue(alpha: TScalar): TVec4;
begin
  result := V4(176 / 255, 196 / 255, 222 / 255, alpha);
end;

class function TWebColorHelper.PowderBlue(alpha: TScalar): TVec4;
begin
  result := V4(176 / 255, 224 / 255, 230 / 255, alpha);
end;

class function TWebColorHelper.LightBlue(alpha: TScalar): TVec4;
begin
  result := V4(173 / 255, 216 / 255, 230 / 255, alpha);
end;

class function TWebColorHelper.SkyBlue(alpha: TScalar): TVec4;
begin
  result := V4(135 / 255, 206 / 255, 235 / 255, alpha);
end;

class function TWebColorHelper.LightSkyBlue(alpha: TScalar): TVec4;
begin
  result := V4(135 / 255, 206 / 255, 250 / 255, alpha);
end;

class function TWebColorHelper.DeepSkyBlue(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 191 / 255, 255 / 255, alpha);
end;

class function TWebColorHelper.DodgerBlue(alpha: TScalar): TVec4;
begin
  result := V4(30 / 255, 144 / 255, 255 / 255, alpha);
end;

class function TWebColorHelper.CornflowerBlue(alpha: TScalar): TVec4;
begin
  result := V4(100 / 255, 149 / 255, 237 / 255, alpha);
end;

class function TWebColorHelper.RoyalBlue(alpha: TScalar): TVec4;
begin
  result := V4(65 / 255, 105 / 255, 225 / 255, alpha);
end;

class function TWebColorHelper.Blue(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 0 / 255, 255 / 255, alpha);
end;

class function TWebColorHelper.MediumBlue(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 0 / 255, 205 / 255, alpha);
end;

class function TWebColorHelper.DarkBlue(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 0 / 255, 139 / 255, alpha);
end;

class function TWebColorHelper.Navy(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 0 / 255, 128 / 255, alpha);
end;

class function TWebColorHelper.MidnightBlue(alpha: TScalar): TVec4;
begin
  result := V4(25 / 255, 25 / 255, 112 / 255, alpha);
end;

class function TWebColorHelper.Cornsilk(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 248 / 255, 220 / 255, alpha);
end;

class function TWebColorHelper.BlanchedAlmond(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 235 / 255, 205 / 255, alpha);
end;

class function TWebColorHelper.Bisque(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 228 / 255, 196 / 255, alpha);
end;

class function TWebColorHelper.NavajoWhite(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 222 / 255, 173 / 255, alpha);
end;

class function TWebColorHelper.Wheat(alpha: TScalar): TVec4;
begin
  result := V4(245 / 255, 222 / 255, 179 / 255, alpha);
end;

class function TWebColorHelper.BurlyWood(alpha: TScalar): TVec4;
begin
  result := V4(222 / 255, 184 / 255, 135 / 255, alpha);
end;

class function TWebColorHelper.Tan(alpha: TScalar): TVec4;
begin
  result := V4(210 / 255, 180 / 255, 140 / 255, alpha);
end;

class function TWebColorHelper.RosyBrown(alpha: TScalar): TVec4;
begin
  result := V4(188 / 255, 143 / 255, 143 / 255, alpha);
end;

class function TWebColorHelper.SandyBrown(alpha: TScalar): TVec4;
begin
  result := V4(244 / 255, 164 / 255, 96 / 255, alpha);
end;

class function TWebColorHelper.Goldenrod(alpha: TScalar): TVec4;
begin
  result := V4(218 / 255, 165 / 255, 32 / 255, alpha);
end;

class function TWebColorHelper.DarkGoldenrod(alpha: TScalar): TVec4;
begin
  result := V4(184 / 255, 134 / 255, 11 / 255, alpha);
end;

class function TWebColorHelper.Peru(alpha: TScalar): TVec4;
begin
  result := V4(205 / 255, 133 / 255, 63 / 255, alpha);
end;

class function TWebColorHelper.Chocolate(alpha: TScalar): TVec4;
begin
  result := V4(210 / 255, 105 / 255, 30 / 255, alpha);
end;

class function TWebColorHelper.SaddleBrown(alpha: TScalar): TVec4;
begin
  result := V4(139 / 255, 69 / 255, 19 / 255, alpha);
end;

class function TWebColorHelper.Sienna(alpha: TScalar): TVec4;
begin
  result := V4(160 / 255, 82 / 255, 45 / 255, alpha);
end;

class function TWebColorHelper.Brown(alpha: TScalar): TVec4;
begin
  result := V4(165 / 255, 42 / 255, 42 / 255, alpha);
end;

class function TWebColorHelper.Maroon(alpha: TScalar): TVec4;
begin
  result := V4(128 / 255, 0 / 255, 0 / 255, alpha);
end;

class function TWebColorHelper.White(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 255 / 255, 255 / 255, alpha);
end;

class function TWebColorHelper.Snow(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 250 / 255, 250 / 255, alpha);
end;

class function TWebColorHelper.HoneyDew(alpha: TScalar): TVec4;
begin
  result := V4(240 / 255, 255 / 255, 240 / 255, alpha);
end;

class function TWebColorHelper.MintCream(alpha: TScalar): TVec4;
begin
  result := V4(245 / 255, 255 / 255, 250 / 255, alpha);
end;

class function TWebColorHelper.Azure(alpha: TScalar): TVec4;
begin
  result := V4(240 / 255, 255 / 255, 255 / 255, alpha);
end;

class function TWebColorHelper.AliceBlue(alpha: TScalar): TVec4;
begin
  result := V4(240 / 255, 248 / 255, 255 / 255, alpha);
end;

class function TWebColorHelper.GhostWhite(alpha: TScalar): TVec4;
begin
  result := V4(248 / 255, 248 / 255, 255 / 255, alpha);
end;

class function TWebColorHelper.WhiteSmoke(alpha: TScalar): TVec4;
begin
  result := V4(245 / 255, 245 / 255, 245 / 255, alpha);
end;

class function TWebColorHelper.SeaShell(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 245 / 255, 238 / 255, alpha);
end;

class function TWebColorHelper.Beige(alpha: TScalar): TVec4;
begin
  result := V4(245 / 255, 245 / 255, 220 / 255, alpha);
end;

class function TWebColorHelper.OldLace(alpha: TScalar): TVec4;
begin
  result := V4(253 / 255, 245 / 255, 230 / 255, alpha);
end;

class function TWebColorHelper.FloralWhite(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 250 / 255, 240 / 255, alpha);
end;

class function TWebColorHelper.Ivory(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 255 / 255, 240 / 255, alpha);
end;

class function TWebColorHelper.AntiqueWhite(alpha: TScalar): TVec4;
begin
  result := V4(250 / 255, 235 / 255, 215 / 255, alpha);
end;

class function TWebColorHelper.Linen(alpha: TScalar): TVec4;
begin
  result := V4(250 / 255, 240 / 255, 230 / 255, alpha);
end;

class function TWebColorHelper.LavenderBlush(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 240 / 255, 245 / 255, alpha);
end;

class function TWebColorHelper.MistyRose(alpha: TScalar): TVec4;
begin
  result := V4(255 / 255, 228 / 255, 225 / 255, alpha);
end;

class function TWebColorHelper.Gainsboro(alpha: TScalar): TVec4;
begin
  result := V4(220 / 255, 220 / 255, 220 / 255, alpha);
end;

class function TWebColorHelper.LightGray(alpha: TScalar): TVec4;
begin
  result := V4(211 / 255, 211 / 255, 211 / 255, alpha);
end;

class function TWebColorHelper.Silver(alpha: TScalar): TVec4;
begin
  result := V4(192 / 255, 192 / 255, 192 / 255, alpha);
end;

class function TWebColorHelper.DarkGray(alpha: TScalar): TVec4;
begin
  result := V4(169 / 255, 169 / 255, 169 / 255, alpha);
end;

class function TWebColorHelper.Gray(alpha: TScalar): TVec4;
begin
  result := V4(128 / 255, 128 / 255, 128 / 255, alpha);
end;

class function TWebColorHelper.DimGray(alpha: TScalar): TVec4;
begin
  result := V4(105 / 255, 105 / 255, 105 / 255, alpha);
end;

class function TWebColorHelper.LightSlateGray(alpha: TScalar): TVec4;
begin
  result := V4(119 / 255, 136 / 255, 153 / 255, alpha);
end;

class function TWebColorHelper.SlateGray(alpha: TScalar): TVec4;
begin
  result := V4(112 / 255, 128 / 255, 144 / 255, alpha);
end;

class function TWebColorHelper.DarkSlateGray(alpha: TScalar): TVec4;
begin
  result := V4(47 / 255, 79 / 255, 79 / 255, alpha);
end;

class function TWebColorHelper.Black(alpha: TScalar): TVec4;
begin
  result := V4(0 / 255, 0 / 255, 0 / 255, alpha);
end;

{$endif}
