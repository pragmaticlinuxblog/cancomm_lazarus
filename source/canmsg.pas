unit CanMsg;
//***************************************************************************************
//  Description: CAN message unit.
//    File Name: canmsg.pas
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
  Classes, SysUtils;


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


implementation


end.
//******************************** end of canmsg.pas ************************************

