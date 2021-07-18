
{$ifdef INTERFACE}

function FRand: single;
function FRand(min, max: single): single;
function FRand(min, max: single; decimal: integer): single;
function Rand(min, max: longint): longint;
function Rand(max: longint): longint;
function RandBool(probability: single = 0.5): boolean;
function GetTicks: longint;
function GetTime: double;

{$endif}

{$ifdef IMPLEMENTATION}

function GetTicks: longint;
begin
  {$ifdef PLATFORM_SDL}
  result := SDL_GetTicks;
  {$endif}
  {$ifdef PLATFORM_GLPT}
  result := round(GLPT_GetTime * 1000);
  {$endif}
end;

function GetTime: double;
begin
  {$ifdef PLATFORM_SDL}
  result := SDL_GetTicks / 1000;
  {$endif}
  {$ifdef PLATFORM_GLPT}
  result := GLPT_GetTime;
  {$endif}
end;

{ Returns a number larger or equal to 'min' and less than or equal to 'max'. }

function FRand(min, max: single): single;
begin
  result := FRand(min, max, 100);
end;

function FRand(min, max: single; decimal: integer): single;
begin
  result := Rand(trunc(min * decimal), trunc(max * decimal)) / decimal;
end;

{ Returns a real number between 0 and 1 is returned (0 included, 1 excluded). }
function FRand: single;
begin
  result := System.Random;
end;

{ Returns a random number larger or equal to 0 and strictly less than 'max'.  }
function Rand(max: longint): longint;
begin
  result := System.Random(max);
end;

{ Returns a number larger or equal to 'min' and less than or equal to 'max'. }
function Rand(min, max: longint): longint;
var
  zero: boolean = false;
begin
  Assert(max >= 0, 'Rand max ('+IntToStr(max)+') is negative.');

  if min = 0 then 
    begin
      //Fatal('GetRandomNumber 0 min value is invalid.');
      min += 1;
      max += 1;
      zero := true;
    end;
    
  if (min < 0) and (max > 0) then
    max += abs(min);
  
  result := System.Random(max) mod ((max - min) + 1);
  
  if result < 0 then
    result := abs(result);
    
  if zero then
    min -= 1;
  result += min;
end;

function RandBool(probability: single = 0.5): boolean;
begin
  result := System.Random >= probability;
end;

{$endif}
