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
    BtnTransmit: TButton;
    CbbDevices: TComboBox;
    GbxConnection: TGroupBox;
    GbxTransmit: TGroupBox;
    GbxLog: TGroupBox;
    MmoLog: TMemo;
    procedure BtnConnectClick(Sender: TObject);
    procedure BtnTransmitClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    CanSocket: TCanSocket;
    procedure PopulateDevices;
    procedure CanMsgTransmitted(Sender: TObject; constref Msg: TCanMsg);
    procedure CanMsgReceived(Sender: TObject; constref Msg: TCanMsg);
    procedure CanConnected(Sender: TObject);
    procedure CanDisconnected(Sender: TObject);
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
  // Create CAN socket.
  CanSocket := TCanSocket.Create(Self);
  // Set the event handlers.
  CanSocket.OnTransmitted := @CanMsgTransmitted;
  CanSocket.OnReceived := @CanMsgReceived;
  CanSocket.OnConnected :=  @CanConnected;
  CanSocket.OnDisconnected := @CanDisconnected;
  // Refresh the devices in the combobox list.
  PopulateDevices;
end; //*** end of FormCreate ***


//***************************************************************************************
// NAME:           FormDestroy
// PARAMETER:      Sender Source of the event.
// DESCRIPTION:    Form destructor.
//
//***************************************************************************************
procedure TMainForm.FormDestroy(Sender: TObject);
begin
  CanSocket.Free;
end; //*** end of FormDestroy ***


//***************************************************************************************
// NAME:           PopulateDevices
// PARAMETER:      Sender Source of the event.
// DESCRIPTION:    Refreshes the items in the device combobox.
//
//***************************************************************************************
procedure TMainForm.PopulateDevices;
var
  DeviceIndex: Integer;
begin
  // Clear the list.
  CbbDevices.Items.Clear;
  // No SocketCAN devices detected on the system?
  if CanSocket.Devices.Count = 0 then
  begin
    // Add a dummy one.
    CbbDevices.Items.Add('vcan0');
  end
  // One or more SocketCAN device(s) detected on the system.
  else
  begin
    // Loop through all detected devices.
    for DeviceIndex := 0 to CanSocket.Devices.Count - 1 do
    begin
      // Add the device to the list.
      CbbDevices.Items.Add(CanSocket.Devices[DeviceIndex]);
    end;
  end;
  // Select the first one.
  CbbDevices.ItemIndex := 0;
end; //*** end of PopulateDevices ***


//***************************************************************************************
// NAME:           BtnConnectClick
// PARAMETER:      Sender Source of the event.
// DESCRIPTION:    Button click event handler.
//
//***************************************************************************************
procedure TMainForm.BtnConnectClick(Sender: TObject);
begin
  // Currently not connected?
  if not CanSocket.Connected then
  begin
    // Configure the device based on the combobox selection.
    CanSocket.Device := CbbDevices.Text;
    // Connect to the CAN socket.
    if not CanSocket.Connect then
    begin
      MmoLog.Lines.Add('[ERROR] Could not connect to CAN device');
    end;
  end
  // Currently connected.
  else
  begin
    // Disconnect from the CAN socket.
    CanSocket.Disconnect;
  end;
end; //*** end of BtnConnectClick ***


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
  // Only transmit if actually connected.
  if CanSocket.Connected then
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
    if not CanSocket.Transmit(Msg) then
    begin
      MmoLog.Lines.Add('[ERROR] Could not transmit CAN message');
    end;
  end;
end; //*** end of BtnTransmitClick ***


//***************************************************************************************
// NAME:           CanMsgTransmitted
// PARAMETER:      Sender Source of the event.
//                 Msg CAN message.
// DESCRIPTION:    CAN message transmitted event handler.
//
//***************************************************************************************
procedure TMainForm.CanMsgTransmitted(Sender: TObject; constref Msg: TCanMsg);
begin
  // Show the CAN message in the log.
  MmoLog.Lines.Add(CanSocket.FormatMsg(Msg));
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
  // Show the CAN message in the log.
  MmoLog.Lines.Add(CanSocket.FormatMsg(Msg));
end; //*** end of CanMsgReceived ***


//***************************************************************************************
// NAME:           CanConnected
// PARAMETER:      Sender Source of the event.
// DESCRIPTION:    CAN connected event handler.
//
//***************************************************************************************
procedure TMainForm.CanConnected(Sender: TObject);
begin
  // Update the user interface.
  BtnConnect.Caption := 'Disconnect';
  CbbDevices.Enabled := False;
  MmoLog.Lines.Add(Format('Connected to CAN device %s', [CanSocket.Device]));
end; //*** end of CanConnected ***


//***************************************************************************************
// NAME:           CanDisconnected
// PARAMETER:      Sender Source of the event.
// DESCRIPTION:    CAN disconnected event handler.
//
//***************************************************************************************
procedure TMainForm.CanDisconnected(Sender: TObject);
begin
  // Update the user interface.
  BtnConnect.Caption := 'Connect';
  CbbDevices.Enabled := True;
  MmoLog.Lines.Add(Format('Disconnected from CAN device %s', [CanSocket.Device]));
end; //*** end of CanDisconnected ***


end.
//******************************** end of mainunit.pas **********************************

