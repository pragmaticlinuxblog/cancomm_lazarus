unit CanSocket;
//***************************************************************************************
//  Description: CAN socket unit.
//    File Name: cansocket.pas
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
  Classes, SysUtils, LResources, CanComm, CanDevices;


//***************************************************************************************
// Global constant declarations
//***************************************************************************************
const
  // Maximum number of data bytes for a CAN classic message.
  CANMSG_CLASSIC_MAX_DATA_LEN = 8;
  // Maximum number of data bytes for a CAN FD message.
  CANMSG_FD_MAX_DATA_LEN = 64;


//***************************************************************************************
// Type definitions
//***************************************************************************************
type
  //---------------------------------- TCanMsg ------------------------------------------
  // Type that groups CAN message related information.
  PCanMsg = ^TCanMsg;
  TCanMsg = packed record
    Id: LongWord;        // Message identifier
    Ext: Boolean;        // False for 11-bit identifier, True for 29-bit identifier
    Len: Byte;           // Number of data bytes in the message
    Data: array [0..(CANMSG_FD_MAX_DATA_LEN-1)] of Byte; // Data bytes
    Flags : bitpacked record
      Fd: Boolean;       // False for CAN classic, True for CAN FD frame
      Err: Boolean;      // False for CAN data frame, True for CAN error frame
    end;
    Timestamp: QWord;    // Message timestamp
  end;

  //---------------------------------- TCanMsgReceivedEvent -----------------------------
  // Event handler type for CAN message reception.
  TCanMsgReceivedEvent = procedure(Sender: TObject; constref Msg: TCanMsg) of object;

  //---------------------------------- TCanErrFrameReceivedEvent ------------------------
  // Event handler type for CAN error frame reception.
  TCanErrFrameReceivedEvent = procedure(Sender: TObject) of object;

  //---------------------------------- TCanSocket ---------------------------------------
  TCanSocket = class(TComponent)
  private
    type
      TCanThread = class(TThread)
      private
        FParent: TCanSocket;
      protected
        procedure   Execute; override;
      public
        constructor Create(AParent: TCanSocket);
        property    Parent: TCanSocket read FParent;
      end;
  private
    FCanDevices: TCanDevices;
    FOnMsgReceived: TCanMsgReceivedEvent;
    FOnErrFrameReceived: TCanErrFrameReceivedEvent;
    FDevice: string;
    FEventThread: TCanThread;
    procedure   SetDevice(Value: string);
  protected
    FCanContext: TCanComm;
    FConnected : Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    function    Connect: Boolean; virtual;
    procedure   Disconnect; virtual;
    function    Transmit(var Msg: TCanMsg): Boolean; virtual;
    property    Connected: Boolean read FConnected;
    property    Devices: TCanDevices read FCanDevices;
  published
    property    Device: string read FDevice write SetDevice;
    property    OnMessage: TCanMsgReceivedEvent read FOnMsgReceived write FOnMsgReceived;
    property    OnErrorFrame: TCanErrFrameReceivedEvent read FOnErrFrameReceived write FOnErrFrameReceived;
  end;


//***************************************************************************************
// Function prototypes
//***************************************************************************************
procedure Register;


implementation
//---------------------------------------------------------------------------------------
//-------------------------------- TCanSocket -------------------------------------------
//---------------------------------------------------------------------------------------
//***************************************************************************************
// NAME:           Create
// PARAMETER:      AParent Parent class.
// DESCRIPTION:    Thread constructor.
//
//***************************************************************************************
constructor TCanSocket.TCanThread.Create(AParent: TCanSocket);
begin
  // Make sure the parent is valid.
  if AParent = nil then
  begin
    raise EArgumentNilException.Create('Invalid parent specified');
  end;
  // Initialize fields
  FParent := AParent;
  // Call inherited construction.
  inherited Create(True);
end; //*** end of Create ***


//***************************************************************************************
// NAME:           Execute
// DESCRIPTION:    Thread execution function.
//
//***************************************************************************************
procedure TCanSocket.TCanThread.Execute;
begin
  // Enter thread's execution loop
  while not Terminated do
  begin
    // Only actively check for CAN events if the CAN socket is connected.
    if Parent.Connected then
    begin
      // TODO Implement Execute method. Sleep for now..
      Sleep(50);
    end
    // Not connected. Just wait a bit to not starve the CPU.
    else
    begin
      Sleep(50);
    end;
  end;
end; //*** end of Execute ***


//***************************************************************************************
// NAME:           Create
// PARAMETER:      AOwner Instance owner.
// DESCRIPTION:    Component constructor. Calls TComponents's constructor and initializes
//                 the fields to their default values.
//
//***************************************************************************************
constructor TCanSocket.Create(AOwner: TComponent);
begin
  // Call inherited constructor.
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
    raise EInvalidPointer.Create('Could not create CAN communication context');
  end;
  // Create the CAN devices class.
  FCanDevices := TCanDevices.Create(FCanContext);
  // Create the event thread.
  FEventThread := TCanThread.Create(Self);
  // Make sure the event could be created.
  if FEventThread = nil then
  begin
    raise EInvalidPointer.Create('Could not create event thread');
  end;
  // Start the event thread.
  FEventThread.Start;
end; //*** end of Create ***


//***************************************************************************************
// NAME:           Destroy
// DESCRIPTION:    Component destructor. Calls TComponent's destructor
//
//***************************************************************************************
destructor TCanSocket.Destroy;
begin
  // Make sure to disconnect.
  Disconnect;
  // Set event thread termination request.
  FEventThread.Terminate;
  // Wait for thread termination to complete.
  FEventThread.WaitFor;
  // Release the thread object.
  FEventThread.Free;
  // Free the CAN devices class.
  FCanDevices.Free;
  // Release the CAN communication context.
  if (FCanContext <> nil) then
  begin
    CanCommFree(FCanContext);
  end;
  // Call inherited destructor.
  inherited Destroy;
end; //*** end of Destroy ***


//***************************************************************************************
// NAME:           SetDevice
// PARAMETER:      Value The device name, e.g. 'can0', 'vcan0', etc.
// DESCRIPTION:    Sets the CAN device name. Automatically reconnects if needed.
//
//***************************************************************************************
procedure TCanSocket.SetDevice(Value: string);
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
function TCanSocket.Connect: Boolean;
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
procedure TCanSocket.Disconnect;
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
// PARAMETER:      Msg Message to transmit.
// RETURN VALUE:   True if successful, False otherwise.
// DESCRIPTION:    Submits a CAN message for transmission. Note that this function writes
//                 the timestamp into the Msg parameter.
//
//***************************************************************************************
function TCanSocket.Transmit(var Msg: TCanMsg): Boolean;
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
                       Msg.Timestamp) = CANCOMM_TRUE then
    begin
      Result := True;
    end;
  end;
end; //*** end of Transmit ***


//***************************************************************************************
// NAME:           Register
// DESCRIPTION:    Registers the component such that it shows up on the IDE's component
//                 palette.
//
//***************************************************************************************
procedure Register;
begin
  {$I socketcan.lrs}
  RegisterComponents('System', [TCanSocket]);
end;  //*** end of Register ***


end.
//******************************** end of cansocket.pas *********************************

