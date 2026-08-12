unit CanUnix;
//***************************************************************************************
//  Description: CAN Unix unit. Exposes Unix related constants, types and functions that
//               are not yet offered by the Unix or BaseUnix units.
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
  PF_CAN             = 29;
  AF_CAN             = PF_CAN;
  SOCK_RAW           = 3;
  CAN_RAW            = 1;
  SIOCGIFMTU         = $8921;
  SIOCGIFHWADDR      = $8927;
  SIOCGIFINDEX       = $8933;
  ARPHRD_CAN         = 280;
  IFNAMSIZ           = 16;
  CAN_MTU            = 16;   // sizeof(struct can_frame)
  CANFD_MTU          = 72;   // sizeof(struct canfd_frame)
  CAN_RAW_FD_FRAMES  = 5;
  SOL_CAN_BASE       = 100 ;
  SOL_CAN_RAW        = SOL_CAN_BASE + CAN_RAW;
  F_GETFL            = 3;
  F_SETFL            = 4;
  O_NONBLOCK         = 2048;


//***************************************************************************************
// Type definitions
//***************************************************************************************
type
  psockaddr = ^tsockaddr;
  tsockaddr = record
    sa_family: cushort;
    sa_data: array[0..13] of cuchar;
  end;

  pifaddrs = ^tifaddrs;
  tifaddrs = record
    ifa_next: pifaddrs;
    ifa_name: pcchar;
    ifa_flags: cuint;
    ifa_addr: psockaddr;
    ifa_netmask: psockaddr;
    ifa_ifu: pointer;       // union treated as single pointer
    ifa_data: pointer;
  end;

  tifreq = record
    ifr_name: array[0..IFNAMSIZ - 1] of Char;
    case Integer of
      0: (ifr_addr:      tsockaddr);
      1: (ifr_dstaddr:   tsockaddr);
      2: (ifr_broadaddr: tsockaddr);
      3: (ifr_netmask:   tsockaddr);
      4: (ifr_hwaddr:    tsockaddr);
      5: (ifr_flags:     cshort);
      6: (ifr_ifindex:   cint);
      7: (ifr_metric:    cint);
      8: (ifr_mtu:       cint);
  end;

  tsockaddr_can = record
    can_family:   cushort;
    can_ifindex:  cint;
    can_rx_id:    culong;
    can_tx_id:    culong;
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
function setsockopt(sockfd: cint; level, optname: cint; optval: Pointer; optlen: cuint): cint;
          cdecl; external 'c' name 'setsockopt';
function  bind(sockfd: cint; addr: Pointer; addrlen: cuint): cint;
          cdecl; external 'c' name 'bind';


implementation

end.
//******************************** end of canunix.pas ***********************************

