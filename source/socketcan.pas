{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit socketcan;

{$warn 5023 off : no warning about unused units}
interface

uses
  CanComm, CanSocket, CanDevices, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('CanSocket', @CanSocket.Register);
end;

initialization
  RegisterPackage('socketcan', @Register);
end.
