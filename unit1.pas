unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  Buttons, ExtCtrls, netmapclasses, netaddrutils, IniFiles, math, LazUTF8;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    Bevel1: TBevel;
    Bt_Add: TButton;
    Bt_Change: TButton;
    Bt_Summary: TButton;
    Bt_Remove: TButton;
    Bt_Generate: TButton;
    Bt_SearchPrivateCalc: TButton;
    Bt_SearchPublicCalc: TButton;
    Bt_Save: TButton;
    Ed_IfaceValue: TEdit;
    Ed_IfaceRule: TComboBox;
    Ed_SummaryTo: TEdit;
    Ed_SearchPublicPort: TEdit;
    Ed_SearchPrivate: TEdit;
    Ed_Profile: TComboBox;
    Ed_Prefix: TComboBox;
    Ed_Division: TComboBox;
    Ed_Private: TEdit;
    Ed_Public: TEdit;
    Ed_SearchPublic: TEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Lb_Lines: TLabel;
    Lb_Private1: TLabel;
    Lb_Public1: TLabel;
    Lb_Public2: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Lb_Private: TLabel;
    Lb_Private2: TLabel;
    Lb_Public: TLabel;
    Lv_Items: TListView;
    Ed_Script: TMemo;
    Bt_ProfileSave: TSpeedButton;
    Bt_ProfileRemove: TSpeedButton;
    SaveDialog: TSaveDialog;
    procedure Bt_AddClick(Sender: TObject);
    procedure Bt_ChangeClick(Sender: TObject);
    procedure Bt_GenerateClick(Sender: TObject);
    procedure Bt_ProfileRemoveClick(Sender: TObject);
    procedure Bt_ProfileSaveClick(Sender: TObject);
    procedure Bt_RemoveClick(Sender: TObject);
    procedure Bt_SearchPrivateCalcClick(Sender: TObject);
    procedure Bt_SearchPublicCalcClick(Sender: TObject);
    procedure Bt_SummaryClick(Sender: TObject);
    procedure Bt_SaveClick(Sender: TObject);
    procedure Ed_ProfileChange(Sender: TObject);
    procedure Ed_SearchPrivateKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Ed_SearchPublicKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Lv_ItemsClick(Sender: TObject);
  private
    Ini: TIniFile;
    Netmaps: TCgnatNetmapList;
    function IndexOfProfile(const S: String): Integer;
  public
    procedure RefreshItem(Item: TListItem);
    procedure Sumerize;
    procedure ReadIni;
    procedure ReadIniProfile(Profile: String);
    procedure WriteIni;
    procedure WriteIniProfile(Profile: String);
  end;

const
  CPrefix: array[0..8] of Integer = (22, 23, 24, 25, 26, 27, 28, 29, 30);

var
  frmMain: TfrmMain;
  AppDir: String;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  AppDir := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));
  Ini := TIniFile.Create(AppDir + 'netmap.ini');

  Netmaps := TCgnatNetmapList.Create;

  ReadIni;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  WriteIni;
  Ini.Free;
end;

procedure TfrmMain.Lv_ItemsClick(Sender: TObject);
begin
  Bt_Change.Enabled := Lv_Items.Selected <> nil;
  Bt_Remove.Enabled := Lv_Items.Selected <> nil;

  Sumerize;
end;

procedure TfrmMain.ReadIni;
var
  Profile: String;
begin
  Ed_Profile.Items.StrictDelimiter := True;
  Ed_Profile.Items.CommaText := Ini.ReadString('Profiles', 'Names', '');

  if Ini.SectionExists(Ed_Profile.Text) then
    Profile := Ed_Profile.Text
  else
    Profile := '';

  ReadIniProfile(Profile);
end;

procedure TfrmMain.ReadIniProfile(Profile: String);
var
  I: Integer;
  ValueExists: Boolean;
  Netmap: TCgnatNetmap;
  Item: TListItem;
  IfaceRule, IfaceValue: String;
begin
  if Profile = '' then
    Profile := 'Netmaps'
  else
    Profile := 'profile-' {%H-}+ Profile;

  IfaceRule := Ini.ReadString(Profile, 'IfaceRule', '');
  IfaceValue := Ini.ReadString(Profile, 'IfaceValue', '');

  I := Ed_IfaceRule.Items.IndexOf(IfaceRule);
  if I >= 0 then
    Ed_IfaceRule.ItemIndex := I
  else
    Ed_IfaceRule.ItemIndex := 0;
  Ed_IfaceValue.Text := IfaceValue;

  Lv_Items.Items.Clear;
  Netmaps.Clear;
  I := 0;
  repeat
    ValueExists := Ini.ValueExists(Profile, 'Prefix' + IntToStr(I));
    if ValueExists then begin
      Netmap := Netmaps.Add(
        Ini.ReadInteger(Profile, 'Prefix' + IntToStr(I), 27),
        Ini.ReadString(Profile, 'Private' + IntToStr(I), '0.0.0.0'),
        Ini.ReadString(Profile, 'Public' + IntToStr(I), '0.0.0.0'),
        Ini.ReadInteger(Profile, 'Division' + IntToStr(I), 32)
      );

      Item := Lv_Items.Items.Add;
      Item.Data := Netmap;
      RefreshItem(Item);
    end;

    Inc(I);
  until not ValueExists;
end;

procedure TfrmMain.WriteIni;
begin
  Ini.WriteString('Profiles', 'Names', Ed_Profile.Items.CommaText);

  WriteIniProfile(Ed_Profile.Text);
end;

procedure TfrmMain.WriteIniProfile(Profile: String);
var
  I: Integer;
  Netmap: TCgnatNetmap;
  IfaceRule: String;
begin
  if Profile = '' then
    Profile := 'Netmaps'
  else
    Profile := 'profile-' {%H-}+ Profile;

  Ini.EraseSection(Profile);

  if Ed_IfaceRule.ItemIndex = 0 then
    IfaceRule := ''
  else
    IfaceRule := Ed_IfaceRule.Text;
  Ini.WriteString(Profile, 'IfaceRule', IfaceRule);
  Ini.WriteString(Profile, 'IfaceValue', Ed_IfaceValue.Text);

  for I := 0 to Netmaps.Count - 1 do begin
    Netmap := Netmaps[I];
    Ini.WriteInteger(Profile, 'Prefix' + IntToStr(I), Netmap.Prefix);
    Ini.WriteString(Profile, 'Private' + IntToStr(I), Netmap.PrivateNw);
    Ini.WriteString(Profile, 'Public' + IntToStr(I), Netmap.PublicNw);
    Ini.WriteInteger(Profile, 'Division' + IntToStr(I), Netmap.Division);
  end;
end;

procedure TfrmMain.Bt_AddClick(Sender: TObject);
var
  Netmap: TCgnatNetmap;
  Prefix, Division: Integer;
  Item: TListItem;
begin
  if IsAddress(Ed_Private.Text) and IsAddress(Ed_Public.Text) then begin
    Prefix := CPrefix[Ed_Prefix.ItemIndex];
    Division := Ed_Division.ItemIndex + 2;
    Netmap := Netmaps.Add(Prefix, Ed_Private.Text, Ed_Public.Text, Division);

    if Ed_Profile.Text = '' then
      WriteIniProfile('');

    Item := Lv_Items.Items.Add;
    Item.Data := Netmap;
    RefreshItem(Item);
  end;
end;

procedure TfrmMain.RefreshItem(Item: TListItem);
var
  Netmap: TCgnatNetmap;
  PortsPerIP: Integer;
begin
  Netmap := TCgnatNetmap(Item.Data);

  PortsPerIP := (65536-1025) div Netmap.Division;
  //FirstPort := 65536 - (PortsPerIP * Division);

  Item.Caption := Netmap.PrivateNw;
  if Item.SubItems.Count <= 0 then
    Item.SubItems.Add(Netmap.PublicNw)
  else
    Item.SubItems[0] := Netmap.PublicNw;

  if Item.SubItems.Count <= 1 then
     Item.SubItems.Add('/' + IntToStr(Netmap.Prefix))
  else
    Item.SubItems[1] := '/' + IntToStr(Netmap.Prefix);

  if Item.SubItems.Count <= 2 then
    Item.SubItems.Add(IntToStr(Netmap.Division))
  else
    Item.SubItems[2] := IntToStr(Netmap.Division);

  if Item.SubItems.Count <= 3 then
    Item.SubItems.Add(IntToStr(PortsPerIP))
  else
    Item.SubItems[3] := IntToStr(PortsPerIP);
end;

procedure TfrmMain.Bt_ChangeClick(Sender: TObject);
var
  Item: TListItem;
  Netmap: TCgnatNetmap;
  Prefix, Division: Integer;
begin
  Item := Lv_Items.Selected;
  if Item <> nil then begin
    Prefix := CPrefix[Ed_Prefix.ItemIndex];
    Division := Ed_Division.ItemIndex + 2;

    Netmap := TCgnatNetmap(Item.Data);
    Netmap.Change(
      Prefix,
      Ed_Private.Text,
      Ed_Public.Text,
      Division
    );

    if Ed_Profile.Text = '' then
      WriteIniProfile('');

    RefreshItem(Item);
    Sumerize;
  end;
end;

procedure TfrmMain.Bt_GenerateClick(Sender: TObject);
var
  nI, dI, Nws, Addrs, PortsPerIP, RulePort: Integer;
  Netmap: TCgnatNetmap;
  PrivAddr: UInt32;
  Cmd: String;
begin
  Ed_Script.Lines.BeginUpdate;
  try
    Ed_Script.Lines.Clear;

    for nI := 0 to Netmaps.Count - 1 do begin
      Netmap := Netmaps[nI];
      Nws := Trunc(intpower(2, 32 - Netmap.Prefix) * Netmap.Division);

      case Ed_IfaceRule.ItemIndex of
        1:
          Cmd := Format('/ip firewall nat add chain=srcnat src-address=%s-%s out-interface=%s action=jump jump-target=cgnat%d comment=cgnat', [Netmap.PrivateNw, IntToAddress(Netmap.IntPrivateNw + Nws - 1), Ed_IfaceValue.Text, nI + 1]);
        2:
          Cmd := Format('/ip firewall nat add chain=srcnat src-address=%s-%s out-interface-list=%s action=jump jump-target=cgnat%d comment=cgnat', [Netmap.PrivateNw, IntToAddress(Netmap.IntPrivateNw + Nws - 1), Ed_IfaceValue.Text, nI + 1]);
        else
          Cmd := Format('/ip firewall nat add chain=srcnat src-address=%s-%s action=jump jump-target=cgnat%d comment=cgnat', [Netmap.PrivateNw, IntToAddress(Netmap.IntPrivateNw + Nws - 1), nI + 1]);
      end;

      Ed_Script.Lines.Add(Cmd);
    end;

    for nI := 0 to Netmaps.Count - 1 do begin
      Netmap := Netmaps[nI];

      Addrs := Trunc(intpower(2, 32 - Netmap.Prefix));

      PortsPerIP := (65536-1025) div Netmap.Division;
      RulePort := 65536 - (PortsPerIP * Netmap.Division);

      PrivAddr := Netmap.IntPrivateNw;
      for dI := 1 to Netmap.Division do begin
        Ed_Script.Lines.Add(Format('/ip firewall nat add chain=cgnat%d protocol=icmp src-address=%s/%d action=netmap to-addresses=%s/%d comment=cgnat', [nI+1, IntToAddress(PrivAddr), Netmap.Prefix, Netmap.PublicNw, Netmap.Prefix, RulePort, RulePort + PortsPerIP - 1]));
        Ed_Script.Lines.Add(Format('/ip firewall nat add chain=cgnat%d protocol=tcp src-address=%s/%d action=netmap to-addresses=%s/%d to-ports=%d-%d comment=cgnat', [nI+1, IntToAddress(PrivAddr), Netmap.Prefix, Netmap.PublicNw, Netmap.Prefix, RulePort, RulePort + PortsPerIP - 1]));
        Ed_Script.Lines.Add(Format('/ip firewall nat add chain=cgnat%d protocol=udp src-address=%s/%d action=netmap to-addresses=%s/%d to-ports=%d-%d comment=cgnat', [nI+1, IntToAddress(PrivAddr), Netmap.Prefix, Netmap.PublicNw, Netmap.Prefix, RulePort, RulePort + PortsPerIP - 1]));

        PrivAddr := PrivAddr + Addrs;
        RulePort := RulePort + PortsPerIP;
      end;
    end;

    Lb_Lines.Caption := IntToStr(Ed_Script.Lines.Count) + ' linha(s)';
  finally
    Ed_Script.Lines.EndUpdate;
  end;
end;

procedure TfrmMain.Bt_ProfileRemoveClick(Sender: TObject);
var
  IO: Integer;
begin
  IO := IndexOfProfile(Ed_Profile.Text);
  if IO >= 0 then begin
    Ini.EraseSection('profile-' + Ed_Profile.Text);
    Ed_Profile.Items.Delete(IO);
    Ed_Profile.Text := '';
    ReadIniProfile('');
  end;
end;

procedure TfrmMain.Bt_ProfileSaveClick(Sender: TObject);
var
  IO: Integer;
  Profile: String;
begin
  Profile := Ed_Profile.Text;

  if Pos(',', Profile) > 0 then
    MessageDlg('', 'Não é permitido utilizar vírgulas (",") no nome do perfil.', mtWarning, [mbOk], 0)
  else begin
    WriteIniProfile(Profile);

    if Profile <> '' then begin
      IO := IndexOfProfile(Profile);
      if IO < 0 then
        Ed_Profile.Items.Add(Profile);
    end;
  end;
end;

procedure TfrmMain.Bt_RemoveClick(Sender: TObject);
var
  Item: TListItem;
  Netmap: TCgnatNetmap;
begin
  Item := Lv_Items.Selected;
  if Item <> nil then begin
    Netmap := TCgnatNetmap(Item.Data);
    Item.Free;
    Netmap.Free;

    if Ed_Profile.Text = '' then
      WriteIniProfile('');

    Bt_Change.Enabled := False;
    Bt_Remove.Enabled := False;
  end;
end;

procedure TfrmMain.Bt_SearchPrivateCalcClick(Sender: TObject);
var
  nI, dI, Addrs, Diff: Integer;
  Netmap: TCgnatNetmap;
  Addr, PrivAddr, LastAddr: UInt32;
begin
  Ed_Script.Lines.BeginUpdate;
  try
    Ed_Script.Lines.Clear;
    Lb_Lines.Caption := '';

    Addr := 0;
    if AddressToInt(Ed_SearchPrivate.Text, Addr) then begin
      for nI := 0 to Netmaps.Count - 1 do begin
        Netmap := Netmaps[nI];
        Addrs := Trunc(intpower(2, 32 - Netmap.Prefix));
        PrivAddr := Netmap.IntPrivateNw;
        for dI := 1 to Netmap.Division do begin
          LastAddr := PrivAddr + Addrs - 1;

          if (Addr >= PrivAddr) and (Addr <= LastAddr) then begin
            Diff := Addr - PrivAddr;

            Ed_Script.Lines.Add('Encontrado na regra: ' + IntToStr(nI + 1));
            Ed_Script.Lines.Add('Endereço de rede privado da regra: ' + IntToAddress(PrivAddr) + '/' + IntToStr(Netmap.Prefix));
            Ed_Script.Lines.Add('Diferença do host até o endereço: ' + IntToStr(Diff));
            Ed_Script.Lines.Add('Endereço de rede público da regra: ' + Netmap.PublicNw + '/' + IntToStr(Netmap.Prefix));
            Ed_Script.Lines.Add('Endereço público do netmap: ' + IntToAddress(Netmap.IntPublicNw + Diff));
          end;

          PrivAddr := PrivAddr + Addrs;
        end;
      end;
    end;
  finally
    Ed_Script.Lines.EndUpdate;
  end;
end;

procedure TfrmMain.Bt_SearchPublicCalcClick(Sender: TObject);
var
  nI, dI, Port, Addrs, Diff, PortsPerIP, RulePort: Integer;
  Netmap: TCgnatNetmap;
  Addr, LastAddr: UInt32;
  FoundRule, FoundPort: Boolean;
begin
  Ed_Script.Lines.BeginUpdate;
  try
    Ed_Script.Lines.Clear;
    Lb_Lines.Caption := '';

    FoundRule := False;
    FoundPort := False;

    Port := StrToInt(Ed_SearchPublicPort.Text);
    Addr := 0;
    if AddressToInt(Ed_SearchPublic.Text, Addr) then begin
      for nI := 0 to Netmaps.Count - 1 do begin
        Netmap := Netmaps[nI];
        Addrs := Trunc(intpower(2, 32 - Netmap.Prefix));
        LastAddr := Netmap.IntPublicNw + Addrs - 1;

        PortsPerIP := (65536-1025) div Netmap.Division;
        RulePort := 65536 - (PortsPerIP * Netmap.Division);

        if (Addr >= Netmap.IntPublicNw) and (Addr <= LastAddr) then begin
          FoundRule := True;
          Diff := Addr - Netmap.IntPublicNw;
          Ed_Script.Lines.Add('Encontrado na regra: ' + IntToStr(nI + 1));
          Ed_Script.Lines.Add('Endereço de rede público da regra: ' + Netmap.PublicNw + '/' + IntToStr(Netmap.Prefix));
          Ed_Script.Lines.Add('Diferença do host até o endereço: ' + IntToStr(Diff));

          for dI := 1 to Netmap.Division do begin
            if (Port >= RulePort) and (Port < RulePort + PortsPerIP) then  begin
              FoundPort := True;
              Ed_Script.Lines.Add('Endereço de rede privado da regra: ' + IntToAddress(Netmap.IntPrivateNw + ((dI-1) * Addrs)) + '/' + IntToStr(Netmap.Prefix));
              Ed_Script.Lines.Add('Endereço privado do netmap: ' + IntToAddress(Netmap.IntPrivateNw + ((dI-1) * Addrs + Diff)));
              Break;
            end;
            RulePort := RulePort + PortsPerIP;
          end;

          Break;
        end;
      end;

      if not FoundRule then
        Ed_Script.Lines.Add('─► Não encontrado o endereço dentro das redes públicas configuradas.');
      if not FoundPort then
        Ed_Script.Lines.Add('─► Porta fora do(s) range(s) utilizado(s).');
    end;
  finally
    Ed_Script.Lines.EndUpdate;
  end;
end;

procedure TfrmMain.Bt_SummaryClick(Sender: TObject);
var
  nI, dI, sI, Addrs, SummTo, Rest, LenS, PortsPerIP, RulePort: Integer;
  Netmap: TCgnatNetmap;
  PrivAddr: UInt32;
  S: String;
begin
  Ed_Script.Lines.BeginUpdate;
  try
    Ed_Script.Lines.Clear;
    Lb_Lines.Caption := '';

    SummTo := StrToInt(Ed_SummaryTo.Text);

    for nI := 0 to Netmaps.Count - 1 do begin
      Netmap := Netmaps[nI];
      Ed_Script.Lines.Add(Format('%s/%d', [Netmap.PublicNw, Netmap.Prefix]));

      Addrs := Trunc(intpower(2, 32 - Netmap.Prefix));
      PrivAddr := Netmap.IntPrivateNw;
      for dI := 1 to Netmap.Division do begin
        S := Format('  %s/%d', [IntToAddress(PrivAddr), Netmap.Prefix]);

        for sI := 1 to (Netmap.Prefix - SummTo) do begin
          LenS := UTF8Length(S);
          S := S + StringOfChar(' ', (22 * sI) + ((sI - 1) * 3) - LenS);

          Rest := (dI-1) mod Trunc(intpower(2, sI));
          if Rest = 0 then
            S := S + '◄─┬─► ' + IntToAddress(PrivAddr) + '/' + IntToStr(Netmap.Prefix - sI)
          else if Rest = Trunc(intpower(2, si)) - 1 then
            S := S + '◄─┘'
          else
            S := S + '  │';
        end;

        Ed_Script.Lines.Add(S);

        PrivAddr := PrivAddr + Addrs;
      end;

      // *** Resumo das portas
      Ed_Script.Lines.Add('');
      Ed_Script.Lines.Add('*** Tabela das portas utilizadas no NAT ***');
      PortsPerIP := (65536-1025) div Netmap.Division;
      RulePort := 65536 - (PortsPerIP * Netmap.Division);

      for dI := 1 to Netmap.Division do begin
        Ed_Script.Lines.Add(Format('Regra %d : %d -> %d', [dI, RulePort, RulePort + PortsPerIP]));

        PrivAddr := PrivAddr + Addrs;
        RulePort := RulePort + PortsPerIP;
      end;
      // ***

      if nI < Netmaps.Count - 1 then
        Ed_Script.Lines.Add('');
    end;
  finally
    Ed_Script.Lines.EndUpdate;
  end;
end;

procedure TfrmMain.Bt_SaveClick(Sender: TObject);
var
  FileName: String;
begin
  if SaveDialog.Execute then begin
    FileName := SaveDialog.FileName;;
    if (Pos('.', ExtractFileName(FileName)) = 0) and (SaveDialog.FilterIndex = 0) then
      FileName := FileName + '.rsc';

    if not FileExists(FileName) or (MessageDlg('Salvar', 'Arquivo de destino já existente. Sobreescrever?', mtWarning, [mbYes, mbNo], 0) = mrYes) then begin
      Ed_Script.Lines.SaveToFile(FileName);
    end;
  end;
end;

procedure TfrmMain.Ed_ProfileChange(Sender: TObject);
var
  IO: Integer;
begin
  IO := IndexOfProfile(Ed_Profile.Text);
  if (IO >= 0) or (Ed_Profile.Text = '') then begin
    ReadIniProfile(Ed_Profile.Text);
  end;
end;

procedure TfrmMain.Ed_SearchPrivateKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 13 then
    Bt_SearchPrivateCalc.Click;
end;

procedure TfrmMain.Ed_SearchPublicKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 13 then
    Bt_SearchPublicCalc.Click;
end;

procedure TfrmMain.Sumerize;
var
  Item: TListItem;
  Netmap: TCgnatNetmap;
  Nws: Integer;
begin
  Item := Lv_Items.Selected;
  if Item <> nil then begin
    Netmap := TCgnatNetmap(Item.Data);

    Ed_Private.Text := Netmap.PrivateNw;
    Ed_Public.Text := Netmap.PublicNw;
    Ed_Prefix.ItemIndex := Netmap.Prefix - 22;
    Ed_Division.ItemIndex := Netmap.Division - 2;

    Nws := Trunc(intpower(2, 32 - Netmap.Prefix) * Netmap.Division);

    Lb_Private1.Caption := Netmap.PrivateNw;
    Lb_Private2.Caption := IntToAddress(Netmap.IntPrivateNw + Nws - 1);

    Lb_Public1.Caption := Netmap.PublicNw;
    Lb_Public2.Caption := IntToAddress(Netmap.IntPublicNw + Trunc(intpower(2, 32 - Netmap.Prefix)) - 1);
  end;
end;

function TfrmMain.IndexOfProfile(const S: String): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Ed_Profile.Items.Count - 1 do begin
    if AnsiCompareText(S, Ed_Profile.Items[I]) = 0 then begin
      Result := I;
      Break;
    end;
  end;
end;

end.

