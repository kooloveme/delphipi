{ **
  DelphiPI (Delphi Package Installer)
  Author  : ibrahim dursun (t-hex) thex [at] thexpot ((dot)) net
  License : GNU General Public License 2.0
  ** }
unit PageShowPackageList;

interface

uses
  CompilationData, Windows, Messages, SysUtils, Variants, Classes, Graphics, StdCtrls, Controls, Forms,
  Dialogs, PageBase, ComCtrls, PackageInfo, ImgList, WizardIntfs, Menus, VirtualTrees, PackageDependencyVerifier,
  ActnList, InstalledPackageResolver, TreeModel, ListViewModel, ToolWin;

type

  TPackageViewType = (pvtTree, pvtList);
  TShowPackageListPage = class(TWizardPage)
    pmSelectPopupMenu: TPopupMenu;
    miSelectAll: TMenuItem;
    miUnselectAll: TMenuItem;
    miSelectMatching: TMenuItem;
    N1: TMenuItem;
    ImageList: TImageList;
    miUnselectMatching: TMenuItem;
    fPackageTree: TVirtualStringTree;
    lblWait: TLabel;
    N2: TMenuItem;
    miCollapse: TMenuItem;
    miExpand: TMenuItem;
    miCollapseChildren: TMenuItem;
    miCollapseAll: TMenuItem;
    miExpandChildren: TMenuItem;
    miExpandAll: TMenuItem;
    ActionList: TActionList;
    actRemove: TAction;
    Remove1: TMenuItem;
    N3: TMenuItem;
    toolbar: TToolBar;
    btnFolderView: TToolButton;
    sepearator1: TToolButton;
    ilActionImages: TImageList;
    pmViewStyles: TPopupMenu;
    FolderTree1: TMenuItem;
    List1: TMenuItem;
    actChangeViewToTree: TAction;
    actChangeViewToList: TAction;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure packageTreeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure packageTreeGetNodeDataSize(Sender: TBaseVirtualTree; var NodeDataSize: Integer);
    procedure miSelectAllClick(Sender: TObject);
    procedure miUnselectAllClick(Sender: TObject);
    procedure miSelectMatchingClick(Sender: TObject);
    procedure miUnselectMatchingClick(Sender: TObject);
    procedure packageTreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean;
      var ImageIndex: Integer);
    procedure fPackageTreeGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle;
      var HintText: string);
    procedure fPackageTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure fPackageTreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType);
    procedure miCollapseAllClick(Sender: TObject);
    procedure miCollapseChildrenClick(Sender: TObject);
    procedure miExpandChildrenClick(Sender: TObject);
    procedure miExpandAllClick(Sender: TObject);
    procedure fPackageTreeKeyAction(Sender: TBaseVirtualTree; var CharCode: Word; var Shift: TShiftState; var DoDefault: Boolean);
    procedure actRemoveExecute(Sender: TObject);
    procedure actRemoveUpdate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure fPackageTreeInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure fPackageTreeInitChildren(Sender: TBaseVirtualTree;
      Node: PVirtualNode; var ChildCount: Cardinal);
    procedure actChangeViewToTreeExecute(Sender: TObject);
    procedure actChangeViewToListExecute(Sender: TObject);
  private
    packageLoadThread: TThread;
    fSelectMask: string;
    fDependencyVerifier: TPackageDependencyVerifier;
    fInstalledPackageResolver: TInstalledPackageResolver;
    fModel : TTreeModelBase<TPackageInfo>;
    procedure PackageLoadCompleted(Sender: TObject);
    procedure ChangeState(Node: PVirtualNode; checkState: TCheckState);

    procedure VerifyDependencies;
    function CreateLogicalNode(name, path: string):TPackageInfo;
    procedure SetView(const viewType:TPackageViewType);
  private
    class var criticalSection: TRTLCriticalSection;
    class constructor Create;
    class destructor Destroy;
  public
    constructor Create(Owner: TComponent; const CompilationData: TCompilationData); override;
    procedure UpdateWizardState; override;
  end;

implementation

uses JclFileUtils, gnugettext, Utils, PackageInfoFactory, VirtualTreeHelper, Generics.Collections;
{$R *.dfm}

var
  threadWorking: Boolean;

type
  TPackageLoadThread = class(TThread)
  private
    fCompilationData: TCompilationData;
    fPackageInfoFactory: TPackageInfoFactory;
    fActive: Boolean;
    procedure LoadPackageInformations(const directory: string);
  protected
    procedure Execute; override;
    procedure Search(const folder: String);
  public
    constructor Create(data: TCompilationData);
    destructor Destroy; override;
    property Active: Boolean read fActive write fActive;
  end;

  { TShowPackageListPage }

constructor TShowPackageListPage.Create(Owner: TComponent; const CompilationData: TCompilationData);
begin
  inherited;
  fCompilationData := CompilationData;

  if not DirectoryExists(fCompilationData.BaseFolder) then
    exit;

  fInstalledPackageResolver := TInstalledPackageResolver.Create(CompilationData);
  fInstalledPackageResolver.AddDefaultPackageList;
  fInstalledPackageResolver.AddIDEPackageList(CompilationData);
  fDependencyVerifier := TPackageDependencyVerifier.Create;

  SetView(pvtTree);

  packageLoadThread := TPackageLoadThread.Create(fCompilationData);
  with packageLoadThread do
  begin
    OnTerminate := PackageLoadCompleted;
    lblWait.Visible := true;
    threadWorking := true;
    fPackageTree.Visible := false;
    Resume;
  end;
end;

class constructor TShowPackageListPage.Create;
begin
  InitializeCriticalSection(criticalSection);
end;

function TShowPackageListPage.CreateLogicalNode(name,
  path: string): TPackageInfo;
begin
  Result := TPackageInfo.Create;
  Result.FileName := path;
  Result.PackageName := name;
end;

class destructor TShowPackageListPage.Destroy;
begin
  DeleteCriticalSection(criticalSection);
end;

procedure TShowPackageListPage.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  if threadWorking then
  begin
    TPackageLoadThread(packageLoadThread).Active := false;
    packageLoadThread.WaitFor;
    packageLoadThread.Free;
    exit;
  end;

  fPackageTree.Traverse(fPackageTree.RootNode, procedure(Node: PVirtualNode)
  var
    data: PNodeData;
  begin
    if Node.checkState <> csCheckedNormal then
      exit;

    data := fPackageTree.GetNodeData(Node);
    if (data <> nil) and (data.Info <> nil) then
      fCompilationData.PackageList.Add(data.Info);
  end);

  FreeAndNil(fDependencyVerifier);
  FreeAndNil(fInstalledPackageResolver);
  FreeAndNil(fModel);
end;

procedure TShowPackageListPage.FormCreate(Sender: TObject);
begin
  inherited;
  TranslateComponent(Self);
end;

procedure TShowPackageListPage.PackageLoadCompleted(Sender: TObject);
begin
  threadWorking := false;
  if TPackageLoadThread(packageLoadThread).Active then
  begin
    lblWait.Visible := false;
    fPackageTree.RootNodeCount := fModel.GetChildCount(nil);
    fPackageTree.Visible := true;
    fPackageTree.FullExpand;

    VerifyDependencies;
    UpdateWizardState;
  end;
end;

procedure TShowPackageListPage.ChangeState(Node: PVirtualNode; checkState: TCheckState);
var
  child: PVirtualNode;
begin
  if Node = nil then
    exit;
  Node.checkState := checkState;
  child := Node.FirstChild;
  while child <> nil do
  begin
    ChangeState(child, checkState);
    child := child.NextSibling;
  end;
end;

procedure TShowPackageListPage.UpdateWizardState;
var
  button: TButton;
  selectedPackageCount: integer;
begin
  inherited;
  wizard.SetHeader(_('Select Packages'));
  wizard.SetDescription(_('Select packages that you want to compile.'));
  button := wizard.GetButton(wbtNext);
  button.Enabled := (not threadWorking);
  if not threadWorking then
  begin
    button := wizard.GetButton(wbtNext);
    button.Caption := _('Compile');
    selectedPackageCount := 0;
    fPackageTree.Traverse( procedure(Node: PVirtualNode)begin if Node.checkState = csCheckedNormal then inc(selectedPackageCount); end);
    button.Enabled := selectedPackageCount > 0;
  end;
end;

procedure TShowPackageListPage.VerifyDependencies;
var
  selectedPackages: TList<TPackageInfo>;
begin
  selectedPackages := TList<TPackageInfo>.Create;
  try
    fPackageTree.Traverse(procedure(Node: PVirtualNode)
    var
      data: PNodeData;
    begin
      if Node.checkState <> csCheckedNormal then
        exit;

      data := fPackageTree.GetNodeData(Node);
      if (data <> nil) and (data.Info <> nil) then
         selectedPackages.Add(data.Info);
    end);

    fDependencyVerifier.Verify(selectedPackages, fInstalledPackageResolver);
  finally
    selectedPackages.Free;
  end;

  fPackageTree.BeginUpdate;
  try
    fPackageTree.TraverseData( procedure(data: PNodeData)
    begin
      data.MissingPackageName := fDependencyVerifier.MissingPackages[data.Info.PackageName];
    end);
  finally
    fPackageTree.EndUpdate;
  end;
end;

procedure TShowPackageListPage.packageTreeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  ChangeState(Node, Node.checkState);
  VerifyDependencies;
  fPackageTree.InvalidateChildren(Node, true);
  UpdateWizardState;
end;

procedure TShowPackageListPage.packageTreeGetNodeDataSize(Sender: TBaseVirtualTree; var NodeDataSize: Integer);
begin
  NodeDataSize := sizeof(TNodeData);
end;

procedure TShowPackageListPage.SetView(const viewType: TPackageViewType);
begin
  EnterCriticalSection(criticalSection);
  try
    if assigned(fModel) then
      fModel.Free;

    case viewType of
      pvtTree: fModel := TTreeViewModel<TPackageInfo>.Create(fCompilationData.PackageList);
      pvtList: fModel := TListViewModel<TPackageInfo>.Create(fCompilationData.PackageList);
    else
        raise Exception.Create('Invalid View');
    end;

    fModel.OnCreateLogicalNode := CreateLogicalNode;
  finally
    LeaveCriticalSection(criticalSection);
  end;
end;

procedure TShowPackageListPage.packageTreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: Integer);
var
  data: PNodeData;
begin
  if Column <> 0 then
    exit;

  data := Sender.GetNodeData(Node);
  case data.NodeType of
     ntFolder: ImageIndex := 0;
     ntPackage: ImageIndex := 1;
  end;
end;

procedure TShowPackageListPage.actChangeViewToListExecute(Sender: TObject);
begin
  inherited;
  fPackageTree.BeginUpdate;
  try
    fPackageTree.Clear;
    SetView(pvtList);
    fPackageTree.RootNodeCount := fModel.GetChildCount(nil);
  finally
    fPackageTree.EndUpdate;
  end;
end;

procedure TShowPackageListPage.actChangeViewToTreeExecute(Sender: TObject);
begin
  inherited;
  fPackageTree.BeginUpdate;
  try
    fPackageTree.Clear;
    SetView(pvtTree);
    fPackageTree.RootNodeCount := fModel.GetChildCount(nil);
    fPackageTree.FullExpand;
  finally
   fPackageTree.EndUpdate;
  end;
end;

procedure TShowPackageListPage.actRemoveExecute(Sender: TObject);
begin
  inherited;
  if fPackageTree.SelectedCount > 0 then
  begin
    fPackageTree.DeleteSelectedNodes;
    VerifyDependencies;
  end;
end;

procedure TShowPackageListPage.actRemoveUpdate(Sender: TObject);
begin
  inherited;
  TAction(Sender).Enabled := fPackageTree.SelectedCount > 0;
end;

procedure TShowPackageListPage.fPackageTreeGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
  var LineBreakStyle: TVTTooltipLineBreakStyle; var HintText: string);

var
  data: PNodeData;
  _type: string;
  info: TPackageInfo;
  builder: TStringBuilder;
begin
  data := Sender.GetNodeData(Node);
  if data.NodeType <> ntPackage then
    Exit;

  info := data.Info;
  _type := _('Designtime Package');
  if (info.RunOnly) then
    _type := _('Runtime Package');

  builder := TStringBuilder.Create;
  try
    builder.Append(_('FullPath:') + info.FileName).AppendLine;
    builder.Append(_('Description:') + info.Description).AppendLine;
    builder.Append(_('Type:') + _type).AppendLine;
    builder.Append(_('Requires:')).AppendLine;
    builder.Append(info.RequiredPackageList.Text).AppendLine;
    if data.MissingPackageName <> '' then
      builder.Append(_('Missing Package:') + data.MissingPackageName);
    HintText := builder.ToString;
  finally
    builder.Free;
  end;
end;

procedure TShowPackageListPage.fPackageTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
var
  data: PNodeData;
begin
  CellText := '';
  data := Sender.GetNodeData(Node);

  case Column of
    0:CellText := data.Name;
    1:if data.NodeType = ntPackage then
        CellText := data.Info.Description;
    2:if data.NodeType = ntPackage then
      begin
        if data.Info.RunOnly then
          CellText := _('runtime')
        else
          CellText := _('design');
      end;
  end;

end;

procedure TShowPackageListPage.fPackageTreeInitChildren(
  Sender: TBaseVirtualTree; Node: PVirtualNode; var ChildCount: Cardinal);
var
  data: PNodeData;
begin
  inherited;
  data := Sender.GetNodeData(Node);
  if data.NodeType = ntFolder then
  begin
    ChildCount := fModel.GetChildCount(data.Info);
  end;
end;

procedure TShowPackageListPage.fPackageTreeInitNode(Sender: TBaseVirtualTree;
  ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
var
  data: PNodeData;
  parentData: PNodeData;
  parentPackageInfo : TPackageInfo;
begin
  inherited;
  Node.CheckType := ctCheckBox;
  Node.CheckState := csCheckedNormal;
  data := Sender.GetNodeData(Node);
  parentData := Sender.GetNodeData(ParentNode);
  parentPackageInfo := nil;
  if parentData <> nil then
    parentPackageInfo := parentData.Info;

  data.Info := fModel.GetChild(parentPackageInfo, Node.Index);
  data.Name := data.Info.PackageName;

  if ExtractFileExt(data.Info.FileName) = '' then //TODO: this is very ugly, change this asap
    data.NodeType := ntFolder
  else
    data.NodeType := ntPackage;

  if fModel.GetChildCount(data.Info) > 0 then
    InitialStates := [ivsHasChildren];
end;

procedure TShowPackageListPage.fPackageTreeKeyAction(Sender: TBaseVirtualTree; var CharCode: Word; var Shift: TShiftState; var DoDefault: Boolean);
begin
  inherited;
  if CharCode = VK_DELETE then
  begin
    actRemove.Execute;
  end;
end;

procedure TShowPackageListPage.fPackageTreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType);
var
  data: PNodeData;
begin
  inherited;

  if fPackageTree.FocusedNode = Node then
  begin
    TargetCanvas.Font.Color := clWhite;
    exit;
  end;

  data := Sender.GetNodeData(Node);
  if Column = 0 then
  begin
    if (data.Info <> nil) and (data.MissingPackageName <> '') then
      TargetCanvas.Font.Color := clRed
    else
      TargetCanvas.Font.Color := clBlack;
  end;
end;

procedure TShowPackageListPage.miCollapseAllClick(Sender: TObject);
begin
  inherited;
  fPackageTree.FullCollapse;
end;

procedure TShowPackageListPage.miCollapseChildrenClick(Sender: TObject);
begin
  inherited;
  fPackageTree.FullCollapse(fPackageTree.FocusedNode);
end;

procedure TShowPackageListPage.miExpandAllClick(Sender: TObject);
begin
  inherited;
  fPackageTree.FullExpand;
end;

procedure TShowPackageListPage.miExpandChildrenClick(Sender: TObject);
begin
  inherited;
  fPackageTree.FullExpand(fPackageTree.FocusedNode);
end;

procedure TShowPackageListPage.miSelectAllClick(Sender: TObject);
begin
  fPackageTree.BeginUpdate;
  try
    fPackageTree.Traverse( procedure(Node: PVirtualNode)
    begin
      Node.checkState := csCheckedNormal;
    end);
    VerifyDependencies;
  finally
    fPackageTree.EndUpdate;
  end;
  UpdateWizardState;
end;

procedure TShowPackageListPage.miSelectMatchingClick(Sender: TObject);
var
  value: string;
begin
  fPackageTree.BeginUpdate;
  try
    value := fCompilationData.Pattern;
    if InputQuery(_('Select Matching...'), _('File Mask'), value) then
    begin
      fSelectMask := value;
      fPackageTree.TraverseWithData( procedure(Node: PVirtualNode; data: PNodeData)
      begin
        if IsFileNameMatch(data.Info.PackageName + '.dpk', fSelectMask) then
           Node.checkState := csCheckedNormal;
      end);
      VerifyDependencies;
    end;
  finally
    fPackageTree.EndUpdate;
  end;
  UpdateWizardState;
end;

procedure TShowPackageListPage.miUnselectAllClick(Sender: TObject);
begin
  fPackageTree.BeginUpdate;
  try
    fPackageTree.Traverse( procedure(Node: PVirtualNode)
    begin
      Node.checkState := csUncheckedNormal;
    end);
    VerifyDependencies;
  finally
    fPackageTree.EndUpdate;
  end;
  UpdateWizardState;
end;

procedure TShowPackageListPage.miUnselectMatchingClick(Sender: TObject);
var
  value: string;
begin
  fPackageTree.BeginUpdate;
  try
    value := fCompilationData.Pattern;
    if InputQuery(_('UnSelect Matching...'), _('File Mask'), value) then
    begin
      fSelectMask := value;
      fPackageTree.TraverseWithData( procedure(Node: PVirtualNode; data: PNodeData)
      begin
        if IsFileNameMatch(data.Info.PackageName + '.dpk', fSelectMask) then
            Node.checkState := csUncheckedNormal;
      end);
      VerifyDependencies;
    end;
  finally
    fPackageTree.EndUpdate;
  end;
  UpdateWizardState;
end;

{ TPackageLoadThread }

constructor TPackageLoadThread.Create(data: TCompilationData);
begin
  inherited Create(true);
  fCompilationData := data;
  fPackageInfoFactory := TPackageInfoFactory.Create;
end;

destructor TPackageLoadThread.Destroy;
begin
  fPackageInfoFactory.Free;
  inherited;
end;

procedure TPackageLoadThread.Execute;
begin
  inherited;
  fActive := true;
  try
    try
      Search(fCompilationData.BaseFolder);
    except
      on e: Exception do
        ShowMessage(e.Message);
    end;
  finally
  end;
end;

procedure TPackageLoadThread.LoadPackageInformations(const directory: string);
var
  sr: TSearchRec;
begin
  if FindFirst(PathAppend(directory,fCompilationData.Pattern), faAnyFile, sr) = 0 then
  begin
    try
      repeat
        if ExtractFileExt(sr.Name) = '.dpk' then
          fCompilationData.PackageList.Add(fPackageInfoFactory.CreatePackageInfo(PathAppend(directory, sr.Name)));
      until FindNext(sr) <> 0;
    finally
      FindClose(sr);
    end;
  end;
end;

procedure TPackageLoadThread.Search(const folder: String);
var
  directoryList: TStringList;
  directory: string;
begin
  if not fActive then
    exit;

  directoryList := TStringList.Create;
  try
    BuildFileList(PathAppend(folder,'*.*'), faDirectory, directoryList);
    for directory in directoryList do
    begin
      Search(PathAppend(folder, directory));
    end;
    LoadPackageInformations(folder);
  finally
    directoryList.Free;
  end;
end;
end.
