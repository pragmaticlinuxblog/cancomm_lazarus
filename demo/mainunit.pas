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
// Global includes
//***************************************************************************************
uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, CanSocket;


//***************************************************************************************
// Type definitions
//***************************************************************************************
type
  { TMainForm }
  TMainForm = class(TForm)
    BtnConnect: TButton;
    BtnDisconnect: TButton;
    BtnList: TButton;
    BtnTransmit: TButton;
    MmoLog: TMemo;
    procedure BtnConnectClick(Sender: TObject);
    procedure BtnDisconnectClick(Sender: TObject);
    procedure BtnListClick(Sender: TObject);
    procedure BtnTransmitClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure CanMsgTransmitted(Sender: TObject; constref Msg: TCanMsg);
    procedure CanMsgReceived(Sender: TObject; constref Msg: TCanMsg);
    procedure CanConnected(Sender: TObject);
    procedure CanDisconnected(Sender: TObject);
  private
    FCanSocket: TCanSocket;
  public

  end;


//***************************************************************************************
// Global variable declarations
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
// DESCRIPTION:    Form constructor.
//
//***************************************************************************************
procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCanSocket := TCanSocket.Create(Self);
  FCanSocket.OnTransmitted := @CanMsgTransmitted;
  FCanSocket.OnReceived := @CanMsgReceived;
  FCanSocket.OnConnected :=  @CanConnected;
  FCanSocket.OnDisconnected := @CanDisconnected;
end; //*** end of FormCreate ***


//***************************************************************************************
// NAME:           BtnConnectClick
// PARAMETER:      Sender Source of the event.
// DESCRIPTION:    Button click event handler.
//
//***************************************************************************************
procedure TMainForm.BtnConnectClick(Sender: TObject);
begin
  FCanSocket.Device := FCanSocket.Devices[0];
  if not FCanSocket.Connect then
  begin
    MmoLog.Lines.Add('[ERROR] Could not connect to CAN device');
  end;
end; //*** end of BtnConnectClick ***


//***************************************************************************************
// NAME:           BtnDisconnectClick
// PARAMETER:      Sender Source of the event.
// DESCRIPTION:    Button click event handler.
//
//***************************************************************************************
procedure TMainForm.BtnDisconnectClick(Sender: TObject);
begin
  FCanSocket.Disconnect;
end; //*** end of BtnDisconnectClick ***


//***************************************************************************************
// NAME:           BtnListClick
// PARAMETER:      Sender Source of the event.
// DESCRIPTION:    Button click event handler.
//
//***************************************************************************************
procedure TMainForm.BtnListClick(Sender: TObject);
var
  DeviceIndex: Integer;
  DeviceStr: string;
begin
  if FCanSocket.Devices.Count = 0 then
  begin
    DeviceStr := 'No CAN devices detected';
  end
  else
  begin
    DeviceStr := 'Detected CAN devices:';
    for DeviceIndex := 0 to FCanSocket.Devices.Count - 1 do
    begin
      DeviceStr := DeviceStr + (Format(' %s', [FCanSocket.Devices[DeviceIndex]]));
    end;
  end;
  MmoLog.Lines.Add(DeviceStr);
end; //*** end of BtnListClick ***


//***************************************************************************************
// NAME:           BtnTransmitClick
// PARAMETER:      Sender Source of the event.
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
  if not FCanSocket.Transmit(Msg) then
  begin
    MmoLog.Lines.Add('[ERROR] Could not transmit CAN message');
  end;
end; //*** end of BtnTransmitClick ***


//***************************************************************************************
// NAME:           FormDestroy
// PARAMETER:      Sender Source of the event.
// DESCRIPTION:    Form destructor.
//
//***************************************************************************************
procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FCanSocket.Free;
end; //*** end of FormDestroy ***


//***************************************************************************************
// NAME:           CanMsgTransmitted
// PARAMETER:      Sender Source of the event.
//                 Msg CAN message.
// DESCRIPTION:    CAN message transmitted event handler.
//
//***************************************************************************************
procedure TMainForm.CanMsgTransmitted(Sender: TObject; constref Msg: TCanMsg);
begin
  MmoLog.Lines.Add(FCanSocket.FormatMsg(Msg));
end; //*** end of CanMsgTransmitted ***


//***************************************************************************************
// NAME:           CanMsgReceived
// PARAMETER:      Sender Source of the event.
//                 Msg CAN message.
// DESCRIPTION:    CAN message reception event handler.
//
//***************************************************************************************
procedure TMainForm.CanMsgReceived(Sender: TObject; constref Msg: TCanMsg);
begin
  MmoLog.Lines.Add(FCanSocket.FormatMsg(Msg));
end; //*** end of CanMsgReceived ***


//***************************************************************************************
// NAME:           CanConnected
// PARAMETER:      Sender Source of the event.
// DESCRIPTION:    CAN connected event handler.
//
//***************************************************************************************
procedure TMainForm.CanConnected(Sender: TObject);
begin
  MmoLog.Lines.Add(Format('Connected to CAN device %s', [FCanSocket.Device]));
end; //*** end of CanConnected ***


//***************************************************************************************
// NAME:           CanDisconnected
// PARAMETER:      Sender Source of the event.
// DESCRIPTION:    CAN disconnected event handler.
//
//***************************************************************************************
procedure TMainForm.CanDisconnected(Sender: TObject);
begin
  MmoLog.Lines.Add(Format('Disconnected from CAN device %s', [FCanSocket.Device]));
end; //*** end of CanDisconnected ***


end.
//******************************** end of mainunit.pas **********************************

