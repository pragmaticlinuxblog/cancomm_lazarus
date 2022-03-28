unit MainUnit;
//***************************************************************************************
//  Description: Contains the main user interface for the demo application
//    File Name: mainunit.pas
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
// Includes
//***************************************************************************************
uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, CanComm, StdCtrls;


//***************************************************************************************
// Type Definitions
//***************************************************************************************
type
  //------------------------------ TMainForm --------------------------------------------
  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FCanContext: TCanComm;
  public

  end;


//***************************************************************************************
// Global Variables
//***************************************************************************************
var
  MainForm: TMainForm;

implementation

{$R *.lfm}

//---------------------------------------------------------------------------------------
//-------------------------------- TMainForm --------------------------------------------
//---------------------------------------------------------------------------------------
//***************************************************************************************
// NAME:           FormCreate
// PARAMETER:      Sender Source of the event.
// RETURN VALUE:   none
// DESCRIPTION:    Form constructor.
//
//***************************************************************************************
procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCanContext := CanCommNew;
end; //*** end of FormCreate ***


//***************************************************************************************
// NAME:           FormDestroy
// PARAMETER:      Sender Source of the event.
// RETURN VALUE:   none
// DESCRIPTION:    Form destructor.
//
//***************************************************************************************
procedure TMainForm.FormDestroy(Sender: TObject);
begin
  CanCommFree(FCanContext);
end; //*** end of FormDestroy ***

end.
//******************************** end of mainunit.pas **********************************

