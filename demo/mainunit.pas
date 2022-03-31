unit MainUnit;
//***************************************************************************************
//  Description: Contains the main user interface for the demo application
//    File Name: mainunit.pas
//
//---------------------------------------------------------------------------------------
//                          C O P Y R I G H T
//---------------------------------------------------------------------------------------
//         Copyright (c) 2022 by PragmaticLinux     All rights reserved
//
//---------------------------------------------------------------------------------------
//                            L I C E N S E
//---------------------------------------------------------------------------------------
// This library is free software; you can redistribute it and/or  modify it under the
// terms of the GNU Library General Public License as published by the Free Software
// Foundation; either version 2 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE.  See the GNU Library General Public License for more details.
//
// You should have received a copy of the GNU Library General Public License along with
// this library; if not, write to the Free Software Foundation, Inc., 51 Franklin Street,
// Fifth Floor, Boston, MA  02110-1301  USA
//
//***************************************************************************************
{$IFDEF FPC}
{$MODE objfpc}{$H+}
{$ENDIF}

interface
//***************************************************************************************
// Includes
//***************************************************************************************
uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  CanDriver, CanMsg;


//***************************************************************************************
// Type Definitions
//***************************************************************************************
type
  { TMainForm }
  TMainForm = class(TForm)
    BtnConnect: TButton;
    BtnDisconnect: TButton;
    BtnList: TButton;
    BtnTransmit: TButton;
    MmoLog: TMemo;
    RxTimer: TTimer;
    procedure BtnConnectClick(Sender: TObject);
    procedure BtnDisconnectClick(Sender: TObject);
    procedure BtnListClick(Sender: TObject);
    procedure BtnTransmitClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure RxTimerTimer(Sender: TObject);
  private
    FCanDriver: TCanDriver;
  public

  end;


//***************************************************************************************
// Global Variables
//***************************************************************************************
var
  MainForm: TMainForm;


implementation

{$R *.lfm}

//---------------------------------------------------------------------------------------
//-------------------------------- TMainForm --------------------------------------------
//---------------------------------------------------------------------------------------
//***************************************************************************************
// NAME:           FormCreate
// PARAMETER:      Sender Source of the event.
// RETURN VALUE:   none
// DESCRIPTION:    Form constructor.
//
//***************************************************************************************
procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCanDriver := TCanDriver.Create(Self);
  FCanDriver.Device := 'vcan0';
end; //*** end of FormCreate ***


//***************************************************************************************
// NAME:           BtnConnectClick
// PARAMETER:      Sender Source of the event.
// RETURN VALUE:   none
// DESCRIPTION:    Button click event handler.
//
//***************************************************************************************
procedure TMainForm.BtnConnectClick(Sender: TObject);
begin
  if FCanDriver.Connect then
  begin
    RxTimer.Enabled := True;
    MmoLog.Lines.Add('Connected to CAN device');
  end
  else
  begin
    MmoLog.Lines.Add('[ERROR] Could not connect to CAN device');
  end;
end; //*** end of BtnConnectClick ***


//***************************************************************************************
// NAME:           BtnDisconnectClick
// PARAMETER:      Sender Source of the event.
// RETURN VALUE:   none
// DESCRIPTION:    Button click event handler.
//
//***************************************************************************************
procedure TMainForm.BtnDisconnectClick(Sender: TObject);
begin
  FCanDriver.Disconnect;
  RxTimer.Enabled := False;
  MmoLog.Lines.Add('Disconnected from CAN device');
end; //*** end of BtnDisconnectClick ***


//***************************************************************************************
// NAME:           BtnListClick
// PARAMETER:      Sender Source of the event.
// RETURN VALUE:   none
// DESCRIPTION:    Button click event handler.
//
//***************************************************************************************
procedure TMainForm.BtnListClick(Sender: TObject);
{var
  DeviceCount: Byte;
  DeviceIndex: Byte;
  DeviceName: PAnsiChar; }
begin
  {DeviceCount := CanCommDevicesBuildList(FCanContext);
  MmoLog.Lines.Add(Format('Number of CAN devices: %d',[DeviceCount]));
  for DeviceIndex := 1 to DeviceCount do
  begin
    DeviceName := CanCommDevicesName(FCanContext, DeviceIndex - 1);
    MmoLog.Lines.Add(Format('Device %d: %s',[DeviceIndex, StrPas(DeviceName)]));
  end; }
end; //*** end of BtnListClick ***


//***************************************************************************************
// NAME:           BtnTransmitClick
// PARAMETER:      Sender Source of the event.
// RETURN VALUE:   none
// DESCRIPTION:    Button click event handler.
//
//***************************************************************************************
procedure TMainForm.BtnTransmitClick(Sender: TObject);
var
  Msg: TCanMsg;
  Idx: Integer;
begin
  // Prepare the message.
  Msg.Id := $123;
  Msg.Ext := False;
  Msg.Len := 8;
  Msg.Flags.Fd := False;
  Msg.Timestamp := 0;
  for Idx := 0 to Msg.Len - 1 do
  begin
    Msg.Data[Idx] := Idx + 1;
  end;
  // Transmit the message.
  if FCanDriver.Transmit(Msg) then
  begin
    MmoLog.Lines.Add('Transmitted CAN message');
  end
  else
  begin
    MmoLog.Lines.Add('[ERROR] Could not transmit CAN message');
  end;
end; //*** end of BtnTransmitClick ***


//***************************************************************************************
// NAME:           FormDestroy
// PARAMETER:      Sender Source of the event.
// RETURN VALUE:   none
// DESCRIPTION:    Form destructor.
//
//***************************************************************************************
procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FCanDriver.Free;
end; //*** end of FormDestroy ***


//***************************************************************************************
// NAME:           RxTimerTimer
// PARAMETER:      Sender Source of the event.
// RETURN VALUE:   none
// DESCRIPTION:    Timer event handler.
//
//***************************************************************************************
procedure TMainForm.RxTimerTimer(Sender: TObject);
{var
  Id: LongWord;
  Ext: Byte;
  Len: Byte;
  Data: Array [0..63] of Byte;
  Flags: Byte;
  Timestamp: QWord;
  LogStr: String;}
begin
  {if (CanCommReceive(FCanContext, @Id, @Ext, @Len, @Data[0], @Flags, @Timestamp)) = CANCOMM_TRUE then
  begin
    LogStr := Format('Id %xh Len %d Data %.2x %.2x %.2x %.2x %.2x %.2x %.2x %.2x',
        [Id, Len, Data[0], Data[1], Data[2], Data[3], Data[4], Data[5], Data[6], Data[7]]);
    MmoLog.Lines.Add('Received CAN message: ' + LogStr);
  end; }
end; //*** end of RxTimerTimer ***/

end.
//******************************** end of mainunit.pas **********************************

