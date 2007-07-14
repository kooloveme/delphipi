unit FormMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, JclBorlandTools, CheckLst, ComCtrls, ActnList, ImgList,
  ToolWin, PackageInfo, ExtCtrls;

type
  TfrmMain = class(TForm)
    ListView1: TListView;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ImageList: TImageList;
    ToolButton2: TToolButton;
    ActionList: TActionList;
    actSelectFolder: TAction;
    actCompile: TAction;
    actExit: TAction;
    StatusBar1: TStatusBar;
    ToolButton3: TToolButton;
    actAbout: TAction;
    ToolButton4: TToolButton;
    Memo: TMemo;
    Splitter1: TSplitter;
    ToolButton5: TToolButton;
    actInstall: TAction;
    procedure actSelectFolderExecute(Sender: TObject);
    procedure actExitExecute(Sender: TObject);
    procedure ListView1InfoTip(Sender: TObject; Item: TListItem;
      var InfoTip: string);
    procedure actCompileUpdate(Sender: TObject);
    procedure actCompileExecute(Sender: TObject);
    procedure actAboutExecute(Sender: TObject);
  private
    FPackageList: PackageInfo.TPackageList;
    inst : TJclBorRADToolInstallation;
    procedure DisplayPackageList(const PackageList: TPackageList);
    procedure AddSourcePaths;
  protected
    procedure handletext(const text:string);
  end;

var
  frmMain: TfrmMain;

implementation
{$R *.dfm}
uses  JclSysUtils, JclFileUtils, FileCtrl, FormAbout, FormOptions;

procedure TfrmMain.actAboutExecute(Sender: TObject);
begin
  Application.CreateForm(TfrmAbout,frmAbout);
  frmAbout.ShowModal;
  frmAbout.Free;
end;

procedure TfrmMain.actCompileExecute(Sender: TObject);
var
  i: Integer;
  info : TPackageInfo;
  includes: String;
  j: Integer;
  ExtraOptions : String;
  BPLFileName: String;
  compiled : boolean;
begin
  AddSourcePaths;

  inst.OutputCallback := self.handletext;
  for i := 0 to ListView1.Items.Count - 1 do begin
    if not ListView1.Items[i].Checked then continue;
    info := TPackageInfo(ListView1.Items[i].Data);
    ExtraOptions := '-B';
    ExtraOptions := ExtraOptions + #13#10 +'-I"'+inst.LibrarySearchPath+'"';
    ExtraOptions := ExtraOptions + #13#10+ '-U"'+inst.LibrarySearchPath+'"';
    ExtraOptions := ExtraOptions + #13#10+ '-O"'+inst.LibrarySearchPath+'"';
    ExtraOptions := ExtraOptions + #13#10+ '-R"'+inst.LibrarySearchPath+'"';
    compiled := inst.DCC32.MakePackage(info.filename, inst.BPLOutputPath,inst.DCPOutputPath,ExtraOptions);
    if (compiled) and (not info.RunOnly) then begin
      BPLFileName := PathAddSeparator(inst.BPLOutputPath) + PathExtractFileNameNoExt(info.FileName) + '.bpl';
      inst.RegisterIDEPackage(BPLFileName, info.Description);
    end;
  end;
end;

procedure TfrmMain.actCompileUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := ListView1.Items.Count > 0;
end;

procedure TfrmMain.actExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.actSelectFolderExecute(Sender: TObject);
var
  directory: string;
  mask : string;
begin
  if SelectDirectory('Select the folder where packages are','C:\',directory) then begin
    //mask := '*D11.dpk';
    Application.CreateForm(TfrmOptions, frmOptions);
    try
      if frmOptions.ShowModal = mrOk then begin
        inst := frmOptions.Installer;
        directory := directory +'\' + frmOptions.Pattern;
        directory := 'C:\Components\Src\DevExpress\ExpressSpreadSheet\*D11.dpk';
        FPackageList := TPackageList.LoadFromFolder(directory);
        FPackageList.SortList;
        DisplayPackageList(FPackageList);
      end;
    finally
      frmOptions.Free;
    end;
  end;
end;

procedure TfrmMain.DisplayPackageList(const PackageList: TPackageList);
var
  info : TPackageInfo;
  I: Integer;
begin
  ListView1.Clear;
  ListView1.Items.BeginUpdate;
  try
    for I := 0 to PackageList.Count - 1 do begin
      info := PackageList[i];
      with ListView1.Items.Add do begin
        Caption := info.Description;
        SubItems.Add(info.PackageName);
        if info.RunOnly then
          SubItems.Add('runtime')
        else
          SubItems.Add('design');
        Checked := True;
        Data := info;
      end;
    end;
  finally
    ListView1.Items.EndUpdate;
  end;
end;

procedure TfrmMain.handletext(const text: string);
begin
  memo.lines.add(text);
  Application.ProcessMessages;
end;

procedure TfrmMain.AddSourcePaths;
var
  SourcePaths: TStringList;
  i: Integer;
begin
  SourcePaths := TStringList.Create;
  try
    FPackageList.GetSourceList(SourcePaths);
    memo.Lines.Assign(SourcePaths);
    for I := 0 to SourcePaths.Count - 1 do
    begin
      inst.AddToLibrarySearchPath(SourcePaths[i]);
    end;
  finally
    SourcePaths.Free;
  end;
end;

procedure TfrmMain.ListView1InfoTip(Sender: TObject; Item: TListItem;
  var InfoTip: string);
var
  info : TPackageInfo;
begin
  info := TPackageInfo(Item.Data);
  InfoTip := 'Requires:'#13#10 + info.Requires.Text;
end;

end.
