unit netaddrutils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, character, Math;

type
  TAddrOctets = array[0..3] of Byte;

function IsInteger(Value: String): Boolean;
function IsAddress(Address: String): Boolean;
function AddressToOctets(Address: String; var Octets: TAddrOctets): Boolean;
function OctetsToInt(Octets: TAddrOctets): UInt32;
function AddressToInt(Address: String; var Int: UInt32): Boolean;
function IntToAddress(Int: UInt32): String;
function IntAddrToIntNetwork(IntAddr: UInt32; Prefix: Integer): UInt32;

implementation

function IsInteger(Value: String): Boolean;
var
  I: Integer;
begin
  Result := Length(Value) > 0;

  for I := 1 to Length(Value) do begin
    if not IsNumber(Value[I]) then begin
      Result := False;
      Exit;
    end;
  end;
end;

function IsAddress(Address: String): Boolean;
var
  Octets: TAddrOctets;
begin
  Octets[0] := 0;
  Result := AddressToOctets(Address, Octets);
end;

function AddressToOctets(Address: String; var Octets: TAddrOctets): Boolean;
var
  OctetN, CharPos: Integer;
  S: String;
begin
  Result := False;

  OctetN := 0;
  CharPos := Pos('.', Address);
  while (CharPos > 0) do begin
    S := Copy(Address, 1, CharPos - 1);
    Delete(Address, 1, CharPos);

    if IsInteger(S) and (OctetN <= 3) then
      Octets[OctetN] := StrToInt(S)
    else
      Exit;

    CharPos := Pos('.', Address);
    if (CharPos = 0) and (Length(Address) > 0) then
      CharPos := Length(Address) + 1;
    Inc(OctetN);
  end;

  Result := (OctetN = 4) and (Address = '');
end;

function OctetsToInt(Octets: TAddrOctets): UInt32;
begin
  Result := (Octets[0] * 16777216) + (Octets[1] * 65536) + (Octets[2] * 256) + Octets[3];
end;

function AddressToInt(Address: String; var Int: UInt32): Boolean;
var
  Octets: TAddrOctets;
begin
  Octets[0] := 0;
  FillChar(Octets, SizeOf(TAddrOctets), 0);
  Result := AddressToOctets(Address, Octets);
  if Result then
    Int := OctetsToInt(Octets);
end;

function IntToAddress(Int: UInt32): String;
begin
  Result := Format('%d.%d.%d.%d', [hi(hi(Int)), lo(hi(Int)), hi(lo(Int)), lo(lo(Int))]);
end;

function IntAddrToIntNetwork(IntAddr: UInt32; Prefix: Integer): UInt32;
begin
  Result := IntAddr and Trunc(intpower(2, 32) - intpower(2, 32 - Prefix));
end;

end.

