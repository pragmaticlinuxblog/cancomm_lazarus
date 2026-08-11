unit CanUnix;
//***************************************************************************************
//  Description: CAN Unix unit.
//    File Name: canunix.pas
//
//---------------------------------------------------------------------------------------
//                          C O P Y R I G H T
//---------------------------------------------------------------------------------------
//         Copyright (c) 2026 by PragmaticLinux     All rights reserved
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
  Classes, SysUtils, BaseUnix;


//***************************************************************************************
// Global constant declarations
//***************************************************************************************
const
  AF_INET = 2;


//***************************************************************************************
// Type definitions
//***************************************************************************************
type
  psockaddr = ^tsockaddr;
  tsockaddr = record
    sa_family: word;
    sa_data: array[0..13] of byte;
  end;

  pifaddrs = ^tifaddrs;
  tifaddrs = record
    ifa_next: pifaddrs;
    ifa_name: pchar;
    ifa_flags: cardinal;
    ifa_addr: psockaddr;
    ifa_netmask: psockaddr;
    ifa_ifu: record
      case byte of
        0: (ifu_broadaddr: psockaddr);
        1: (ifu_dstaddr: psockaddr);
    end;
    ifa_data: pointer;
  end;

//***************************************************************************************
// Function prototypes
//***************************************************************************************
function getifaddrs(var ifap: pifaddrs): cint; cdecl; external 'c' name 'getifaddrs';
procedure freeifaddrs(ifa: pifaddrs); cdecl; external 'c' name 'freeifaddrs';


implementation

end.
//******************************** end of canunix.pas ***********************************

