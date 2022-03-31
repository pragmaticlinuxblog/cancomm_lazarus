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
  Classes, SysUtils, CanComm;


//***************************************************************************************
// Global Constant Declarations
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
      Fd: Boolean;         // False for CAN classic, True for CAN FD frame
      Err: Boolean;        // False for CAN data frame, True for CAN error frame
    end;
    Timestamp: QWord;    // Message timestamp
  end;

  //---------------------------------- TCanDevices --------------------------------------
  // Class for convenient access to the CAN device detected on the system.
  TCanDevices = class(TObject)
    private
      FCanContext: TCanComm;
      FCount: Integer;
      procedure   BuildDeviceList;
      function    GetCount: Integer;
      function    GetDevice(Index: Integer): string;
    public
      constructor Create(ACanContext: TCanComm);
      destructor  Destroy; override;
      property    Count: Integer read GetCount;
      property    Devices[Index: Integer]: string read GetDevice; default;
  end;

  //---------------------------------- TCanMsgReceivedEvent -----------------------------
  // Event handler type for CAN message reception.
  TCanMsgReceivedEvent = procedure(Sender: TObject; Msg: TCanMsg) of object;

  //---------------------------------- TCanErrFrameReceivedEvent ------------------------
  // Event handler type for CAN error frame reception.
  TCanErrFrameReceivedEvent = procedure(Sender: TObject) of object;

  //---------------------------------- TCanDriver ---------------------------------------
  TCanDriver = class(TComponent)
  // TODO Implement reception thread. Should probably be a separate class.
  // TODO Implement register function and figure out how to add an icon.
  private
    { Private declarations }
    FCanDevices: TCanDevices;
  protected
    { Protected declarations }
    FCanContext: TCanComm;
    FConnected : Boolean;
    FDevice: string;
    FOnMsgReceived: TCanMsgReceivedEvent;
    FOnErrFrameReceived: TCanErrFrameReceivedEvent;
    procedure   SetDevice(Value: string);
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    function    Connect: Boolean;
    procedure   Disconnect;
    function    Transmit(Msg: TCanMsg): Boolean;
    { Public properties }
    property    Device: string read FDevice write SetDevice;
    property    Connected: Boolean read FConnected;
    property    Devices: TCanDevices read FCanDevices;
    property    OnMsgReceived: TCanMsgReceivedEvent read FOnMsgReceived write FOnMsgReceived;
    property    OnErrFrameReceived: TCanErrFrameReceivedEvent read FOnErrFrameReceived write FOnErrFrameReceived;
  end;


implementation
//---------------------------------------------------------------------------------------
//-------------------------------- TCanDevices ------------------------------------------
//---------------------------------------------------------------------------------------
//***************************************************************************************
// NAME:           Create
// PARAMETER:      ACanContext The CAN communication context that it operates on.
// DESCRIPTION:    Object constructor. Calls TObjects's constructor and initializes
//                 the fields their default values.
//
//***************************************************************************************
constructor TCanDevices.Create(ACanContext: TCanComm);
begin
  // Call inherited constructor.
  inherited Create;
  // Store the context.
  FCanContext := ACanContext;
  FCount := 0;
end; //*** end of Create ***


//***************************************************************************************
// NAME:           Destroy
// DESCRIPTION:    Object destructor. Calls TObjects's destructor
//
//***************************************************************************************
destructor TCanDevices.Destroy;
begin
  // Call inherited destructor.
  inherited Destroy;
end; //*** end of Destroy ***


//***************************************************************************************
// NAME:           BuildDeviceList
// DESCRIPTION:    Refreshes the CAN device list inside the context.
//
//***************************************************************************************
procedure TCanDevices.BuildDeviceList;
begin
  // Reset the device count.
  FCount := 0;
  // Only continue with a valid context.
  if FCanContext <> nil then
  begin
    // Rebuild the list and store the total number of detected CAN devices.
    FCount := CanCommDevicesBuildList(FCanContext);
  end;
end; //*** end of BuildDeviceList ***


//***************************************************************************************
// NAME:           GetCount
// RETURN VALUE:   Number of detected CAN devices on the system.
// DESCRIPTION:    Obtains the number of CAN devices detected on the system.
//
//***************************************************************************************
function TCanDevices.GetCount: Integer;
begin
  // Build the CAN device list, which also updates FCount.
  BuildDeviceList;
  // Update the result.
  Result := FCount;
end; //*** end of GetCount ***


//***************************************************************************************
// NAME:           GetDevice
// PARAMETER:      Index Zero based index into the list with CAN devices.
// RETURN VALUE:   Name of the CAN device at the specified index.
// DESCRIPTION:    Obtains the name of the CAN device at the specified index.
//
//***************************************************************************************
function TCanDevices.GetDevice(Index: Integer): string;
var
  DeviceName: PAnsiChar;
begin
  // Initialize the result.
  Result := '';
  // Build the CAN device list, which also updates FCount.
  BuildDeviceList;
  // Only continue if the index is valid
  if Index < FCount then
  begin
    // Obtain the device name.
    DeviceName := CanCommDevicesName(FCanContext, Index);
    // Update the result if the device name is valid.
    if DeviceName <> nil then
    begin
      Result := StrPas(DeviceName);
    end;
  end;
end;  //*** end of GetDevice ***


//---------------------------------------------------------------------------------------
//-------------------------------- TCanDriver -------------------------------------------
//---------------------------------------------------------------------------------------
//***************************************************************************************
// NAME:           Create
// PARAMETER:      AOwner Instance owner.
// DESCRIPTION:    Component constructor. Calls TComponents's constructor and initializes
//                 the fields their default values.
//
//***************************************************************************************
constructor TCanDriver.Create(AOwner: TComponent);
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
    raise Exception.Create('Could not create CAN communication context');
  end;
  // Create the CAN devices class.
  FCanDevices := TCanDevices.Create(FCanContext);
end; //*** end of Create ***


//***************************************************************************************
// NAME:           Destroy
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
  // Free the CAN devices class.
  FCanDevices.Free;
  // Call inherited destructor.
  inherited Destroy;
end; //*** end of Destroy ***


//***************************************************************************************
// NAME:           SetDevice
// PARAMETER:      Value The device name, e.g. 'can0', 'vcan0', etc.
// DESCRIPTION:    Sets the CAN device name. Automatically reconnects if needed.
//
//***************************************************************************************
procedure TCanDriver.SetDevice(Value: string);
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

