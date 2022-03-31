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
  Classes, SysUtils, CanMsg;


//***************************************************************************************
// Type definitions
//***************************************************************************************
type
  //---------------------------------- TCanMsgReceivedEvent -----------------------------
  TCanMsgReceivedEvent = procedure(Sender: TObject; Msg: TCanMsg) of object;

  //---------------------------------- TCanDriver ---------------------------------------
  TCanDriver = class(TComponent)
  private
    { Private declarations }
  protected
    { Protected declarations }
    // TODO Add a FContext field.
    FConnected : Boolean;
    FOnMsgReceived: TCanMsgReceivedEvent;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    function    Transmit(Msg: TCanMsg): Boolean;
    { Public properties }
    // TODO Add Connected property. Could even do the connect/disconnect part there.
    property    OnMsgReceived: TCanMsgReceivedEvent read FOnMsgReceived write FOnMsgReceived;
end;

implementation
//***************************************************************************************
// Local Includes
//***************************************************************************************
uses
  CanComm;


//---------------------------------------------------------------------------------------
//-------------------------------- TCanDriver -------------------------------------------
//---------------------------------------------------------------------------------------
//***************************************************************************************
// NAME:           Create
// DESCRIPTION:    Component constructor. Calls TComponents's constructor and initializes
//                 the fields their default values.
//
//***************************************************************************************
constructor TCanDriver.Create(AOwner: TComponent);
begin
  // Call inherited constructor
  inherited Create(AOwner);
  // TODO Initialize fields
  // TODO Create the context.
end; //*** end of Create ***


//***************************************************************************************
// NAME:           Destroy
// PARAMETER:      none
// RETURN VALUE:   none
// DESCRIPTION:    Component destructor. Calls TComponent's destructor
//
//***************************************************************************************
destructor TCanDriver.Destroy;
begin
  // TODO Disconnect if connected and free the context.
  // Call inherited destructor
  inherited Destroy;
end; //*** end of Destroy ***


//***************************************************************************************
// NAME:           Transmit
// PARAMETER:      msg Message to transmit.
// RETURN VALUE:   True if successful, False otherwise.
// DESCRIPTION:    Submits a CAN message for transmission.
//
//***************************************************************************************
function TCanDriver.Transmit(msg: TCanMsg): Boolean;
begin
  // Give the result back to the caller.
  Result := False;
end; //*** end of Transmit ***


end.
//******************************** end of candriver.pas *********************************

