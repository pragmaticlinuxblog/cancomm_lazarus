unit CanComm;
//***************************************************************************************
//  Description: Unit that mimics the API of the LibCanComm shared library on Linux
//               (https://github.com/pragmaticlinuxblog/cancomm).
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
  // TODO ##Vg Can be removed once the rework is done.
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
// API for obtaining a context, allowing multiple applications to use this library.
function  CanCommNew: TCanComm;
procedure CanCommFree(Context: TCanComm);
function  CanCommConnect(Context: TCanComm; Device: PAnsiChar): Byte;
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


// API for obtaining CAN device names on the system (can0, vcan0, etc.).
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
function CanCommSanitizeFrameLen(Len: Byte): Byte; forward;


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
var
  currentCtxPtr: PCanCommCtx;
  ifr: tifreq;
  tv: TTimeVal;
  deviceMtu: LongInt;
  flags: LongInt;
  enableCanFd: Integer;
  addr: tsockaddr_can;
begin
  // Initialize the result.
  Result := CANCOMM_FALSE;
  // Only continue with a valid parameters.
  if (Context <> nil) and (Device <> nil) then
  begin
    // Cast the opaque pointer to its non-opaque counter part.
    currentCtxPtr := PCanCommCtx(Context);
    // Set positive result at this point and negate upon error detection.
    Result := CANCOMM_TRUE;
    // Make sure we are not already connected to a CAN device.
    CanCommDisconnect(Context);
    // Create an ifreq structure for passing data in and out of ioctl. Reset the
    // ifr_mtu and and ifr_ifindex elements. Then set all bytes of the interface name to
    // the \0 string termination. Then copy over all but the last byte, to make sure the
    // last byte is always also a \0 string termination.
    ifr.ifr_mtu := 0;
    ifr.ifr_ifindex := 0;
    FillChar(ifr.ifr_name, IFNAMSIZ, 0);
    Move(Device^, ifr.ifr_name, IFNAMSIZ - 1);
    // Get current system time.
    tv.tv_sec := 0;
    tv.tv_usec := 0;
    if fpgettimeofday(@tv, nil) = 0 then
    begin
      // Convert the current time to microseconds and store it as the connection start
      // time. Needed for zero based timestamp.
      currentCtxPtr^.ConnectTime := (Int64(tv.tv_sec) * 1000000) + tv.tv_usec;
    end
    else
    begin
      // Flag the error.
      Result := CANCOMM_FALSE;
    end;

    // Only continue if all is okay so far.
    if Result = CANCOMM_TRUE then
    begin
      // Get open socket descriptor.
      currentCtxPtr^.Socket := socket(PF_CAN, SOCK_RAW, CAN_RAW);
      if currentCtxPtr^.Socket < 0 then
      begin
        // Flag the error.
        Result := CANCOMM_FALSE;
      end;
    end;

    // Only continue if all is okay so far.
    if Result = CANCOMM_TRUE then
    begin
      // Determine if the CAN device is configured for CAN classic or CAN FD mode. Do so
      // by reading the MTU size of the CAN device. For CAN classic it will be CAN_MTU.
      // For CAN FD it will be CANFD_MTU.
      deviceMtu := CAN_MTU;
      // Attempt to read the MTU value from the CAN device.
      if FpIOCtl(currentCtxPtr^.Socket, TIOCtlRequest(SIOCGIFMTU), @ifr) >= 0 then
      begin
        // Only update the MTU value if it is a supported value.
        if (ifr.ifr_mtu = CAN_MTU) or (ifr.ifr_mtu = CANFD_MTU) then
        begin
          deviceMtu := ifr.ifr_mtu;
        end;
      end;
      // Use the MTU value to determine if the CAN device is operating in CAN classic or
      // CAN FD mode. Note that the MTU value of the CAN device changes automatically to
      // the value of CANFD_MTU, after the data bitrate was configured and the fd mode
      // was turned on. Example:
      //   ip link set can0 type can bitrate 500000 dbitrate 4000000 fd on
      if deviceMtu = CANFD_MTU then
      begin
        currentCtxPtr^.FdEnabled := CANCOMM_TRUE;
      end
      else
      begin
        currentCtxPtr^.FdEnabled := CANCOMM_FALSE;
      end;
      // Attempt to switch socket into CAN FD mode, if the CAN device is configured for
      // CAN FD.
      if currentCtxPtr^.FdEnabled = CANCOMM_TRUE then
      begin
        enableCanFd := 1;
        if setsockopt(currentCtxPtr^.Socket, SOL_CAN_RAW, CAN_RAW_FD_FRAMES, @enableCanFd, SizeOf(enableCanFd)) <> 0 then
        begin
          // Could not switch the socket into CAN FD mode. Fall back to CAN classic
          // operation.
          currentCtxPtr^.FdEnabled := CANCOMM_FALSE;
        end;
      end;
    end;

    // Only continue if all is okay so far.
    if Result = CANCOMM_TRUE then
    begin
      // Configure socket to work in non-blocking mode.
      flags := fpFCntl(currentCtxPtr^.Socket, F_GETFL, 0);
      if flags = -1 then
      begin
        flags := 0;
      end;
      if fpFCntl(currentCtxPtr^.Socket, F_SETFL, flags or O_NONBLOCK) = -1 then
      begin
        // Flag the error and close the socket.
        fpClose(currentCtxPtr^.Socket);
        currentCtxPtr^.Socket := CANCOMM_INVALID_SOCKET;
        Result := CANCOMM_FALSE;
      end;
    end;

    // Only continue if all is okay so far.
    if Result = CANCOMM_TRUE then
    begin
      // Obtain interface index.
      if fpIOCtl(currentCtxPtr^.Socket, SIOCGIFINDEX, @ifr) < 0 then
      begin
        // Flag the error and close the socket.
        fpClose(currentCtxPtr^.Socket);
        currentCtxPtr^.Socket := CANCOMM_INVALID_SOCKET;
        Result := CANCOMM_FALSE;
      end;
    end;

    // Only continue if all is okay so far.
    if Result = CANCOMM_TRUE then
    begin
      // Set the address info.
      addr.can_family := AF_CAN;
      addr.can_ifindex := ifr.ifr_ifindex;
      // Bind the socket.
      if bind(currentCtxPtr^.Socket, @addr, SizeOf(addr)) < 0 then
      begin
        // Flag the error and close the socket.
        fpClose(currentCtxPtr^.Socket);
        currentCtxPtr^.Socket := CANCOMM_INVALID_SOCKET;
        Result := CANCOMM_FALSE;
      end;
    end;
  end;
end; //*** end of CanCommConnect ***


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
            if CanCommDevicesIsCan(PChar(ifAddr^.ifa_name)) = CANCOMM_TRUE then
            begin
              // Increment the devices count in the context and add it to the list.
              Inc(currentCtxPtr^.DevicesCnt);
              currentCtxPtr^.DevicesList.Add(PChar(ifAddr^.ifa_name));
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
// PARAMETER:      Name Network interface name. For example obtained by getifaddrs().
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


//***************************************************************************************
// NAME:           CanCommSanitizeFrameLen
// PARAMETER:      Len Unsanitized frame length. 0..64.
// RETURN VALUE:   Sanitized frame length in the range 0..8, 12, 16, 20, 24, 32, 48, 64.
// DESCRIPTION:    Helper function to sanitize the CAN frame length, specifically for
//                 CAN FD. On CAN FD, the frame lengths can be: 0..8, 12, 16, 20, 24, 32,
//                 48, 64. This means that if a frame length of 14 is specified, it
//                 should be rounded up to the next supported frame length value, 16 in
//                 this case.
//
//***************************************************************************************
function CanCommSanitizeFrameLen(Len: Byte): Byte;
const
  len2dlc: array[0..64] of Byte = (
     0,  1,  2,  3,  4,  5,  6,  7,  8,    {  0 -  8 }
     9,  9,  9,  9,                        {  9 - 12 }
    10, 10, 10, 10,                        { 13 - 16 }
    11, 11, 11, 11,                        { 17 - 20 }
    12, 12, 12, 12,                        { 21 - 24 }
    13, 13, 13, 13, 13, 13, 13, 13,        { 25 - 32 }
    14, 14, 14, 14, 14, 14, 14, 14,        { 33 - 40 }
    14, 14, 14, 14, 14, 14, 14, 14,        { 41 - 48 }
    15, 15, 15, 15, 15, 15, 15, 15,        { 49 - 56 }
    15, 15, 15, 15, 15, 15, 15, 15         { 57 - 64 }
  );
  dlc2len: array[0..15] of Byte = (
    0, 1, 2, 3, 4, 5, 6, 7, 8, 12, 16, 20, 24, 32, 48, 64
  );
var
  frameLen: Byte;
  frameDlc: Byte;
begin
  // Make sure the specified len parameter is valid. If not, correct it.
  if len > CANFD_MAX_DLEN then
  begin
    frameLen := CANFD_MAX_DLEN
  end
  else
  begin
    frameLen := len;
  end;
  // Convert the lenght value to the CAN FD dlc value (0..15).
  frameDlc := len2dlc[frameLen];
  // Convert the CAN FD dlc value to its representive frame length value.
  Result := dlc2len[frameDlc];
end; //*** end of CanCommSanitizeFrameLen ***

end.
//******************************** end of cancomm.pas ***********************************

