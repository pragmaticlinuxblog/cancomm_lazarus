unit CanUnix;
//***************************************************************************************
//  Description: CAN Unix unit. Exposes Unix related constants, types and functions that
//               are not yet offered by BaseUnix.
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
  Classes, SysUtils, ctypes;


//***************************************************************************************
// Global constant declarations
//***************************************************************************************
const
  AF_INET          = 2;
  PF_CAN           = 29;
  SOCK_RAW         = 3;
  CAN_RAW          = 1;
  SIOCGIFHWADDR    = $8927;
  ARPHRD_CAN       = 280;
  IFNAMSIZ         = 16;


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
    _padding: cardinal;     // explicit pad to match C struct layout
    ifa_addr: psockaddr;
    ifa_netmask: psockaddr;
    ifa_ifu: pointer;       // union treated as single pointer
    ifa_data: pointer;
  end;

  tifreq = record
    ifr_name: array[0..IFNAMSIZ - 1] of Char;
    case Byte of
      0: (ifr_hwaddr: Tsockaddr);
      1: (_padding: array[0..23] of Byte);
  end;


//***************************************************************************************
// Function prototypes
//***************************************************************************************
function  getifaddrs(var ifap: pifaddrs): cint;
          cdecl; external 'c' name 'getifaddrs';
procedure freeifaddrs(ifa: pifaddrs);
          cdecl; external 'c' name 'freeifaddrs';
function  socket(domain, socktype, protocol: cint): cint;
          cdecl; external 'c' name 'socket';


implementation

end.
//******************************** end of canunix.pas ***********************************

