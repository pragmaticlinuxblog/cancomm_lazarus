unit CanComm;
//***************************************************************************************
//  Description: Unit with bindings for the LibCanComm shared library on Linux.
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
  Classes, SysUtils;

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
//***************************************************************************************
// NAME:           CanCommNew
// RETURN VALUE:   Newly created context, if successful. nil otherwise.
// DESCRIPTION:    Creates a new CAN communication context. All subsequent library
//                 functions need this context.
//
//***************************************************************************************
function CanCommNew: TCanComm;
         cdecl; external CANCOMM_LIBNAME name 'cancomm_new';


//***************************************************************************************
// NAME:           CanCommFree
// PARAMETER:      Context CAN communication context.
// DESCRIPTION:    Releases the context. Should be called for each CAN communication
//                 context, created with function cancomm_new(), once you no longer need
//                 it.
//
//***************************************************************************************
procedure CanCommFree(Context: TCanComm);
          cdecl; external CANCOMM_LIBNAME name 'cancomm_free';


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


//***************************************************************************************
// NAME:           CanCommDisconnect
// PARAMETER:      Context CAN communication context.
// DESCRIPTION:    Disconnects from the SocketCAN device.
//
//***************************************************************************************
procedure CanCommDisconnect(Context: TCanComm);
          cdecl; external CANCOMM_LIBNAME name 'cancomm_disconnect';


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
         cdecl; external CANCOMM_LIBNAME name 'cancomm_devices_buildlist';


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
         cdecl; external CANCOMM_LIBNAME name 'cancomm_devices_name';


implementation


end.
//******************************** end of cancomm.pas ***********************************

