unit CanDevices;
//***************************************************************************************
//  Description: CAN devices unit.
//    File Name: candevices.pas
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
  Classes, SysUtils, CanComm;


//***************************************************************************************
// Type definitions
//***************************************************************************************
type
  //---------------------------------- TCanDevices --------------------------------------
  // Class for convenient access to the CAN devices detected on the system.
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


end.
//******************************** end of candevices.pas ********************************

