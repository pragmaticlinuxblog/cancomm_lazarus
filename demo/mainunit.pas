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
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
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
    CbbLen: TComboBox;
    EdtData1: TEdit;
    EdtData2: TEdit;
    EdtData3: TEdit;
    EdtData4: TEdit;
    EdtData5: TEdit;
    EdtData6: TEdit;
    EdtData7: TEdit;
    EdtId: TEdit;
    EdtData0: TEdit;
    GbxConnection: TGroupBox;
    GbxTransmit: TGroupBox;
    GbxLog: TGroupBox;
    LblId: TLabel;
    LblLen: TLabel;
    LblData: TLabel;
    MmoLog: TMemo;
    procedure BtnConnectClick(Sender: TObject);
    procedure BtnTransmitClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    CanSocket: TCanSocket;
    procedure PopulateDevices;
    procedure CanMsgTransmitted(Sender: TObject; constref Msg: TCanMsg);
    procedure CanMsgReceived(Sender: TObject; constref Msg: TCanMsg);
    procedure CanConnected(Sender: TObject);
    procedure CanDisconnected(Sender: TObject);
    procedure EditKeyPressHexOnly(Sender: TObject; var Key: Char);
    procedure VerifyTransmitInfo;
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
  // Create the CAN socket. Alternatively, you can add it to your form from the component
  // palette.
  CanSocket := TCanSocket.Create(Self);
  // Set the event handlers. If you added the TCanSocket to your form from the component
  // palette, you can also set the event handlers using the object inspector.
  CanSocket.OnTransmitted := @CanMsgTransmitted;
  CanSocket.OnReceived := @CanMsgReceived;
  CanSocket.OnConnected :=  @CanConnected;
  CanSocket.OnDisconnected := @CanDisconnected;
  // Set the key press event handlers to only allow input of hexadecimal characters.
  EdtId.OnKeyPress := @EditKeyPressHexOnly;
  EdtData0.OnKeyPress := @EditKeyPressHexOnly;
  EdtData1.OnKeyPress := @EditKeyPressHexOnly;
  EdtData2.OnKeyPress := @EditKeyPressHexOnly;
  EdtData3.OnKeyPress := @EditKeyPressHexOnly;
  EdtData4.OnKeyPress := @EditKeyPressHexOnly;
  EdtData5.OnKeyPress := @EditKeyPressHexOnly;
  EdtData6.OnKeyPress := @EditKeyPressHexOnly;
  EdtData7.OnKeyPress := @EditKeyPressHexOnly;
  // Refresh the devices in the combobox list.
  PopulateDevices;
end; //*** end of FormCreate ***


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
begin
  // Validate the entered transmit data on the user interface and correct it, if needed.
  VerifyTransmitInfo;
  // Attempt to automatically connect, if not yet connected.
  if not CanSocket.Connected then
  begin
    BtnConnectClick(Sender);
  end;
  // Only transmit if actually connected.
  if CanSocket.Connected then
  begin
    // Prepare the message.
    Msg.Id :=  StrToDWord('$' + EdtId.Text);
    Msg.Len := CbbLen.ItemIndex;
    Msg.Ext := False;
    Msg.Flags.Fd := False;
    Msg.Timestamp := 0;
    Msg.Data[0] := StrToDWord('$' + EdtData0.Text);
    Msg.Data[1] := StrToDWord('$' + EdtData1.Text);
    Msg.Data[2] := StrToDWord('$' + EdtData2.Text);
    Msg.Data[3] := StrToDWord('$' + EdtData3.Text);
    Msg.Data[4] := StrToDWord('$' + EdtData4.Text);
    Msg.Data[5] := StrToDWord('$' + EdtData5.Text);
    Msg.Data[6] := StrToDWord('$' + EdtData6.Text);
    Msg.Data[7] := StrToDWord('$' + EdtData7.Text);
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


//***************************************************************************************
// NAME:           EditKeyPressHexOnly
// PARAMETER:      Sender Source of the event.
//                 Key The key's character code that was pressed.
// DESCRIPTION:    Generic TEdit KeyPress handler allowing only hexadecimal numbers to be
//                 entered.
//
//***************************************************************************************
procedure TMainForm.EditKeyPressHexOnly(Sender: TObject; var Key: Char);
begin
  if not (Key In ['0'..'9', 'a'..'f', 'A'..'F', #8]) then // #8 = backspace
  begin
    // Ignore it
    Key := #0;
  end;
  // Convert a..f to upper case
  if Key In ['a'..'f'] then
  begin
    Key := UpCase(Key);
  end;
end; //*** end of EditKeyPressHexOnly ***


//***************************************************************************************
// NAME:           VerifyTransmitInfo
// DESCRIPTION:    Checks if the entered info for the transmit message is actually valid.
//                 If could for example happen that a user pasted a non-hex value into
//                 the Id or Data edit boxes.
//
//***************************************************************************************
procedure TMainForm.VerifyTransmitInfo;
var
  Value: LongWord;
begin
  // Convert the hexadecimal message identifier string to an unsigned integer.
  if not TryStrToDWord('$' + EdtId.Text, Value) then
  begin
    // Invalid hexadecimal value. Correct it.
    EdtId.Text := '7FF';
  end
  // Valid hexadecimal string. Now check its range.
  else
  begin
    if Value > $7FF then
    begin
      EdtId.Text := '7FF';
    end;
  end;

  // Convert the hexadecimal message data 0 string to an unsigned integer.
  if not TryStrToDWord('$' + EdtData0.Text, Value) then
  begin
    EdtData0.Text := '00';
  end;

  // Convert the hexadecimal message data 1 string to an unsigned integer.
  if not TryStrToDWord('$' + EdtData1.Text, Value) then
  begin
    EdtData1.Text := '00';
  end;

  // Convert the hexadecimal message data 2 string to an unsigned integer.
  if not TryStrToDWord('$' + EdtData2.Text, Value) then
  begin
    EdtData2.Text := '00';
  end;

  // Convert the hexadecimal message data 3 string to an unsigned integer.
  if not TryStrToDWord('$' + EdtData3.Text, Value) then
  begin
    EdtData3.Text := '00';
  end;

  // Convert the hexadecimal message data 4 string to an unsigned integer.
  if not TryStrToDWord('$' + EdtData4.Text, Value) then
  begin
    EdtData4.Text := '00';
  end;

  // Convert the hexadecimal message data 5 string to an unsigned integer.
  if not TryStrToDWord('$' + EdtData5.Text, Value) then
  begin
    EdtData5.Text := '00';
  end;

  // Convert the hexadecimal message data 6 string to an unsigned integer.
  if not TryStrToDWord('$' + EdtData6.Text, Value) then
  begin
    EdtData6.Text := '00';
  end;

  // Convert the hexadecimal message data 7 string to an unsigned integer.
  if not TryStrToDWord('$' + EdtData7.Text, Value) then
  begin
    EdtData7.Text := '00';
  end;

  // Set message identifier and data bytes to upper case.
  EdtId.Text := UpperCase(EdtId.Text);
  EdtData0.Text := UpperCase(EdtData0.Text);
  EdtData1.Text := UpperCase(EdtData1.Text);
  EdtData2.Text := UpperCase(EdtData2.Text);
  EdtData3.Text := UpperCase(EdtData3.Text);
  EdtData4.Text := UpperCase(EdtData4.Text);
  EdtData5.Text := UpperCase(EdtData5.Text);
  EdtData6.Text := UpperCase(EdtData6.Text);
  EdtData7.Text := UpperCase(EdtData7.Text);
end; //*** end of VerifyTransmitInfo ***


end.
//******************************** end of mainunit.pas **********************************

