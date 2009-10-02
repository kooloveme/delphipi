{ **
  DelphiPI (Delphi Package Installer)
  Author  : ibrahim dursun (t-hex) thex [at] thexpot ((dot)) net
  License : GNU General Public License 2.0
  ** }
unit TreeModel;
interface

uses Classes, StrUtils, Generics.Collections;
type
  TDynStrArray = array of string;

  INode = interface
     function GetDisplayName: string;
     function GetData: TObject;
     function GetNodePath: string;
  end;

  TCreateLogicalNodeHandler<T> = reference to function(name, path:string):T;
  TTreeModelBase<T: INode > = class
  private
    fOnCreateLogicalNode: TCreateLogicalNodeHandler<T>;
  protected
    function DoCreateLogicalNode(name, path:string):T; virtual;
  public
    function GetChild(const parent: T; index: Integer): T; virtual; abstract;
    function GetChildCount(const parent: T): integer; virtual; abstract;
    property OnCreateLogicalNode: TCreateLogicalNodeHandler<T> read fOnCreateLogicalNode write fOnCreateLogicalNode;
  end;

  TTreeViewModel<T : INode> = class(TTreeModelBase<T>)
  private
    fNodes : TList<T>;
    function SplitString(const str:string):TDynStrArray;
  public
    constructor Create(const nodes: TList<T>);
    function GetChild(const parent: T; index: Integer): T; override;
    function GetChildCount(const parent: T): integer; override;
  end;

implementation

uses JclStrings;

function TTreeModelBase<T>.DoCreateLogicalNode(name, path: string): T;
begin
  if Assigned(fOnCreateLogicalNode) then
    Result := fOnCreateLogicalNode(name,path)
  else
    Result := default(T);
end;


function TTreeViewModel<T>.SplitString(const str:string):TDynStrArray;
var
  I, lastIndex: Integer;
  words : TStringList;
begin
  words := TStringList.Create;
  try
    ExtractStrings(['\'], [], PWideChar(str), words);
    SetLength(Result, words.Count);
    for I := 0 to words.Count - 1 do
      Result[i] := words[i];
  finally
    words.Free;
  end;
end;

{ TBasicTreeModel }
constructor TTreeViewModel<T>.Create(const nodes: TList<T>);
begin
  fNodes := nodes;
end;

function TTreeViewModel<T>.GetChild(const parent: T; index: Integer): T;
var
  prefix, nodePath: string;
  node: T;
  words: TDynStrArray;
  I, currentLevel, nextLevel : integer;
  immediateChild: boolean;
  list : TStringList;
  nodes: TList<T>;
begin
  Result := default(T);

  prefix := '';
  currentLevel := 0;
  nextLevel := 0;
  if parent <> nil then
  begin
    prefix := parent.GetNodePath;
    currentLevel := StrCharCount(prefix, '\');
    nextLevel := currentLevel + 1;
  end;

  i := 0;
  list := TStringList.Create;
  list.Sorted := true;
  list.Duplicates := dupIgnore;
  try
    for node in fNodes do
    begin
      nodePath := node.GetNodePath;
      if not StartsStr(prefix, nodePath) then
        Continue;

      words := SplitString(nodePath);
      if Length(words) = 0 then
        Continue;

      if Length(words) <= nextLevel then
        Continue;

      list.Add(words[nextLevel]);
      if (List.Count = index+1) then
      begin
        immediateChild := Length(words) = nextLevel + 1;
        if immediateChild then
          Result := node
        else begin
          if prefix <> '' then
            Result := DoCreateLogicalNode(words[nextLevel], prefix + '\' + words[nextLevel])
          else
            Result := DoCreateLogicalNode(words[nextLevel], words[nextLevel]);
        end;
        Break;
      end;
    end;
  finally
    list.Free;
  end;
end;

function TTreeViewModel<T>.GetChildCount(const parent: T): integer;
var
  prefix: string;
  node: T;
  nodePath: string;
  words: TDynStrArray;
  I: Integer;
  list: TStringList;
  currentLevel, nextLevel : integer;
begin
  Result := 0;
  prefix := '';
  currentLevel := 0;
  nextLevel := 0;
  if parent <> nil then
  begin
    prefix := parent.GetNodePath;
    currentLevel := StrCharCount(prefix, '\');
    nextLevel := currentLevel + 1;
  end;

  list := TStringList.Create;
  list.Sorted := true;
  list.Duplicates := TDuplicates.dupIgnore;
  try
    for node in fNodes do
    begin
      nodePath := node.GetNodePath;
      if not StartsStr(prefix, nodePath) then
        Continue;

      words := SplitString(nodePath);
      if Length(words) = 0 then
        Continue;
      if Length(words) <= nextLevel then
        Continue;

      list.Add(words[nextLevel]);
    end;
  finally
    Result := list.Count;
    list.Free;
  end;
end;
end.
