unit netmapclasses;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, netaddrutils;

type
  TCgnatNetmap = class(TCollectionItem)
  private
    FValidPrefix: Boolean;
    FValidPrivateNw: Boolean;
    FValidPublicNw: Boolean;
    FValidDivision: Boolean;
    FIntPrivateNw: UInt32;
    FIntPublicNw: UInt32;

    FPrefix: Integer;
    FPrivateNw: String;
    FPublicNw: String;
    FDivision: Integer;

    procedure SetPrefix(Value: Integer);
    procedure SetPrivateNw(Value: String);
    procedure SetPublicNw(Value: String);
    procedure SetDivision(Value: Integer);

    procedure Recalculate;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;

    procedure Change(APrefix: Integer; APrivateNw, APublicNw: String; ADivision: Integer);

    property Prefix: Integer read FPrefix write SetPrefix;
    property PrivateNw: String read FPrivateNw write SetPrivateNw;
    property PublicNw: String read FPublicNw write SetPublicNw;
    property Division: Integer read FDivision write SetDivision;

    property IntPrivateNw: UInt32 read FIntPrivateNw;
    property IntPublicNw: UInt32 read FIntPublicNw;
  end;

  TCgnatNetmapList = class(TCollection)
  private
    function GetItem(Index: Integer): TCgnatNetmap;
    procedure SetItem(Index: Integer; Value: TCgnatNetmap);
  public
    constructor Create;
    destructor Destroy; override;

    function Add: TCgnatNetmap;
    function Add(APrefix: Integer; APrivateNw, APublicNw: String; ADivision: Integer): TCgnatNetmap;
    function Insert(Index: Integer): TCgnatNetmap;

    property Items[Index: Integer]: TCgnatNetmap read GetItem write SetItem; default;
  end;

implementation

{ TCgnatNetmap }

constructor TCgnatNetmap.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);

  FPrefix := 27;
  FPrivateNw := '0.0.0.0';
  FPublicNw := '0.0.0.0';
  FDivision := 32;
end;

destructor TCgnatNetmap.Destroy;
begin
  inherited Destroy;
end;

procedure TCgnatNetmap.SetPrefix(Value: Integer);
begin
  FPrefix := Value;
  Recalculate;
end;

procedure TCgnatNetmap.SetPrivateNw(Value: String);
begin
  FPrivateNw := Value;
  Recalculate;
end;

procedure TCgnatNetmap.SetPublicNw(Value: String);
begin
  FPublicNw := Value;
  Recalculate;
end;

procedure TCgnatNetmap.SetDivision(Value: Integer);
begin
  FDivision := Value;
  Recalculate;
end;

procedure TCgnatNetmap.Change(APrefix: Integer; APrivateNw, APublicNw: String; ADivision: Integer);
begin
  FPrefix    := APrefix;
  FPrivateNw := APrivateNw;
  FPublicNw  := APublicNw;
  FDivision  := ADivision;
  Recalculate;
end;

procedure TCgnatNetmap.Recalculate;
begin
  FValidPrefix    := (FPrefix >= 22) and (FPrefix <= 30);
  FValidPrivateNw := AddressToInt(FPrivateNw, FIntPrivateNw);
  FValidPublicNw  := AddressToInt(FPublicNw, FIntPublicNw);
  FValidDivision  := (FDivision >= 2) and (FDivision <= 64);

  FIntPrivateNw   := IntAddrToIntNetwork(FIntPrivateNw, FPrefix);
  FIntPublicNw    := IntAddrToIntNetwork(FIntPublicNw, FPrefix);

  if FValidPrefix and FValidPrivateNw then
    FPrivateNw := IntToAddress(FIntPrivateNw);
  if FValidPrefix and FValidPublicNw then
    FPublicNw := IntToAddress(FIntPublicNw);
end;

{ TCgnatNetmapList }

constructor TCgnatNetmapList.Create;
begin
  inherited Create(TCgnatNetmap);
end;

destructor TCgnatNetmapList.Destroy;
begin
  inherited Destroy;
end;

function TCgnatNetmapList.Add: TCgnatNetmap;
begin
  Result := TCgnatNetmap(inherited Add);
end;

function TCgnatNetmapList.Add(APrefix: Integer; APrivateNw, APublicNw: String; ADivision: Integer): TCgnatNetmap;
begin
  Result := TCgnatNetmap(inherited Add);
  Result.FPrefix := APrefix;
  Result.FPrivateNw := APrivateNw;
  Result.FPublicNw := APublicNw;
  Result.FDivision := ADivision;
  Result.Recalculate;
end;

function TCgnatNetmapList.Insert(Index: Integer): TCgnatNetmap;
begin
  Result := TCgnatNetmap(inherited Insert(Index));
end;

function TCgnatNetmapList.GetItem(Index: Integer): TCgnatNetmap;
begin
  Result := TCgnatNetmap(inherited GetItem(Index));
end;

procedure TCgnatNetmapList.SetItem(Index: Integer; Value: TCgnatNetmap);
begin
  inherited SetItem(Index, Value);
end;

end.

