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
// Global Includes
//***************************************************************************************
uses
  Classes, SysUtils;

//***************************************************************************************
// Global Constant Declarations
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
// Opaque pointer for the CAN communication context.
type
  TCanComm = pointer;


//***************************************************************************************
// Function prototypes
//***************************************************************************************
//***************************************************************************************
// NAME:           CanCommNew
// RETURN VALUE:   none
// DESCRIPTION:    Newly created context, if successful. nil otherwise.
//
//***************************************************************************************
function CanCommNew: TCanComm; cdecl; external CANCOMM_LIBNAME name 'cancomm_new';


//***************************************************************************************
// NAME:           CanCommFree
// PARAMETER:      Context CAN communication context.
// DESCRIPTION:    Releases the context. Should be called for each CAN communication
//                 context, created with function cancomm_new(), once you no longer need
//                 it.
//
//***************************************************************************************
procedure CanCommFree(Context: TCanComm); cdecl; external CANCOMM_LIBNAME name 'cancomm_free';


implementation

end.
//******************************** end of cancomm.pas ***********************************

