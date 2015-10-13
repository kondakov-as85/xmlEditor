program xmlEditor;

uses
  Forms,
  main in 'main.pas' {Form1},
  xmlItem in 'xmlItem.pas',
  BNFXMLParser in 'BNFXMLParser.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
