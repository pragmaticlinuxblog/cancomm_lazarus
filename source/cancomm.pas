unit CanComm;
//***************************************************************************************
//  Description: Unit that mimics the API of the LibCanComm shared library on Linux.
//    File Name: cancomm.pas
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
  Classes, SysUtils, Unix, BaseUnix, CanUnix;


//***************************************************************************************
// Global constant declarations
//***************************************************************************************
const
  // Name of the external library.
  CANCOMM_LIBNAME = 'cancomm';
  // Boolean true value.
  CANCOMM_TRUE = 1;
  // Boolean false value.
  CANCOMM_FALSE = 0;
  // Bit flag to indicate that the message is a CAN FD message.
  CANCOMM_FLAG_CANFD_MSG = $01;
  // Bit flag to indicate that the message is a CAN error frame.
  CANCOMM_FLAG_CANERR_MSG = $80;


//***************************************************************************************
// Type definitions
//***************************************************************************************
type
  // Opaque pointer for the CAN communication context.
  TCanComm = pointer;


//***************************************************************************************
// Function prototypes
//***************************************************************************************
function  CanCommNew: TCanComm;
procedure CanCommFree(Context: TCanComm);


//***************************************************************************************
// NAME:           CanCommConnect
// PARAMETER:      Context CAN communication context.
//                 Device Null terminated string with the SocketCAN device name, e.g.
//                 PAnsiChar(AnsiString('can0'))
// RETURN VALUE:   CANCOMM_TRUE if successfully connected to the SocketCAN device.
//                 CANCOMM_FALSE otherwise.
// DESCRIPTION:    Connects to the specified SocketCAN device. Note that you can use the
//                 functions cancomm_devices_buildlist() and cancomm_devices_name() to
//                 determine the names of the SocketCAN devices known to the system.
//                 Alternatively, you can run command "ip addr" in the terminal to find
//                 out about the SocketCAN devices know to the system.
//                 This function automatically figures out if the SocketCAN device
//                 supports CAN FD, in addition to CAN classic.
//
//***************************************************************************************
function CanCommConnect(Context: TCanComm; Device: PAnsiChar): Byte;
         cdecl; external CANCOMM_LIBNAME name 'cancomm_connect';


procedure CanCommDisconnect(Context: TCanComm);


//***************************************************************************************
// NAME:           CanCommTransmit
// PARAMETER:      Context CAN communication context.
//                 Id CAN message identifier.
//                 Ext CANCOMM_FALSE for an 11-bit message identifier, CANCOMM_TRUE for
//                 29-bit.
//                 Len Number of CAN message data bytes.
//                 PData Pointer to array with data bytes.
//                 Flags Bit flags for providing additional information about how to
//                       transmit the message:
//                         CANCOMM_FLAG_CANFD_MSG - The message is CAN FD and not CAN
//                                                  classic. Ignored for non CAN FD
//                                                  SocketCAN devices.
//                 PTimestamp Pointer to where the timestamp (microseconds) of the
//                 message is stored.
// RETURN VALUE:   CANCOMM_TRUE if successfully submitted the message for transmission.
//                 CANCOMM_FALSE otherwise.
// DESCRIPTION:    Submits a CAN message for transmission.
//
//***************************************************************************************
function CanCommTransmit(Context: TCanComm; Id: LongWord; Ext: Byte; Len: Byte;
                         PData: PByte; Flags: Byte; out Timestamp: QWord): Byte;
         cdecl; external CANCOMM_LIBNAME name 'cancomm_transmit';


//***************************************************************************************
// NAME:           CanCommReceive
// PARAMETER:      Context CAN communication context.
//                 Id Variable where the CAN message identifier is stored.
//                 Ext Variable where the CAN identifier type is stored. CANCOMM_FALSE
//                 for an 11-bit message identifier, CANCOMM_TRUE for 29-bit.
//                 Len Variable where the number of CAN message data bytes is stored.
//                 PData Pointer to array where the data bytes are stored.
//                 Flags Variable where the bit flags are stored for providing
//                 additional information about the received message:
//                         CANCOMM_FLAG_CANFD_MSG - The message is CAN FD and not CAN
//                                                  classic.
//                         CANCOMM_FLAG_CANERR_MSG - The message is a CAN error frame.
//                 Timestamp Variable where the timestamp (microseconds) of the
//                 message is stored.
// RETURN VALUE:   CANCOMM_TRUE if a new message was received and copied. CANCOMM_FALSE
//                 otherwise.
// DESCRIPTION:    Reads a possibly received CAN message or CAN eror frame in a
//                 non-blocking manner.
//
//***************************************************************************************
function CanCommReceive(Context: TCanComm; out Id: LongWord; out Ext: Byte;
                        out Len: Byte; PData: PByte; out Flags: Byte;
                        out Timestamp: QWord): Byte;
         cdecl; external CANCOMM_LIBNAME name 'cancomm_receive';


function CanCommDevicesBuildList(Context: TCanComm): Byte;
function CanCommDevicesName(Context: TCanComm; Index: Byte): PAnsiChar;



implementation
//***************************************************************************************
// Local constant declarations
//***************************************************************************************
const
  // Value of an invalid socket.
  CANCOMM_INVALID_SOCKET = -1;


//***************************************************************************************
// Local type definitions
//***************************************************************************************
type
  // Structure for grouping all CAN communication context related data. Basically the
  // non-opaque counter part of TCanComm.
  TCanCommCtx = record
    // CAN raw socket handle. Also used to determine the connection state internally.
    // CANCOMM_INVALID_SOCKET if not connected, any other value if connected.
    Socket: LongInt;
    // Boolean flag to determine if the CAN device is CAN classic or CAN FD.
    FdEnabled: Byte;
    // System time at which this module connected to the CAN network. Used to calculate
    // zero based CAN message timestamps.
    ConnectTime: QWord;
    // Holds the number of CAN devices that were detected on the system.
    DevicesCnt: LongWord;
    // List of strings with the names of CAN devices that were detected on the system.
    DevicesList: TStringList;
  end;
  PCanCommCtx = ^TCanCommCtx;


//***************************************************************************************
// Local function prototypes
//***************************************************************************************
function CanCommDevicesIsCan(Name: PAnsiChar): Byte; forward;


//***************************************************************************************
// NAME:           CanCommNew
// RETURN VALUE:   Newly created context, if successful. nil otherwise.
// DESCRIPTION:    Creates a new CAN communication context. All subsequent library
//                 functions need this context.
//
//***************************************************************************************
function CanCommNew: TCanComm;
var
  newCtxPtr: PCanCommCtx;
begin
  // Initialize the result.
  Result := nil;
  // Allocate memory for the new context.
  New(newCtxPtr);
  // Only continue if memory could be allocated.
  if newCtxPtr <> nil then
  begin
    // Initialize the context members.
    newCtxPtr^.Socket := CANCOMM_INVALID_SOCKET;
    newCtxPtr^.FdEnabled := CANCOMM_FALSE;
    newCtxPtr^.ConnectTime := 0;
    newCtxPtr^.DevicesCnt := 0;
    newCtxPtr^.DevicesList := TStringList.Create;
    // Update the result.
    Result := TCanComm(newCtxPtr);
  end;
end; //*** end of CanCommNew ***


//***************************************************************************************
// NAME:           CanCommFree
// PARAMETER:      Context CAN communication context.
// DESCRIPTION:    Releases the context. Should be called for each CAN communication
//                 context, created with function cancomm_new(), once you no longer need
//                 it.
//
//***************************************************************************************
procedure CanCommFree(Context: TCanComm);
var
  currentCtxPtr: PCanCommCtx;
begin
  // Only continue with a valid parameter.
  if Context <> nil then
  begin
    // Cast the opaque pointer to its non-opaque counter part.
    currentCtxPtr := PCanCommCtx(Context);
    // Make sure to disconnect the CAN device.
    CanCommDisconnect(Context);
    // Empty the devices list.
    currentCtxPtr^.DevicesList.Free;
    currentCtxPtr^.DevicesCnt := 0;
    // Release the context's allocated memory.
    Dispose(currentCtxPtr);
    // Reset the pointer to prevent a dangling pointer.
    currentCtxPtr := nil;
  end;
end; //*** end of CanCommFree ***


//***************************************************************************************
// NAME:           CanCommDisconnect
// PARAMETER:      Context CAN communication context.
// DESCRIPTION:    Disconnects from the SocketCAN device.
//
//***************************************************************************************
procedure CanCommDisconnect(Context: TCanComm);
var
  currentCtxPtr: PCanCommCtx;
begin
  // Only continue with a valid parameter.
  if Context <> nil then
  begin
    // Cast the opaque pointer to its non-opaque counter part.
    currentCtxPtr := PCanCommCtx(Context);
    // Only disconnect if actually connected.
    if currentCtxPtr^.Socket <> CANCOMM_INVALID_SOCKET then
    begin
      FpClose(currentCtxPtr^.Socket);
      currentCtxPtr^.Socket := CANCOMM_INVALID_SOCKET;
    end;
  end;
end; //*** end of CanCommDisconnect ***


//***************************************************************************************
// NAME:           CanCommDevicesBuildlist
// PARAMETER:      Context CAN communication context.
// RETURN VALUE:   The total number of CAN devices currently present on the system, or 0
//                 if none were found or in case of an error.
// DESCRIPTION:    Builds a list with all the CAN device names currently present on the
//                 system. Basically an internal array with strings such as can0, vcan0,
//                 etc. Afterwards, you can call CanCommDevicesName() to retrieve the
//                 name of a specific SocketCAN device, using its array index.
//
//***************************************************************************************
function CanCommDevicesBuildList(Context: TCanComm): Byte;
var
  currentCtxPtr: PCanCommCtx;
  ifAddr: pifaddrs = Nil;
  ifAddrHead: pifaddrs = Nil;
begin
  // Initialize the result.
  Result := 0;
  // Only continue with a valid parameter.
  if Context <> nil then
  begin
    // Cast the opaque pointer to its non-opaque counter part.
    currentCtxPtr := PCanCommCtx(Context);
    // Reset the device count and clear the device name list.
    currentCtxPtr^.DevicesCnt := 0;
    currentCtxPtr^.DevicesList.Clear;
    // Attempt to obtain access to the linked list with network interfaces.
    if getifaddrs(ifAddr) = 0 then
    begin
      // Create a copy of the original pointer before iterating through the interfaces.
      ifAddrHead := ifAddr;
      // Loop through the linked list.
      try
        while ifAddr <> nil do
        begin
          // We are interested in the ifa_name element, so only process the node, when
          // this one is valid.
          if ifAddr^.ifa_name <> nil then
          begin
            // Check if this network interface is actually a CAN interface.
            if CanCommDevicesIsCan(ifAddr^.ifa_name) = CANCOMM_TRUE then
            begin
              // Increment the devices count in the context and add it to the list.
              Inc(currentCtxPtr^.DevicesCnt);
              currentCtxPtr^.DevicesList.Add(ifAddr^.ifa_name);
            end;
          end;
          // Continue with the next entry in the linked list.
          ifAddr := ifAddr^.ifa_next;
        end;
      finally
        // Free the list, now that we are done with it.
        freeifaddrs(ifAddrHead);
      end;
      // Update the result.
      Result := Byte(currentCtxPtr^.DevicesCnt );
    end;
  end;
end; //*** end of CanCommDevicesBuildList ***


//***************************************************************************************
// NAME:           CanCommDevicesName
// PARAMETER:      Context CAN communication context.
//                 Index Zero based index into the device list.
// RETURN VALUE:   The CAN device name at the specified index, or nil in case of an
//                 error. Note that you can use StrPas() to convert the value to a
//                 string.
// DESCRIPTION:    Obtains the CAN device name at the specified index of the internal
//                 list with CAN devices, created by function CanCommDevicesBuildList().
//                 You could use this CAN device name when calling CanCommConnect().
// ATTENTION:      Call CanCommDevicesBuildList() prior to calling this function.
//
//***************************************************************************************
function CanCommDevicesName(Context: TCanComm; Index: Byte): PAnsiChar;
var
  currentCtxPtr: PCanCommCtx;
begin
  // Initialize the result.
  Result := nil;
  // Only continue with a valid parameter.
  if Context <> nil then
  begin
    // Cast the opaque pointer to its non-opaque counter part.
    currentCtxPtr := PCanCommCtx(Context);
    // Only continue if the specified index is valid.
    if Index < currentCtxPtr^.DevicesCnt then
    begin
      // Update the result.
      Result := PAnsiChar(currentCtxPtr^.DevicesList[Index]);
    end;
  end;
end; //*** end of CanCommDevicesName ***


//***************************************************************************************
// NAME:           CanCommDevicesIsCan
// PARAMETER:      Name: Network interface name. For example obtained by getifaddrs().
// RETURN VALUE:   CANCOMM_TRUE is the specified network interface name is a CAN device,
//                 CANCOMM_FALSE otherwise.
// DESCRIPTION:    Determines if the specified network interface name is a CAN device.
//
//***************************************************************************************
function CanCommDevicesIsCan(Name: PAnsiChar): Byte;
var
  ifr: tifreq;
  canSocket: LongInt;
begin
  // Initialize the result.
  Result := CANCOMM_FALSE;
  // Only continue with valid parameter and acceptable length of the interface name.
  if (Name <> nil) and (StrLen(Name) < IFNAMSIZ) then
  begin
    // Create an ifreq structure for passing data in and out of ioctl. Reset the
    // sa_family element. Then set all bytes of the interface name to the \0 string
    // termination. Then copy over all but the last byte, to make sure the last byte is
    // always also a \0 string termination.
    ifr.ifr_hwaddr.sa_family := 0;
    FillChar(ifr.ifr_name, IFNAMSIZ, 0);
    Move(Name^, ifr.ifr_name, IFNAMSIZ - 1);
    // Get open socket descriptor.
    canSocket := socket(PF_CAN, SOCK_RAW, CAN_RAW);
    if canSocket <> -1 then
    begin
      // Obtain the hardware address information.
      if FpIOCtl(canSocket, TIOCtlRequest(SIOCGIFHWADDR), @ifr) <> -1 then
      begin
        // Is this a CAN device?
        if ifr.ifr_hwaddr.sa_family = ARPHRD_CAN then
        begin
          // Update the result accordingly.
          Result := CANCOMM_TRUE;
        end;
      end;
      // Close the socket, now that we are done with it.
      FpClose(canSocket);
    end;
  end;
end; //*** end of CanCommDevicesIsCan ***

end.
//******************************** end of cancomm.pas ***********************************

