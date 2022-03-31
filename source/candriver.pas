unit CanDriver;
//***************************************************************************************
//  Description: CAN driver unit.
//    File Name: candriver.pas
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
// Global Includes
//***************************************************************************************
uses
  Classes, SysUtils, CanComm, CanMsg;


//***************************************************************************************
// Type definitions
//***************************************************************************************
type
  //---------------------------------- TCanMsgReceivedEvent -----------------------------
  TCanMsgReceivedEvent = procedure(Sender: TObject; Msg: TCanMsg) of object;

  //---------------------------------- TCanErrFrameReceivedEvent ------------------------
  TCanErrFrameReceivedEvent = procedure(Sender: TObject) of object;

  //---------------------------------- TCanDriver ---------------------------------------
  TCanDriver = class(TComponent)
  // TODO Maybe add something to get the detected devices as a list somehow.
  // TODO Implement reception thread. Should probably be a separate class.
  // TODO Implement register function and figure out how to add an icon.
  private
    { Private declarations }
  protected
    { Protected declarations }
    FCanContext: TCanComm;
    FConnected : Boolean;
    FDevice: String;
    FOnMsgReceived: TCanMsgReceivedEvent;
    FOnErrFrameReceived: TCanErrFrameReceivedEvent;
    procedure SetDevice(Value: String);
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    function    Connect: Boolean;
    procedure   Disconnect;
    function    Transmit(Msg: TCanMsg): Boolean;
    { Public properties }
    property    Device: String read FDevice write SetDevice;
    property    Connected: Boolean read FConnected;
    property    OnMsgReceived: TCanMsgReceivedEvent read FOnMsgReceived write FOnMsgReceived;
    property    OnErrFrameReceived: TCanErrFrameReceivedEvent read FOnErrFrameReceived write FOnErrFrameReceived;
end;


implementation
//---------------------------------------------------------------------------------------
//-------------------------------- TCanDriver -------------------------------------------
//---------------------------------------------------------------------------------------
//***************************************************************************************
// NAME:           Create
// DESCRIPTION:    Component constructor. Calls TComponents's constructor and initializes
//                 the fields their default values.
//
//***************************************************************************************
constructor TCanDriver.Create(AOwner: TComponent);
begin
  // Call inherited constructor
  inherited Create(AOwner);
  // Initialize fields.
  FConnected := False;
  FOnMsgReceived := nil;
  FOnErrFrameReceived := nil;
  // Create the CAN communication context.
  FCanContext := CanCommNew;
  // Make sure the context could be created.
  if FCanContext = nil then
  begin
    raise Exception.Create('Could not create CAN communication context');
  end;
end; //*** end of Create ***


//***************************************************************************************
// NAME:           Destroy
// PARAMETER:      none
// RETURN VALUE:   none
// DESCRIPTION:    Component destructor. Calls TComponent's destructor
//
//***************************************************************************************
destructor TCanDriver.Destroy;
begin
  // Make sure to disconnect.
  Disconnect;
  // Release the CAN communication context.
  if (FCanContext <> nil) then
  begin
    CanCommFree(FCanContext);
  end;
  // Call inherited destructor
  inherited Destroy;
end; //*** end of Destroy ***


//***************************************************************************************
// NAME:           SetDevice
// PARAMETER:      Value The device name, e.g. 'can0', 'vcan0', etc.
// RETURN VALUE:   none
// DESCRIPTION:    Sets the CAN device name. Automatically reconnects if needed.
//
//***************************************************************************************
procedure TCanDriver.SetDevice(Value: String);
var
  WasConnected: Boolean;
begin
  // Only continue with a valid context.
  if FCanContext <> nil then
  begin
    // Store the current connection state.
    WasConnected := FConnected;
    // Make sure to disconnect before changing the device name.
    if FConnected then
    begin
      Disconnect;
    end;
    // Store the new device name.
    FDevice := Value;
    // Reconnect if needed.
    if WasConnected then
    begin
      Connect;
    end;
  end;
end; //*** end of SetDevice ***


//***************************************************************************************
// NAME:           Connect
// RETURN VALUE:   True if successfully connected, False otherwise.
// DESCRIPTION:    Connects the device to the CAN bus.
//
//***************************************************************************************
function TCanDriver.Connect: Boolean;
begin
  // Initialize the result.
  Result := False;
  // Only continue with a valid context.
  if FCanContext <> nil then
  begin
    // Make sure to disconnect first.
    if FConnected then
    begin
      Disconnect;
    end;
    // Attemp to connect.
    if CanCommConnect(FCanContext, PAnsiChar(AnsiString(FDevice))) = CANCOMM_TRUE then
    begin
      FConnected := True;
      Result := True;
    end;
  end;
end; //*** end of Connect ***


//***************************************************************************************
// NAME:           Disconnect
// DESCRIPTION:    Disconnects the device from the CAN bus.
//
//***************************************************************************************
procedure TCanDriver.Disconnect;
begin
  // Only continue with a valid context.
  if FCanContext <> nil then
  begin
    // Only disconnect if actually connected.
    if FConnected then
    begin
      CanCommDisconnect(FCanContext);
      FConnected := False;
    end;
  end;
end; //*** end of Disconnect ***


//***************************************************************************************
// NAME:           Transmit
// PARAMETER:      msg Message to transmit.
// RETURN VALUE:   True if successful, False otherwise.
// DESCRIPTION:    Submits a CAN message for transmission.
//
//***************************************************************************************
function TCanDriver.Transmit(Msg: TCanMsg): Boolean;
var
  Ext: Byte;
  Flags: Byte;
begin
  // Initialize the result.
  Result := False;

  // Only continue with a valid context and when connected
  if (FCanContext <> nil) and FConnected then
  begin
    // Convert those parts of the CAN message that have a different type.
    Ext := CANCOMM_FALSE;
    if Msg.Ext then
    begin
      Ext := CANCOMM_TRUE;
    end;
    Flags := 0;
    if Msg.Flags.Fd then
    begin
      Flags := Flags or CANCOMM_FLAG_CANFD_MSG;
    end;
    // Attempt to submit the message for transmission on the CAN bus.
    if CanCommTransmit(FCanContext, Msg.Id, Ext, Msg.Len, @Msg.Data[0], Flags,
                       @Msg.Timestamp) = CANCOMM_TRUE then
    begin
      Result := True;
    end;
  end;
end; //*** end of Transmit ***


end.
//******************************** end of candriver.pas *********************************

