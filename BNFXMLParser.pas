unit BNFXMLParser;

interface

uses SysUtils, StrUtils;

type
  PXMLNode = ^TXMLNode;

  TXMLValues = (TextNode, XMLNode);
  TXMLNode = record
    Name: string;
    Attributes: array of record
      Name: string;
      Value: string;
    end;
    SubNodes: array of record
      RecType: TXMLValues;
      case TXMLValues of
        TextNode: (Text: PString);
        XMLNode: (XML: PXMLNode);
    end;
    Parent: PXMLNode;
  end;

function BNFXMLTree(var Value: string): PXMLNode;

implementation

function fnTEG(var Node: PXMLNode; var Value: string): boolean; forward;
function fnVAL(var Node: PXMLNode; var Value: string): boolean; forward;
function fnATT(var Node: PXMLNode; var Value: string): boolean; forward;

function fnXML(var Node: PXMLNode; var Value: string): boolean;
var
  i: integer;
begin
  if (Pos('<', Value) > 0)
    and (Pos('>', Value) > Pos('<', Value))
    and (Pos('<', Value) <> Pos('</', Value)) then
  begin
    // ???????? ????
    if Node = nil then
    begin
      New(Node);
      Node.Parent := nil;
    end
    else
    begin
      i := length(Node.SubNodes);
      Setlength(Node.SubNodes, i + 1);
      New(Node.SubNodes[i].XML);
      Node.SubNodes[i].RecType := XMLNode;
      Node.SubNodes[i].XML.Parent := Node;
      Node := Node.SubNodes[i].XML;
    end;
    Result := fnTEG(Node, Value);
  end // '<'
  else
    Result := True;
end;

function fnTEG(var Node: PXMLNode; var Value: string): boolean;
var
  i, i1, i2, i3: integer;
  S: string;
begin
  Result := False;
  i1 := Pos('<', Value);
  if i1 > 0 then
  begin
    i2 := PosEx('/>', Value, i1);
    i3 := PosEx('>', Value, i1);
    if (i2 > 0) and (i2 < i3) then
    begin // <abc/>
      // Value
      S := Copy(Value, i1 + 1, (i2 - i1) - 1);
      Delete(Value, i1, (i2 - i1) + 2);
      // TEXT, ???? ????? ??????????? ??????
      if Node.Parent <> nil then
      begin // ?????????? ? ??????
        i := length(Node.Parent.SubNodes);
        Setlength(Node.Parent.SubNodes, i + 1);
        New(Node.Parent.SubNodes[i].Text);
        Node.Parent.SubNodes[i].RecType := TextNode;
        Node.Parent.SubNodes[i].Text^ := Copy(Value, 1, Pos('<', Value) - 1);
      end;
      Delete(Value, 1, Pos('<', Value) - 1);
      //
      if fnVAL(Node, S) then
      begin // ????????? ????? ?? ??????
        Node := Node.Parent;
        Result := fnXML(Node, Value);
      end;
    end
    else
    begin // <abc>...</abc>
      // Value
      S := Copy(Value, i1 + 1, (i3 - i1) - 1);
      Delete(Value, i1, (i3 - i1) + 1);
      // TEXT
      i := length(Node.SubNodes);
      Setlength(Node.SubNodes, i + 1);
      New(Node.SubNodes[i].Text);
      Node.SubNodes[i].RecType := TextNode;
      Node.SubNodes[i].Text^ := Copy(Value, 1, Pos('<', Value) - 1);
      Delete(Value, 1, Pos('<', Value) - 1);
      //
      if fnVAL(Node, S) then
      begin // Val
        // ???????? ???????? ????, ?????? ????? ? ??????? ?????????? ??????
        if Pos('</' + AnsiLowerCase(Node.Name) + '>', AnsiLowerCase(Value)) = 1
          then
        begin
          Delete(Value, 1, Length('</' + Node.Name + '>'));
          // TEXT ????????????? ??????
          if Node.Parent <> nil then
          begin // ?????????? ? ??????
            i := length(Node.Parent.SubNodes);
            Setlength(Node.Parent.SubNodes, i + 1);
            New(Node.Parent.SubNodes[i].Text);
            Node.Parent.SubNodes[i].RecType := TextNode;
            Node.Parent.SubNodes[i].Text^ := Copy(Value, 1, Pos('<', Value) -
              1);
          end;
          Delete(Value, 1, Pos('<', Value) - 1);
          Node := Node.Parent;
          Result := fnXML(Node, Value);
        end
        else
        begin
          // ??????????? ????????? ????, ?? ?????? ??? ????
          if fnXML(Node, Value) then
          begin
            // ???????? ???
            if Pos('</' + AnsiLowerCase(Node.Name) + '>', AnsiLowerCase(Value))
              = 1 then
            begin
              Delete(Value, 1, Length('</' + Node.Name + '>'));
              // TEXT ????????????? ??????
              if Node.Parent <> nil then
              begin // ?????????? ? ??????
                i := length(Node.Parent.SubNodes);
                Setlength(Node.Parent.SubNodes, i + 1);
                New(Node.Parent.SubNodes[i].Text);
                Node.Parent.SubNodes[i].RecType := TextNode;
                Node.Parent.SubNodes[i].Text^ := Copy(Value, 1, Pos('<', Value)
                  - 1);
              end;
              Delete(Value, 1, Pos('<', Value) - 1);
            end;
            // ????????? XML - ??????
            if Node.Parent <> nil then
              Node := Node.Parent;
            Result := fnXML(Node, Value);
          end;
        end;
      end; // Val
    end; // <abc>...</abc>
  end; // i1
end;

function fnVAL(var Node: PXMLNode; var Value: string): boolean;
begin
  Value := AnsiReplaceStr(Value, '''', '"');
  if (Pos(' ', Value) > 0)
    and (Pos('="', Value) > Pos(' ', Value)) then
  begin
    Node.Name := Trim(Copy(Value, 1, Pos(' ', Value) - 1)); // ???????? ???? Name
    Delete(Value, 1, Pos(' ', Value));
    Result := fnATT(Node, Value);
  end // ' ' ? ('="'
  else
  begin
    // ???????? ???? Name
    Value := Trim(Value);
    if Pos(' ', Value) > 0 then
      Node.Name := Copy(Value, 1, Pos(' ', Value) - 1)
    else
      Node.Name := Value;
    Value := '';
    Result := True;
  end;
end;

function fnATT(var Node: PXMLNode; var Value: string): boolean;
begin
  Result := True;
  Value := Trim(Value);
  if Pos('="', Value) > 0 then
  begin
    Result := False;
    SetLength(Node.Attributes, Length(Node.Attributes) + 1);
    // ???????? ????????
    Node.Attributes[Length(Node.Attributes) - 1].Name := Trim(Copy(Value, 1,
      Pos('="', Value) - 1));
    Delete(Value, 1, Pos('="', Value) + 1);
    if Pos('"', Value) > 0 then
    begin
      // ???????? ????????
      Node.Attributes[Length(Node.Attributes) - 1].Value := Copy(Value, 1,
        Pos('"', Value) - 1);
      Delete(Value, 1, Pos('"', Value));
      if Length(Value) > 0 then
        Result := fnATT(Node, Value)
      else
        Result := True;
    end;
  end;
end;

function BNFXMLTree(var Value: string): PXMLNode;
begin
  Result := nil;
  fnXML(Result, Value);
end;

end.
