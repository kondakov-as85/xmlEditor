unit xmlItem;

interface

type
    TParam = Record
        name : string;
        value  : string;
    end;
    mParam = array of TParam;
    //tagType = (message,id,catalog,hierarchy,item,categories,category,data,attribute,values,value);
TXmlItem = class(TObject)
protected
  name:String;
  param:mParam;
  value:string;
  parent:integer;

public
    constructor Create;
    destructor  Destroy; override;
    procedure setParams(p:mParam);

    property nameItem: String read name write name;
    property valueItem: string read value write value;
    property parentIndex: integer read parent write parent;
    property paramsMas: mParam read param write setParams;

end;

implementation  

{ TXmlItem }

constructor TXmlItem.Create;
begin

end;

destructor TXmlItem.Destroy;
begin 
  inherited;
end;

procedure TXmlItem.setParams(p: mParam);
begin
    param := p;
end;

end.
