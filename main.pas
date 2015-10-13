unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, xmlItem, Grids, Buttons, ExtCtrls, Menus,
  ImgList, xmldom, XMLIntf, msxmldom, XMLDoc;

type
  TForm1 = class(TForm)

    Panel1: TPanel;
    Panel2: TPanel;
    XmlTree: TTreeView;
    Panel3: TPanel;
    ParamsBox: TGroupBox;
    ParamString: TStringGrid;
    ParamName: TComboBox;
    ParamValue: TEdit;
    TagBox: TGroupBox;
    TagName: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Panel4: TPanel;
    Added: TBitBtn;
    EditTag: TBitBtn;
    DelTag: TBitBtn;
    ClearTag: TBitBtn;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    OpenXML: TOpenDialog;
    SaveXML: TSaveDialog;
    ImageList1: TImageList;
    Panel5: TPanel;
    DelPar: TBitBtn;
    AddParam: TBitBtn;
    EditParam: TBitBtn;
    ClrParams: TBitBtn;
    GXml: TBitBtn;
    Memo1: TMemo;
    N5: TMenuItem;
    TagValue: TMemo;
    ParValChange: TComboBox;
    N6: TMenuItem;
    N7: TMenuItem;
    StatusBar: TStatusBar;
    procedure AddedClick(Sender: TObject);
    procedure XmlTreeChanging(Sender: TObject; Node: TTreeNode;
      var AllowChange: Boolean);
    procedure TagNameChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ParamNameChange(Sender: TObject);
    procedure ParamValueChange(Sender: TObject);
    procedure AddParamClick(Sender: TObject);

    procedure DelParClick(Sender: TObject);

    procedure DeleteRow(ARow: Integer);
    procedure RefreshParam;
    procedure DelTagClick(Sender: TObject);
    procedure ClearParams;
    procedure SaveXmlFile(sa:integer);
    procedure DeleteTag(I:integer);
    procedure EditTagClick(Sender: TObject);
    procedure ClrParamsClick(Sender: TObject);
    procedure ParamStringSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure EditParamClick(Sender: TObject);
    procedure ClearTagClick(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure SelectCell(top,left,right,bottom:integer);
    procedure GXmlClick(Sender: TObject);

    procedure OnEachNode (ARoot: TTreeNode);
    procedure PrintXml(txt:String);
    procedure insertitem(index: integer; value: TXmlItem);
    procedure N5Click(Sender: TObject);
    function TagStr(Item:TXmlItem; tab:integer):String;
    procedure TagValueChange(Sender: TObject);
    procedure ParValChangeChange(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure N7Click(Sender: TObject);
    function tabPrint(count:integer):String;
    procedure SetIcon(Node: TTreeNode);
    procedure XmlTreeGetImageIndex(Sender: TObject; Node: TTreeNode);
    procedure settingTag(tName:String);
    procedure setComboValues(combo:TComboBox;list:String);
    function GetWord(Str:string; Smb: char; WordNmbr: Byte): string;
    procedure OpenFileXML(path:String);
    function ReadFile(f: string):String;
    procedure readNode(parent:IXMLNode);
    procedure removeAllTags;

  private
    { Private declarations }
  public
    { Public declarations }
  end; 

var
  Form1: TForm1;
  currentNode:TTreeNode;
  parentId:integer;
  nameTag:String;
  valueTag:String;
  nameParam:String;
  valueParam:String;
  savePath:String;

  param:TParam;

  mParams:mParam;
  masTag:array of TXmlItem;

  ItemTag:TXmlItem;

  const version:string = '1.0';           //текущая версия
  const maxParam:integer = 4;             //максимальное число параметров
  const tabStr:char = #$9;                //для задания отступов уровней
  const tagsList = 'message,id,catalog,hierarchy,item,categories,category,data,attribute,values,value,groupvalue';
  const paramList = 'name,action,nameHier,type,pk';

  const paramCatalogList = 'name';
  const paramItemList = 'action';
  const paramCategoryList = 'nameHier';
  const paramAttributeList = 'name,type,pk';

  const actionList = 'ADDED,MODIFIED,DELETED';
  const boolList = 'TRUE,FALSE';
  const typeList = 'INTEGER,STRING,NUMBER,DATE,BINARY,GROUPING,LOOKUP_TABLE,URL,SEQUENCE,RELATIONSHIP,PASSWORD,EXTERNAL_CONTENT_REFERENCE,STRING_ENUMERATION,FLAG,UNKNOWN';

implementation

{$R *.dfm}

//Запуск приложения
procedure TForm1.FormCreate(Sender: TObject);
begin
   Form1.Caption := Form1.Caption + ' v.'+version;        //пишем заголовок формы
   setComboValues(TagName, tagsList);                     //список тегов
   setComboValues(ParamName, paramList);                  //список тегов
   nameTag := TagName.Text;                               //запоминаем имя тега
   settingTag(nameTag);
   param.name := ParamName.Text;                          //запоминаем имя параметра
   param.value := ParamValue.Text;                        //запоминаем значение тега
   valueTag := TagValue.Text; 
end;

function TForm1.GetWord(Str: string; Smb: char; WordNmbr: Byte): string;
var SWord: string;
  StrLen, N: Byte;
begin
  StrLen := SizeOf(Str);
  N := 1;
  while ((WordNmbr >= N) and (StrLen <> 0)) do
  begin
    StrLen := Pos(Smb, str);
    if StrLen <> 0 then
    begin
      SWord := Copy(Str, 1, StrLen - 1);
      Delete(Str, 1, StrLen);
      Inc(N);
    end else SWord := Str;
  end;
  if WordNmbr <= N then Result := SWord else Result := '';
end;

procedure TForm1.setComboValues(combo: TComboBox; list: String);
var str:String;
    i:integer;
begin
  combo.Items.Clear;
  i:=1;
  str := GetWord(list,',',i);
  combo.Items.Add(str);
  i:=i+1;
   while str<>'' do
     begin
         str := GetWord(list,',',i);
         if(str<>'') then
            combo.Items.Add(str);
         i:=i+1;
     end;
     combo.ItemIndex:=0;
end;

procedure TForm1.settingTag(tName:String);
var
i,sHTB,bHTB,sTTB,bTTB:integer;
begin
  sHTB := 46;
  bHTB := 192;
  sTTB := 58;
  bTTB := 210;

  if (tName='message') then begin
      TagValue.Enabled:=false;
      TagBox.Height := sHTB;
      ParamsBox.visible:=false;
      ParamsBox.Top := sTTB;
  end;
  if (tName='id') then begin
      TagValue.Enabled:=true;
      TagBox.Height := bHTB;
      ParamsBox.visible:=false;
      ParamsBox.Top := sTTB;
  end;
  if (tName='catalog') then begin
      TagValue.Enabled:=false;
      TagBox.Height := sHTB;
      ParamsBox.visible:=true;
      ParamsBox.Top := sTTB;
      setComboValues(ParamName, paramCatalogList);
      ParamNameChange(ParamName);
  end;
  if (tName='hierarchy') then begin
      TagValue.Enabled:=false;
      TagBox.Height := sHTB;
      ParamsBox.visible:=true;
      ParamsBox.Top := sTTB;
      setComboValues(ParamName, paramCatalogList);
      ParamNameChange(ParamName);
  end;
  if (tName='item') then begin
      TagValue.Enabled:=false;
      TagBox.Height := sHTB;
      ParamsBox.visible:=true;
      ParamsBox.Top := sTTB;
      setComboValues(ParamName, paramItemList);
      ParamNameChange(ParamName);
  end;
  if (tName='categories') then begin
      TagValue.Enabled:=false;
      TagBox.Height := sHTB;
      ParamsBox.visible:=false;
      ParamsBox.Top := sTTB;
  end;
  if (tName='category') then begin
      TagValue.Enabled:=true;
      TagBox.Height := bHTB;
      ParamsBox.visible:=true;
      ParamsBox.Top := bTTB;
      setComboValues(ParamName, paramCategoryList);
      ParamNameChange(ParamName);
  end;
  if (tName='data') then begin
      TagValue.Enabled:=false;
      TagBox.Height := sHTB;
      ParamsBox.visible:=false;
      ParamsBox.Top := sTTB;
  end;
  if (tName='attribute') then begin
      TagValue.Enabled:=false;
      TagBox.Height := sHTB;
      ParamsBox.visible:=true;
      ParamsBox.Top := sTTB;
      setComboValues(ParamName, paramAttributeList);
      ParamNameChange(ParamName);
  end;
  if (tName='values') then begin
      TagValue.Enabled:=false;
      TagBox.Height := sHTB;
      ParamsBox.visible:=false;
      ParamsBox.Top := sTTB;
  end;
  if (tName='value') then begin
      TagValue.Enabled:=true;
      TagBox.Height := bHTB;
      ParamsBox.visible:=false;
      ParamsBox.Top := sTTB;
  end;
  if (tName='groupvalue') then begin
      TagValue.Enabled:=false;
      TagBox.Height := sHTB;
      ParamsBox.visible:=false;
      ParamsBox.Top := sTTB;
  end;
end;  

//////////!!!ТЕГИ!!!//////////

//формируем тег для отображения
function TForm1.TagStr(Item: TXmlItem; tab:integer): String;
var
    params:mParam;
    i:integer;
    par,caption,tabulator:String;
begin
      params := Item.paramsMas;
      tabulator := tabPrint(tab);
      if(Item.nameItem='value') then
         par := ' occurrence="'+inttostr(currentNode.Count)+'"'
      else
         for i:=0 to Length(params)-1 do           //рисуем параметры
            par := par +' '+ params[i].name+'="'+params[i].value+'"';

     if Item.valueItem<>'' then                  //пишем значение если есть
        caption := tabulator+'<'+Item.nameItem+par+'>'+Item.valueItem+'</'+Item.nameItem+'>'
     else
        caption := tabulator+'<'+Item.nameItem+par+'>';

    TagStr:=caption;
end;

//добавляем тег
procedure TForm1.AddedClick(Sender: TObject);
var
  caption, par:String;
  i,sel:integer;
begin
     N2.Enabled := true;
     ItemTag := TXmlItem.Create;                //Создаем объект тег
     ItemTag.nameItem := TagName.Text;          //Имя тега
     ItemTag.valueItem := TagValue.Text;        //Значение
     ItemTag.parentIndex := parentId;           //Индекс родительского элемента
     ItemTag.setParams(mParams);                //Массив параметров

     sel := XmlTree.Items.AddChild(currentNode,TagStr(ItemTag,0)).AbsoluteIndex;  //Добавляем тег в дерево и получаем абсолютный индекс

     insertitem(sel, itemTag);                                          //сохраняем объект в массив (для удобства)

     XmlTree.SetFocus;                                                  //выделяем элемент
     XmlTree.items[sel].Selected:=true;

end;

//процедура вставки тега в массив (в любое место)
procedure TForm1.insertitem(index: integer; value: TXmlItem);
begin
    setlength(masTag,high(masTag) + 2);
    move(masTag[index],masTag[index+1],(high(masTag)-index) * sizeof(masTag[0]));
    masTag[index]:= value;
end;

//обработка редактирования тега
procedure TForm1.EditTagClick(Sender: TObject);
var
  caption, par:String;
  i:integer;
begin
    if(XmlTree.SelectionCount>0) then begin                             //если был выбран тег
       N2.Enabled :=true;

       if (ItemTag<>nil) then begin                                        //обновляем информацию в массиве тегов
          ItemTag.nameItem := nameTag;                                     //имя тега
          ItemTag.valueItem := valueTag;                                   //значение тега
          ItemTag.setParams(mParams);                                      //массив параметров
          SetLength(masTag,Length(masTag)+1);                              //
          masTag[Length(masTag)-1] := itemTag;
          currentNode.Text := TagStr(itemTag,0);
          //ClearParams;
       end;
    end;

end;

//обработка выбора элемента в дереве
procedure TForm1.XmlTreeChanging(Sender: TObject; Node: TTreeNode;
  var AllowChange: Boolean);
  var i:integer;
begin
     currentNode := Node;                                            //запоминаем выделенный Нод
     parentId := -1;
     ClearParams;                                                    //чистим таблицу парметров
     form1.Caption := Node.Text +' - '+inttostr(Node.AbsoluteIndex);

     if (Node.Parent<>nil) then                                      //если парент у тега есть
         parentId := Node.Parent.AbsoluteIndex;                      //получаем его абсолютный индекс, иначе -1

     ItemTag := masTag[Node.AbsoluteIndex];                          //по индексу находим элемент в массиве
     TagName.text := ItemTag.nameItem;                               //заполняем поля наименования тега
     TagValue.Text := ItemTag.valueItem;                             //заполняем поле значения тега

     mParams := ItemTag.paramsMas;                                   //получаем массив параметров
     ParamString.RowCount := length(mParams);                        //рисуем столько строк в таблице, сколько параметров у тега

     for i:=0 to length(mParams)-1 do begin                          //рисуем параметры
         ParamString.Cells[0,i] := mParams[i].name;                  //имя
         ParamString.Cells[1,i] := mParams[i].value;                 //значение
     end;

     StatusBar.Panels.Items[0].Text := 'Current tag: '+TagName.Text;
     StatusBar.Panels.Items[0].Width := 125;
     StatusBar.Panels.Items[1].Text := 'Index: '+inttostr(Node.AbsoluteIndex);

end;

//процедура удаления тега из массива
procedure TForm1.DeleteTag(I: integer);
var k,fSize:integer;
begin
    fSize := length(masTag);
    if i<fSize then
      for k:=i to FSize-1 do
           masTag[k]:=masTag[k+1]
    else exit;
    SetLength(masTag,FSize-1);
end;

//обработка удаления тега
procedure TForm1.DelTagClick(Sender: TObject);
begin
  if XmlTree.SelectionCount>0 then begin              //если выбран тег
     N2.Enabled := true; 
     DeleteTag(XmlTree.Selected.AbsoluteIndex);       //удаляем тег из массива
     XmlTree.Selected.Delete;                         //удаляем из дерева
     currentNode := nil;
  end;
end;

//обработка очистки дерева тегов
procedure TForm1.ClearTagClick(Sender: TObject);
begin
    removeAllTags;
end;

procedure TForm1.removeAllTags;
begin
    XmlTree.Items.Clear;                                  //чистим дерево
    SetLength(masTag,0);                                  //обнуляем массив
    ItemTag.Free;                                         //убиваем объект
    currentNode := nil;                                   //обнуляем текущий тег
end;

//обработка выбора типа тега
procedure TForm1.TagNameChange(Sender: TObject);
begin
  nameTag := TagName.Text;                                           //запомним имя тега
  ClearParams;                                                       //чистим таблицу параметров
  SetLength(mParams,0);                                              //обнуляем массив параметров
  settingTag(nameTag);
end;

//обработка редактирования поля значения тега
procedure TForm1.TagValueChange(Sender: TObject);
begin
    valueTag := TagValue.Text;                                       //запоминаем значение тега
end;

//////////!!!ПАРАМЕТРЫ!!!//////////
//обработка выбора типа параметра
procedure TForm1.ParamNameChange(Sender: TObject);
begin
    param.name := ParamName.Text;                                        //запоминаем имя параметра
    ParamValue.Text:='';
    ParValChange.Text := '';                                                 //обнуляем поле значения
    if(ParamName.Text='action') then
    begin
         ParamValue.Visible := false;
         ParValChange.Visible := true;
         setComboValues(ParValChange, actionList);
         ParValChangeChange(ParValChange);
    end else if(ParamName.Text='pk') then
    begin
         ParamValue.Visible := false;
         ParValChange.Visible := true;
         setComboValues(ParValChange, boolList);
         ParValChangeChange(ParValChange);
    end else if(ParamName.Text='type') then begin
        ParamValue.Visible := false;
        ParValChange.Visible := true;
        setComboValues(ParValChange, typeList);
        ParValChangeChange(ParValChange);
    end else begin
        ParamValue.Visible := true;
         ParValChange.Visible := false;
    end;
end;

//обработка редактирования поля значения параметра
procedure TForm1.ParamValueChange(Sender: TObject);
begin
    param.value := ParamValue.Text;                                  //запоминаем значение параметра
end;

//добавляем параметр
procedure TForm1.AddParamClick(Sender: TObject);
var pName:String;
begin
      if (ParamString.RowCount<maxParam) then begin                         //ограничиваем количество параметров
        if (ParamString.Cells[0,0] <> '') then
            ParamString.RowCount := ParamString.RowCount + 1;
        ParamString.Cells[0,ParamString.RowCount-1] := param.name;          //отображаем выбранное имя
        ParamString.Cells[1,ParamString.RowCount-1] := param.value;         //отображаем значение
        RefreshParam;                                                       //обновляем массив параметров
        SelectCell(ParamString.RowCount-1,0,1,ParamString.RowCount-1);      //выделяем добавленный параметр в таблице
      end;                                                            
end;

//удаление параметра
procedure TForm1.DelParClick(Sender: TObject);
begin
    DeleteRow(ParamString.Selection.Bottom);
end;

//процедура удаления парамтра из таблицы
procedure TForm1.DeleteRow(ARow: Integer);
var i, j: Integer;
begin
with ParamString do
  begin
    for i:=ARow+1 to RowCount-1 do
    for j:=0 to ColCount-1 do
      Cells[j, i-1]:=Cells[j, i];
    for i:=0 to ColCount-1 do
      Cells[i, RowCount-1]:='';
    RowCount:=RowCount-1;
  end;
  RefreshParam;                      //обновляем массив
end;

//процедура обновления массива параметров
procedure TForm1.RefreshParam;
var i,j:integer;
begin
    j:=0;
    SetLength(mParams,0);                             //обнуляем массив
    for i:=0 to ParamString.RowCount-1 do begin       //заносим параметры в массив из таблицы
    if(ParamString.Cells[0,0]<>'') then begin
        j:=j+1;
        SetLength(mParams,j);
        param.name := ParamString.Cells[0,i];
        param.value := ParamString.Cells[1,i];
        mParams[j-1] := param;
       end;
    end;
end;

//процедура чистки таблицы параметров
procedure TForm1.ClearParams;
begin
    TagValue.Text := '';                             //чистим поле значения
    ParamValue.Text := '';                           //чистим поле значения
    ParamString.RowCount := 1;                       //удаляем строки
    ParamString.Cells[0,0] := '';                    //чистим поле наименования в таблице
    ParamString.Cells[1,0] := '';                    //чистим поле значения в таблице
end;

//обработка очистки параметров
procedure TForm1.ClrParamsClick(Sender: TObject);
begin
  ClearParams;
end;

//обряботка выделения параметра в таблице
procedure TForm1.ParamStringSelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
begin
    ParamName.Text := ParamString.Cells[0,ARow];
    ParamValue.Text := ParamString.Cells[1,ARow];
end;

//обработка нажатия редактирования параметра
procedure TForm1.EditParamClick(Sender: TObject);
var selRow:integer;
begin
     if (length(mParams)<>0) then begin                   //если массив параметров не пуст
        selRow := ParamString.Selection.Bottom;           //получим индекс выделенного параметра
        ParamString.Cells[0,selRow] := ParamName.Text;    //рисуем имя параметра в таблице
        ParamString.Cells[1,selRow] := ParamValue.Text;   //рисуем значение параметра в таблице
        RefreshParam;
     end;
end;

//обработка выделения строки в таблице
procedure TForm1.SelectCell(top, left, right, bottom: integer);
var  hGridRect: TGridRect;
begin
    hGridRect.Top := top;
    hGridRect.Left := left;
    hGridRect.Right := right;
    hGridRect.Bottom := bottom;
    ParamString.Selection := hGridRect;
end;

//процедура сохранения в файл
//sa = 0 сохранить
//sa = 1 сохранить как
procedure TForm1.SaveXmlFile(sa:integer);
var i:integer;
Item:TXmlItem;
rootName: String;
s:boolean;
begin
    //if(memo1.Text<>'') then begin
    if(length(masTag)>0) then begin                //если массив тегов не пустой
        memo1.Lines.Clear;                          //чистим мемо
        rootName := masTag[0].nameItem;             //получаем имя рутового элемента
        PrintXml('<'+rootName+'>');                 //печатаем рутовый элемент
        OnEachNode(XmlTree.Items.Item[0]);          //пробегаем по дочерним элемента и печатаем их
        PrintXml('</'+rootName+'>');                //печатаем конец рутового элемента
     end;


    if(sa=1) then begin
       if SaveXML.Execute then
          savePath := SaveXML.FileName;
    end else
        if (savePath='') then
            if SaveXML.Execute then
               savePath := SaveXML.FileName;
    
    s:=false;
    if(FileExists(savePath)) then begin
       if MessageBox(Handle,'Заменить файл?','Сохранение...',mb_YesNo)=mrYes then
          s:=true;
    end else s:=true;
    
    if(s)then begin
      memo1.Lines.SaveToFile(savePath);
      N2.Enabled := false;
    end;
    //end;
end;

//////////!!!ГЕНЕРАЦИЯ СООБЩЕНИЯ!!!//////////
//генерация текста результирующей xml
procedure TForm1.GXmlClick(Sender: TObject);
var i:integer;
Item:TXmlItem;
rootName: String;
begin
     if(length(masTag)>0) then begin                //если массив тегов не пустой
        memo1.Lines.Clear;                          //чистим мемо
        rootName := masTag[0].nameItem;             //получаем имя рутового элемента
        PrintXml('<'+rootName+'>');                 //печатаем рутовый элемент
        OnEachNode(XmlTree.Items.Item[0]);          //пробегаем по дочерним элемента и печатаем их
        PrintXml('</'+rootName+'>');                //печатаем конец рутового элемента
     end;
end;

//рекурсивное считывание тегов
procedure TForm1.OnEachNode(ARoot: TTreeNode);
var
 I: Integer;
 ANode: TTreeNode;
 tagText:String;
 item:TXmlItem;
 par:String;
 lev:integer;
begin
// перебираем рекурсивно всех детей
 for I := 0 to ARoot.Count-1 do begin
   item := masTag[ARoot.Item[I].AbsoluteIndex];
   lev := ARoot.Item[I].Level;
   tagText := item.nameItem; 

   if (item.valueItem = '') and (ARoot.Item[I].getFirstChild = nil) then
       PrintXml(tabPrint(lev)+'<'+tagText+'/>')

   else begin
       PrintXml(TagStr(item,lev));
       OnEachNode (ARoot.Item[I]);
       if (ARoot.Item[I].getFirstChild <> nil) then
          PrintXml(tabPrint(lev)+'</'+tagText+'>');
   end;
 end;  
end;

//печать строки в мемо
procedure TForm1.PrintXml(txt:String);
begin
  memo1.Lines.Add(txt);
end;

//////////!!!ОБРАБОТКА МЕНЮ!!!//////////
//обработка выхода из программы
procedure TForm1.N4Click(Sender: TObject);
begin
    Close;
end;

//открыть файл
procedure TForm1.N1Click(Sender: TObject);
begin
  if OpenXML.Execute then
    OpenFileXML(OpenXML.FileName);
end;

//сохраненить
procedure TForm1.N2Click(Sender: TObject);
begin
    SaveXmlFile(0);
end;

//сохранить как
procedure TForm1.N5Click(Sender: TObject);
begin
    SaveXmlFile(1);
end; 

procedure TForm1.ParValChangeChange(Sender: TObject);
begin
    param.value := ParValChange.Text;                                  //запоминаем значение параметра
end;

procedure TForm1.N6Click(Sender: TObject);
begin
  ShowMessage('Функция в разработке!!!');
end;

procedure TForm1.N7Click(Sender: TObject);
begin
    ShowMessage('Функция в разработке!!!');
end;

function TForm1.tabPrint(count: integer): String;
var i:integer;
rez:String;
tab:char;
begin
  tab := tabStr;
  rez := '';
  for i:=0 to count-1 do
      rez := rez+tab;
  tabPrint := rez;
end;

procedure TForm1.SetIcon(Node: TTreeNode);
var indx : integer;
begin
    node.ImageIndex := 1;
    if node.getFirstChild = nil then
       node.ImageIndex := 2
end;

procedure TForm1.XmlTreeGetImageIndex(Sender: TObject; Node: TTreeNode);
begin
  SetIcon(Node);
end;

procedure TForm1.OpenFileXML(path: String);
var
  S,nameTag,value: string;

  XMLDoc: IXMLDocument;
  Root,Node,NodeSvc: IXMLNode;
  l,i: Integer;


begin

    removeAllTags;


    XMLDoc:= TXMLDocument.Create(nil);
    XMLDoc.LoadFromFile(path);
    XMLDoc.Active := True;
    Root := XMLDoc.DocumentElement;
    readNode(Root);
    
end;


procedure TForm1.readNode(parent: IXMLNode);
var
  i,index:integer;
  Node,NodeSvc: IXMLNode;
  S,nameTag,value: string;
  ItemTag: TXmlItem;
begin
for i:=0 to parent.ChildNodes.Count-1 do
    begin
        Node := parent.ChildNodes[i];
        nameTag := Node.NodeName;

        ItemTag := TXmlItem.Create;                //Создаем объект тег
        ItemTag.nameItem := nameTag;          //Имя тега

        if(Node.ChildNodes.Count=0) then begin
          value := Node.Text;
          ItemTag.valueItem := value;        //Значение
          //ItemTag.parentIndex := parentId;           //Индекс родительского элемента
          //ItemTag.setParams(mParams);                //Массив параметров
          index := Length(masTag);
          insertitem(index, itemTag);
        end else begin
          index := Length(masTag);
          insertitem(index, itemTag);
          readNode(Node);
        end;

                                                 //сохраняем объект в массив (для удобства)

        //XmlTree.SetFocus;                                                  //выделяем элемент
        //XmlTree.items[index].Selected:=true;




        //ShowMessage(nameTag);



    end;
end;


//чтение из файла
function TForm1.ReadFile(f: string):String;
var
   infile: TextFile;
   line,sp:string;
   i,b,l : integer;
   res :String;
begin
    if FileExists(f) then begin
      assignfile(infile, f);   //дескриптор файла
      reset(infile);
      res := '';
      repeat
        Readln(infile, line);
        res := res + line;
      until Eof(infile);
      closefile(infile);
   end;
   ReadFile := res;
end;





end.

