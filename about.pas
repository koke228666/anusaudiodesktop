unit about;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TAbout }

  TAbout = class(TForm)
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  AboutForm: TAbout;

implementation

{$R *.lfm}

{ TAbout }

procedure TAbout.FormCreate(Sender: TObject);
begin
  AboutForm.Left := (Screen.WorkAreaRect.Width  - AboutForm.Width)  div 2;
  AboutForm.Top  := (Screen.WorkAreaRect.Height - AboutForm.Height) div 2;
end;

end.

